import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/features/telegram/telegram_deep_link.dart';

void main() {
  group('buildTelegramDeepLink', () {
    test('builds the t.me start deep link', () {
      final uri = buildTelegramDeepLink('satonero_bot', 'abc123');

      expect(uri.scheme, 'https');
      expect(uri.host, 't.me');
      expect(uri.path, '/satonero_bot');
      expect(uri.queryParameters['start'], 'abc123');
      expect(uri.toString(), 'https://t.me/satonero_bot?start=abc123');
    });

    test('strips a leading @ from the bot username', () {
      final uri = buildTelegramDeepLink('@satonero_bot', 'abc123');

      expect(uri.path, '/satonero_bot');
      expect(uri.toString(), 'https://t.me/satonero_bot?start=abc123');
    });

    test('URL-encodes special characters in the code', () {
      final uri = buildTelegramDeepLink('bot', 'a b&c=d');

      expect(uri.queryParameters['start'], 'a b&c=d');
      expect(uri.toString(), 'https://t.me/bot?start=a+b%26c%3Dd');
    });

    test('builds the production Satonero bot deep link', () {
      final uri = buildTelegramDeepLink('Satonerobot', 'A1B2C3');

      expect(uri.scheme, 'https');
      expect(uri.host, 't.me');
      expect(uri.path, '/Satonerobot');
      expect(uri.queryParameters['start'], 'A1B2C3');
      expect(
        uri.toString(),
        'https://t.me/Satonerobot?start=A1B2C3',
      );
    });
  });
}
