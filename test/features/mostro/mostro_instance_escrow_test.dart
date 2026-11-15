import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/features/mostro/mostro_instance.dart';

void main() {
  group('MostroInstance Cashu escrow tags', () {
    NostrEvent buildEvent(List<List<String>> extraTags) {
      return NostrEvent(
        id: 'a' * 64,
        kind: 38385,
        content: '',
        sig: 'b' * 128,
        pubkey: 'c' * 64,
        createdAt: DateTime(2025),
        tags: [
          ['d', 'c' * 64],
          ['mostro_version', '0.20.2'],
          ['mostro_commit_hash', 'deadbeef'],
          ['max_order_amount', '1000000'],
          ['min_order_amount', '1'],
          ['expiration_hours', '24'],
          ['expiration_seconds', '900'],
          ['fee', '0.006'],
          ['pow', '0'],
          ['hold_invoice_expiration_window', '300'],
          ['hold_invoice_cltv_delta', '144'],
          ['invoice_expiration_window', '300'],
          ['lnd_version', '0.18.0'],
          ['lnd_node_pubkey', 'd' * 66],
          ['lnd_commit_hash', 'cafebabe'],
          ['lnd_node_alias', 'mostro-lnd'],
          ['lnd_chains', 'bitcoin'],
          ['lnd_networks', 'mainnet'],
          ['lnd_uris', 'lnd://example'],
          ['fiat_currencies_accepted', 'USD,EUR'],
          ['max_orders_per_response', '100'],
          ...extraTags,
        ],
      );
    }

    test('escrow_mode absent → lightning (legacy daemon)', () {
      final instance = MostroInstance.fromEvent(buildEvent(const []));
      expect(instance.escrowMode, EscrowMode.lightning);
      expect(instance.cashuMintUrls, isEmpty);
      expect(instance.cashuEscrowLocktimeDays, isNull);
    });

    test('escrow_mode="lightning" → lightning', () {
      final instance = MostroInstance.fromEvent(buildEvent(const [
        ['escrow_mode', 'lightning'],
      ]));
      expect(instance.escrowMode, EscrowMode.lightning);
    });

    test('escrow_mode="cashu" → cashu', () {
      final instance = MostroInstance.fromEvent(buildEvent(const [
        ['escrow_mode', 'cashu'],
      ]));
      expect(instance.escrowMode, EscrowMode.cashu);
    });

    test('escrow_mode malformed value → lightning (defensive)', () {
      for (final raw in ['cash', '1', '']) {
        final instance = MostroInstance.fromEvent(buildEvent([
          ['escrow_mode', raw],
        ]));
        expect(instance.escrowMode, EscrowMode.lightning, reason: '"$raw"');
      }
    });

    test('escrow_mode parses case-insensitively (uppercase CASHU)', () {
      final instance = MostroInstance.fromEvent(buildEvent(const [
        ['escrow_mode', 'CASHU'],
      ]));
      expect(instance.escrowMode, EscrowMode.cashu);
    });

    test('repeated cashu_mint_url tags are all collected', () {
      final instance = MostroInstance.fromEvent(buildEvent(const [
        ['escrow_mode', 'cashu'],
        ['cashu_mint_url', 'https://mint-a.example.com'],
        ['cashu_mint_url', 'https://mint-b.example.com/'],
      ]));
      expect(instance.cashuMintUrls, [
        'https://mint-a.example.com',
        'https://mint-b.example.com/',
      ]);
    });

    test('open cashu node (no mint tags) yields an empty mint list', () {
      final instance = MostroInstance.fromEvent(buildEvent(const [
        ['escrow_mode', 'cashu'],
        ['cashu_escrow_locktime_days', '21'],
      ]));
      expect(instance.cashuMintUrls, isEmpty);
      expect(instance.cashuEscrowLocktimeDays, 21);
    });

    test('cashu_escrow_locktime_days parses and guards malformed values', () {
      final valid = MostroInstance.fromEvent(buildEvent(const [
        ['escrow_mode', 'cashu'],
        ['cashu_escrow_locktime_days', '30'],
      ]));
      expect(valid.cashuEscrowLocktimeDays, 30);

      for (final raw in ['abc', '-1', '']) {
        final instance = MostroInstance.fromEvent(buildEvent([
          ['escrow_mode', 'cashu'],
          ['cashu_escrow_locktime_days', raw],
        ]));
        expect(instance.cashuEscrowLocktimeDays, isNull, reason: '"$raw"');
      }
    });

    test('blank cashu_mint_url values are dropped', () {
      final instance = MostroInstance.fromEvent(buildEvent(const [
        ['escrow_mode', 'cashu'],
        ['cashu_mint_url', ''],
        ['cashu_mint_url', '   '],
        ['cashu_mint_url', 'https://mint-a.example.com'],
      ]));
      expect(instance.cashuMintUrls, ['https://mint-a.example.com']);
    });
  });
}
