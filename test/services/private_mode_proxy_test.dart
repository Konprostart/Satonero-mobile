import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/services/private_mode_proxy.dart';

void main() {
  test('Private Mode enables HTTP proxy overrides', () {
    applyPrivateModeProxy(true);
    expect(HttpOverrides.current, isNotNull);
  });

  test('Private Mode disables HTTP proxy overrides', () {
    applyPrivateModeProxy(false);
    expect(HttpOverrides.current, isNull);
  });
}
