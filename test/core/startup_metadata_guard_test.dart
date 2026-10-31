import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guard: the cold-start wiring must stay custom-only, and the
/// selector must keep loading trusted metadata. Behaviour of the method
/// itself is covered by mostro_metadata_scope_test.dart. This test only checks
/// the call sites, because app startup cannot run in a unit test.
void main() {
  test('app startup fetches custom-node metadata only', () {
    final source =
        File('lib/shared/providers/app_init_provider.dart').readAsStringSync();

    expect(source, contains('fetchAllNodeMetadata(includeTrusted: false)'));
    expect(source, isNot(contains('fetchAllNodeMetadata()')));
  });

  test('the community selector loads trusted metadata when opened', () {
    final source = File(
      'lib/features/community/screens/community_selector_screen.dart',
    ).readAsStringSync();

    expect(source, contains('fetchAllNodeMetadata()'));
  });
}
