import 'dart:io';

class PrivateModeHttpOverrides extends HttpOverrides {
  final String proxyUrl;

  PrivateModeHttpOverrides({required this.proxyUrl});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (Uri uri) => 'PROXY $proxyUrl';
    return client;
  }
}

void applyPrivateModeProxy(bool enabled, {String proxyUrl = '127.0.0.1:8118'}) {
  if (enabled) {
    HttpOverrides.global = PrivateModeHttpOverrides(proxyUrl: proxyUrl);
  } else {
    HttpOverrides.global = null;
  }
}
