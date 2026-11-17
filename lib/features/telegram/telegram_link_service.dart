import 'dart:async';
import 'dart:convert';

import 'package:dart_nostr/nostr/core/key_pairs.dart';
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:dart_nostr/nostr/model/request/filter.dart';
import 'package:dart_nostr/nostr/model/request/request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satonero_mobile/core/config.dart';
import 'package:satonero_mobile/data/models/cant_do.dart';
import 'package:satonero_mobile/data/models/enums/action.dart';
import 'package:satonero_mobile/data/models/enums/cant_do_reason.dart';
import 'package:satonero_mobile/data/models/mostro_message.dart';
import 'package:satonero_mobile/data/models/nostr_event.dart';
import 'package:satonero_mobile/data/models/payload.dart';
import 'package:satonero_mobile/data/models/text_message.dart';
import 'package:satonero_mobile/features/key_manager/key_manager_provider.dart';
import 'package:satonero_mobile/features/mostro/mostro_instance.dart';
import 'package:satonero_mobile/features/mostro/transport.dart';
import 'package:satonero_mobile/features/settings/settings_provider.dart';
import 'package:satonero_mobile/services/logger_service.dart';
import 'package:satonero_mobile/shared/providers/nostr_service_provider.dart';
import 'package:satonero_mobile/shared/providers/order_repository_provider.dart';
import 'package:satonero_mobile/shared/utils/nostr_utils.dart';

/// Why a Telegram linking request failed. The settings screen maps each kind
/// to a distinct, actionable message instead of one generic error.
enum TelegramLinkFailure {
  /// The request was sent but the node did not reply in time.
  timeout,

  /// The node rate-limited the request (a code is already outstanding).
  rateLimited,

  /// The node refused the request (e.g. Telegram is disabled on it).
  unavailable,

  /// The node could not be reached at all (no live relay connection).
  serverUnreachable,

  /// A local prerequisite is missing (master key / node not configured).
  notConfigured,

  /// The reply could not be decoded, or did not carry a code.
  badReply,

  /// Opening the Telegram app / web fallback failed.
  openFailed,

  /// Another linking request is already in flight.
  inProgress,

  /// Any other unexpected failure.
  unexpected,
}

/// Error surfaced to the UI when the link request cannot be completed.
///
/// [kind] carries the machine-readable reason so the settings screen can pick
/// the right localized message; [message] is a developer-facing description.
class TelegramLinkException implements Exception {
  final String message;
  final TelegramLinkFailure kind;

  const TelegramLinkException(
    this.message, {
    this.kind = TelegramLinkFailure.unexpected,
  });

  @override
  String toString() => 'TelegramLinkException(${kind.name}): $message';
}

/// Requests a one-time Telegram linking code from the connected Mostro node.
///
/// This mirrors the identity-bound request pattern used by the restore flow: a
/// temporary trade key at index 1 plus the master identity proof. The node
/// mints a single-use code bound to that identity and replies with
/// `Action.telegramCode` carrying the code in a `text_message` payload.
///
/// The returned code is a plain string — the caller owns opening the
/// `https://t.me/<bot>?start=<code>` deep link, so the deep-link construction
/// stays a pure, testable concern.
class TelegramLinkService {
  final Ref ref;

  NostrKeyPairs? _masterKey;
  NostrKeyPairs? _tempTradeKey;
  StreamSubscription<NostrEvent>? _subscription;
  Completer<NostrEvent>? _completer;
  bool _inProgress = false;

  TelegramLinkService(this.ref);

