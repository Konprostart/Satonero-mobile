import 'dart:io';

import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

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

/// Returns an [HttpClient] that respects the active Private Mode proxy.
HttpClient createPrivateModeHttpClient() {
  return HttpOverrides.current?.createHttpClient(null) ?? HttpClient();
}

/// Returns an [http.Client] that respects the active Private Mode proxy.
http.Client createPrivateModeHttp() {
  return IOClient(createPrivateModeHttpClient());
}
