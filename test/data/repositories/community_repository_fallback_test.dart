import 'dart:convert';
import 'dart:io';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/data/repositories/community_repository.dart';
import 'package:satonero_mobile/shared/utils/nostr_utils.dart';

/// Minimal Nostr relay used by the fallback tests.
///
/// It upgrades every request to a WebSocket, answers each REQ with the
/// prepared events matching the requested kinds (none by default) and then
/// sends EOSE for that subscription.
class _FakeRelay {
  _FakeRelay._(this._server, this.url);

  final HttpServer _server;
  final String url;

  static Future<_FakeRelay> start({
    List<Map<String, dynamic>> events = const [],
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final relay = _FakeRelay._(server, 'ws://127.0.0.1:${server.port}');

    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen(
        (data) {
          final msg = jsonDecode(data as String) as List<dynamic>;
          if (msg.isEmpty || msg[0] != 'REQ') return;

          final subId = msg[1] as String;
          final filter = msg[2] as Map<String, dynamic>;
          final kinds = (filter['kinds'] as List<dynamic>).cast<int>();

          for (final event in events) {
            if (kinds.contains(event['kind'])) {
              socket.add(jsonEncode(['EVENT', subId, event]));
            }
          }
          socket.add(jsonEncode(['EOSE', subId]));
        },
        onError: (_) {},
        cancelOnError: false,
      );
    });

    return relay;
  }

  Future<void> close() => _server.close(force: true);
}

void main() {
  group('CommunityRepository relay fallback', () {
    late NostrKeyPairs keyPair;

    setUp(() {
      keyPair = NostrUtils.generateKeyPair();
    });

    Map<String, dynamic> kind0Event() => NostrEvent.fromPartialData(
          kind: 0,
          content: jsonEncode({'name': 'Test Community', 'about': 'Testing'}),
          keyPairs: keyPair,
        ).toMap();

    Map<String, dynamic> kind38385Event() => NostrEvent.fromPartialData(
          kind: 38385,
          content: '',
          keyPairs: keyPair,
          tags: [
            ['y', 'mostro'],
            ['fee', '0.01'],
            ['fiat_currencies_accepted', 'USD,EUR'],
          ],
        ).toMap();

    test('falls back to the next relay when one returns no events', () async {
      final emptyRelay = await _FakeRelay.start();
      final populatedRelay = await _FakeRelay.start(
        events: [kind0Event(), kind38385Event()],
      );
      addTearDown(emptyRelay.close);
      addTearDown(populatedRelay.close);

      final repository = CommunityRepository(
        relays: [emptyRelay.url, populatedRelay.url],
      );

      final metadata =
          await repository.fetchCommunityMetadata([keyPair.public]);

      final meta = metadata[keyPair.public]!;
      expect(meta.hasTradeInfo, isTrue);
      expect(meta.name, 'Test Community');
      expect(meta.fee, 0.01);
      expect(meta.currencies, ['USD', 'EUR']);
    });

    test('throws when every relay connects but returns no events', () async {
      final firstRelay = await _FakeRelay.start();
      final secondRelay = await _FakeRelay.start();
      addTearDown(firstRelay.close);
      addTearDown(secondRelay.close);

      final repository = CommunityRepository(
        relays: [firstRelay.url, secondRelay.url],
      );

      await expectLater(
        repository.fetchCommunityMetadata([keyPair.public]),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains('No community events'),
          ),
        ),
      );
    });

    test('ignores events for another pubkey and still falls back', () async {
      final otherKeyPair = NostrUtils.generateKeyPair();
      final unverifiedRelay = await _FakeRelay.start(
        events: [
          NostrEvent.fromPartialData(
            kind: 38385,
            content: '',
            keyPairs: otherKeyPair,
            tags: [
              ['y', 'mostro'],
            ],
          ).toMap(),
        ],
      );
      final populatedRelay = await _FakeRelay.start(
        events: [kind0Event(), kind38385Event()],
      );
      addTearDown(unverifiedRelay.close);
      addTearDown(populatedRelay.close);

      final repository = CommunityRepository(
        relays: [unverifiedRelay.url, populatedRelay.url],
      );

      final metadata =
          await repository.fetchCommunityMetadata([keyPair.public]);

      expect(metadata.containsKey(otherKeyPair.public), isFalse);
      expect(metadata[keyPair.public]!.hasTradeInfo, isTrue);
    });
  });
}