  /// Requests the code and returns it. Throws [TelegramLinkException] on any
  /// failure so the UI can surface a message and revert the toggle.
  Future<String> requestCode({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_inProgress) {
      throw const TelegramLinkException(
        'Telegram link request already in progress',
        kind: TelegramLinkFailure.inProgress,
      );
    }
    _inProgress = true;
    try {
      final keyManager = ref.read(keyManagerProvider);
      final master = keyManager.masterKeyPair;
      if (master == null) {
        throw const TelegramLinkException(
          'Master key not initialized',
          kind: TelegramLinkFailure.notConfigured,
        );
      }
      _masterKey = master;
      _tempTradeKey = await keyManager.deriveTradeKeyFromIndex(1);

      final settings = ref.read(settingsProvider);
      if (settings.mostroPublicKey.isEmpty) {
        throw const TelegramLinkException(
          'Mostro node not configured',
          kind: TelegramLinkFailure.notConfigured,
        );
      }

      // Wait for a live connection to the node before firing the request. A
      // freshly selected node resets the relay list and rediscovers it
      // asynchronously (kind 10002); sending immediately races connectivity
      // and times out. This mirrors the restore flow's connectivity gate.
      final mostroInstance = await _resolveNodeInfo(settings.mostroPublicKey);

      _subscription = await _subscribe(
        settings.mostroPublicKey,
        mostroInstance,
      );
      _completer = Completer<NostrEvent>();

      final requestId = DateTime.now().millisecondsSinceEpoch;
      await _sendRequest(requestId, settings.mostroPublicKey, mostroInstance);

      final NostrEvent event;
      try {
        event = await _completer!.future.timeout(timeout);
      } on TimeoutException {
        throw const TelegramLinkException(
          'Telegram code request timed out',
          kind: TelegramLinkFailure.timeout,
        );
      }

      final code = await _extractCode(event, settings.mostroPublicKey);
      logger.i('Telegram link: received code');
      return code;
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      _completer = null;
      _tempTradeKey = null;
      _masterKey = null;
      _inProgress = false;
    }
  }

