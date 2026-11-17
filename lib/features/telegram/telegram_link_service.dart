import 'dart:async';
import 'dart:convert';

import 'package:dart_nostr/nostr/core/key_pairs.dart';
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:dart_nostr/nostr/model/request/filter.dart';
import 'package:dart_nostr/nostr/model/request/request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satonero_mobile/data/models/enums/action.dart';
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
      );
    }
    _inProgress = true;
    try {
      final keyManager = ref.read(keyManagerProvider);
      final master = keyManager.masterKeyPair;
      if (master == null) {
        throw const TelegramLinkException('Master key not initialized');
      }
      _masterKey = master;
      _tempTradeKey = await keyManager.deriveTradeKeyFromIndex(1);

      final settings = ref.read(settingsProvider);
      if (settings.mostroPublicKey.isEmpty) {
        throw const TelegramLinkException('Mostro node not configured');
      }

      // Resolve the node's transport and PoW before sending, matching the
      // restore request path. The subscription filter depends on it.
      final mostroInstance =
          await ref.read(orderRepositoryProvider).awaitMostroInstance();
      if (mostroInstance == null) {
        logger.w('Telegram link: node info unavailable, sending with PoW 0');
      }

      _subscription = await _subscribe(
        settings.mostroPublicKey,
        mostroInstance,
      );
      _completer = Completer<NostrEvent>();

      final requestId = DateTime.now().millisecondsSinceEpoch;
      await _sendRequest(requestId, settings.mostroPublicKey, mostroInstance);

      final event = await _completer!.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Telegram code request timed out after ${timeout.inSeconds}s',
        ),
      );

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

    final event = await message.wrapForTransport(
      protocolVersion: instance?.protocolVersion,
      tradeKey: _tempTradeKey!,
      recipientPubKey: mostroPubkey,
      masterKey: settings.fullPrivacyMode ? null : _masterKey,
      difficulty: instance?.pow ?? 0,
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
      throw TelegramLinkException('Could not parse reply: $e');
    }

    if (msg.action == Action.cantDo) {
      throw const TelegramLinkException(
        'Telegram notifications are not available on this node',
      );
    }
    if (msg.action != Action.telegramCode) {
      throw TelegramLinkException('Unexpected reply action: ${msg.action}');
    }

    final code = msg.getPayload<TextMessage>()?.message;
    if (code == null || code.isEmpty) {
      throw const TelegramLinkException('Reply did not include a code');
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
      throw const TelegramLinkException('Reply content is empty');
    }

    final list = jsonDecode(content) as List<dynamic>;
    if (list.isEmpty) {
      throw const TelegramLinkException('Reply tuple is empty');
    }
    return list[0] as Map<String, dynamic>;
  }
}

/// Error surfaced to the UI when the link request cannot be completed.
class TelegramLinkException implements Exception {
  final String message;

  const TelegramLinkException(this.message);

  @override
  String toString() => 'TelegramLinkException: $message';
}
