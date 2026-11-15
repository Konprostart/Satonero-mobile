import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/data/models/enums/order_type.dart';
import 'package:satonero_mobile/data/models/order.dart';

void main() {
  group('Order cashu_mint_url', () {
    test('toJson emits cashu_mint_url only when set (Lightning orders omit it)',
        () {
      final lightning = Order(
        kind: OrderType.sell,
        fiatCode: 'USD',
        fiatAmount: 100,
        paymentMethod: 'face to face',
      );
      expect(lightning.cashuMintUrl, isNull);
      expect(
          lightning.toJson()['order'].containsKey('cashu_mint_url'), isFalse);

      final cashu = Order(
        kind: OrderType.sell,
        fiatCode: 'USD',
        fiatAmount: 100,
        paymentMethod: 'face to face',
        cashuMintUrl: 'https://mint.example.com',
      );
      expect(
        cashu.toJson()['order']['cashu_mint_url'],
        'https://mint.example.com',
      );
    });

    test('fromJson parses cashu_mint_url and defaults to null when absent', () {
      final withMint = Order.fromJson({
        'kind': 'sell',
        'fiat_code': 'USD',
        'fiat_amount': 100,
        'payment_method': 'face to face',
        'cashu_mint_url': 'https://mint.example.com',
      });
      expect(withMint.cashuMintUrl, 'https://mint.example.com');

      final withoutMint = Order.fromJson({
        'kind': 'sell',
        'fiat_code': 'USD',
        'fiat_amount': 100,
        'payment_method': 'face to face',
      });
      expect(withoutMint.cashuMintUrl, isNull);
    });

    test('toMap/fromMap round-trips cashu_mint_url', () {
      final order = Order(
        kind: OrderType.sell,
        fiatCode: 'USD',
        fiatAmount: 100,
        paymentMethod: 'face to face',
        cashuMintUrl: 'https://mint.example.com',
      );
      final restored = Order.fromMap(order.toMap());
      expect(restored.cashuMintUrl, 'https://mint.example.com');
    });

    test('equality includes cashu_mint_url', () {
      final a = Order(
        kind: OrderType.sell,
        fiatCode: 'USD',
        fiatAmount: 100,
        paymentMethod: 'face to face',
        cashuMintUrl: 'https://mint-a.example.com',
      );
      final b = Order(
        kind: OrderType.sell,
        fiatCode: 'USD',
        fiatAmount: 100,
        paymentMethod: 'face to face',
        cashuMintUrl: 'https://mint-b.example.com',
      );
      expect(a == b, isFalse);
    });
  });
}
