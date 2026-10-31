import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:satonero_mobile/core/config/communities.dart';
import 'package:satonero_mobile/core/legacy_daemon_migration.dart';
import 'package:satonero_mobile/features/mostro/mostro_nodes_provider.dart';
import 'package:satonero_mobile/shared/providers/nostr_service_provider.dart';
import 'package:satonero_mobile/shared/providers/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../mocks.mocks.dart';

const _custom =
    '5555555555555555555555555555555555555555555555555555555555555555';

void main() {
  late MockNostrService nostr;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    nostr = MockNostrService();
    when(nostr.fetchEvents(any)).thenAnswer((_) async => <NostrEvent>[]);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(SharedPreferencesAsync()),
      nostrServiceProvider.overrideWithValue(nostr),
    ]);
    await container.read(mostroNodesProvider.notifier).init();
  });

  tearDown(() => container.dispose());

  List<String> authorsOfLastRequest() {
    final captured =
        verify(nostr.fetchEvents(captureAny)).captured.last as NostrFilter;
    return captured.authors ?? const [];
  }

  test('cold start (includeTrusted: false) with no custom node sends no kind 0 request',
      () async {
    await container
        .read(mostroNodesProvider.notifier)
        .fetchAllNodeMetadata(includeTrusted: false);

    verifyNever(nostr.fetchEvents(any));
  });

  test('cold start requests only custom nodes, never the upstream entry',
      () async {
    final notifier = container.read(mostroNodesProvider.notifier);
    expect(await notifier.addCustomNode(_custom), isTrue);

    await notifier.fetchAllNodeMetadata(includeTrusted: false);

    // Read the captured call once: a mock verifies each call only once.
    final authors = authorsOfLastRequest();
    expect(authors, [_custom]);
    expect(authors, isNot(contains(legacyUpstreamDaemonPubkey)));
    expect(authors, isNot(contains(trustedCommunities.first.pubkey)));
  });

  test('the community selector flow (default) still requests trusted nodes',
      () async {
    final notifier = container.read(mostroNodesProvider.notifier);
    await notifier.addCustomNode(_custom);

    await notifier.fetchAllNodeMetadata();

    final authors = authorsOfLastRequest();
    expect(authors, contains(legacyUpstreamDaemonPubkey),
        reason: 'the upstream entry stays selectable and its metadata loads '
            'when the user opens the selector');
    expect(authors, contains(_custom));
  });
}
