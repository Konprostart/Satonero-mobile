import 'package:url_launcher/url_launcher.dart';

/// Builds the Telegram deep link that carries a one-time linking code.
///
/// The bot username may include a leading `@` (it is stripped). The code is
/// URL-encoded by [Uri] so it survives transport intact. Produces
/// `https://t.me/<bot>?start=<code>`.
Uri buildTelegramDeepLink(String botUsername, String code) {
  final user =
      botUsername.startsWith('@') ? botUsername.substring(1) : botUsername;
  return Uri.https('t.me', '/$user', {'start': code});
}

/// Opens [uri] in Telegram, trying the external app first and falling back to
/// the in-app webview. Returns `false` when every launch mode failed.
Future<bool> openTelegramDeepLink(Uri uri) async {
  const modes = [
    LaunchMode.platformDefault,
    LaunchMode.externalApplication,
    LaunchMode.inAppWebView,
  ];
  for (final mode in modes) {
    try {
      final ok = await launchUrl(uri, mode: mode);
      if (ok) return true;
    } catch (_) {
      // Try the next mode.
    }
  }
  return false;
}