  /// Ensures the app is actually connected to the node before the request.
  ///
  /// Engages the defensive bootstrap relays (same as the restore flow), then
  /// waits for the node's kind-38385 info event — which proves we are on a
  /// relay the node publishes on, and carries the PoW and `protocol_version`
  /// the send needs. Returns the info event, or `null` when it never arrived
  /// but we still have live relays (best-effort send with defaults).
  Future<NostrEvent?> _resolveNodeInfo(String mostroPubkey) async {
    final nostrService = ref.read(nostrServiceProvider);
    final orderRepo = ref.read(orderRepositoryProvider);

    try {
      await nostrService.ensureBootstrapConnectivity();
    } catch (e, stackTrace) {
      logger.w(
        'Telegram link: failed to engage bootstrap relays',
        error: e,
        stackTrace: stackTrace,
      );
    }

    final maxWait = Config.relayDiscoveryTimeout + const Duration(seconds: 4);
    final start = DateTime.now();
    while (DateTime.now().difference(start) < maxWait) {
      final instance = orderRepo.mostroInstance;
      if (instance != null && instance.pubkey == mostroPubkey) {
        return instance;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }

    // One last await for the info event; then degrade to best-effort defaults.
    final instance = await orderRepo.awaitMostroInstance();
    if (instance != null) return instance;

    if (nostrService.liveRelayCount == 0) {
      throw const TelegramLinkException(
        'No live relay connection to the node',
        kind: TelegramLinkFailure.serverUnreachable,
      );
    }
    logger.w(
      'Telegram link: node info unavailable, sending with defaults '
      '(${nostrService.liveRelayCount} live relays)',
    );
    return null;
  }

  Future<StreamSubscription<NostrEvent>> _subscribe(
    String mostroPubkey,
    NostrEvent? instance,
  ) async {
    final v2Filter = NostrFilter(
      kinds: [14],
      authors: [mostroPubkey],
      p: [_tempTradeKey!.public],
      limit: 0,
    );
    // No `authors` pin on v1: NIP-59 signs the outer gift wrap with a
    // per-event ephemeral key, so the node's pubkey never appears there.
    final v1Filter = NostrFilter(
      kinds: [1059],
      p: [_tempTradeKey!.public],
      limit: 0,
    );

    final filters = instance?.protocolVersion == null
        ? [v1Filter, v2Filter]
        : switch (resolveTransport(instance!.protocolVersion)) {
            Transport.nip44 => [v2Filter],
            Transport.giftWrap => [v1Filter],
          };

    final stream = ref.read(nostrServiceProvider).subscribeToEvents(
          NostrRequest(filters: filters),
        );

    return stream.listen(
      (event) {
        final completer = _completer;
        if (completer != null && !completer.isCompleted) {
          completer.complete(event);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'Telegram link subscription error',
          error: error,
          stackTrace: stackTrace,
        );
      },
      cancelOnError: false,
    );
  }

  Future<void> _sendRequest(
    int requestId,
    String mostroPubkey,
    NostrEvent? instance,
  ) async {
    final settings = ref.read(settingsProvider);
    final message = MostroMessage<EmptyPayload>(
      action: Action.requestTelegramCode,
      requestId: requestId,
    );

    // A linking request is typically first-contact: the node may require the
    // stiffer `pow_first_contact` rather than the base `pow`. When the tag is
    // advertised it is always `>= pow`, so mining at it is safe for known
    // senders too (just a touch more work).
    final difficulty = instance?.powFirstContact ?? instance?.pow ?? 0;

    final event = await message.wrapForTransport(
      protocolVersion: instance?.protocolVersion,
      tradeKey: _tempTradeKey!,
      recipientPubKey: mostroPubkey,
      masterKey: settings.fullPrivacyMode ? null : _masterKey,
      difficulty: difficulty,
    );

    await ref.read(nostrServiceProvider).publishEvent(event);
    logger.i('Telegram link: request sent (id $requestId)');
  }

  Future<String> _extractCode(NostrEvent event, String mostroPubkey) async {
    final messageData = await _decode(event, mostroPubkey);

    // Reuse the shared parser so the `restore` wrapper and `text_message`
    // payload decode identically to the restore flow.
    final MostroMessage msg;
    try {
      msg = MostroMessage.fromJson(messageData);
    } catch (e) {
      throw TelegramLinkException(
        'Could not parse reply: $e',
        kind: TelegramLinkFailure.badReply,
      );
    }

    if (msg.action == Action.cantDo) {
      final reason = msg.getPayload<CantDo>()?.cantDoReason;
      if (reason == CantDoReason.tooManyRequests) {
        throw const TelegramLinkException(
          'Too many link attempts; wait a moment and try again',
          kind: TelegramLinkFailure.rateLimited,
        );
      }
      // `invalid_action` (Telegram disabled) and any other structured refusal.
      throw TelegramLinkException(
        'Telegram linking refused by the node (${reason?.value ?? 'unknown'})',
        kind: TelegramLinkFailure.unavailable,
      );
    }
    if (msg.action != Action.telegramCode) {
      throw TelegramLinkException(
        'Unexpected reply action: ${msg.action}',
        kind: TelegramLinkFailure.badReply,
      );
    }

    final code = msg.getPayload<TextMessage>()?.message;
    if (code == null || code.isEmpty) {
      throw const TelegramLinkException(
        'Reply did not include a code',
        kind: TelegramLinkFailure.badReply,
      );
    }
    return code;
  }

  /// Decodes the reply into its message map, handling both transports: v2
  /// (kind 14, NIP-44 direct) and v1 (kind 1059 gift wrap). Returns the first
  /// element of the message tuple (the wrapper map).
  Future<Map<String, dynamic>> _decode(
    NostrEvent event,
    String mostroPubkey,
  ) async {
    final String content;
    if (event.kind == 14) {
      content = await NostrUtils.decryptNIP44DirectEvent(
        event,
        _tempTradeKey!.private,
        expectedAuthor: mostroPubkey,
      );
    } else {
      final rumor = await event.mostroUnWrap(_tempTradeKey!);
      content = rumor.content ?? '';
    }

    if (content.isEmpty) {
      throw const TelegramLinkException(
        'Reply content is empty',
        kind: TelegramLinkFailure.badReply,
      );
    }

    final list = jsonDecode(content) as List<dynamic>;
    if (list.isEmpty) {
      throw const TelegramLinkException(
        'Reply tuple is empty',
        kind: TelegramLinkFailure.badReply,
      );
    }
    return list[0] as Map<String, dynamic>;
  }
}
