import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:satonero_mobile/core/config.dart';
import 'package:satonero_mobile/data/models/enums/storage_keys.dart';
import 'package:satonero_mobile/data/repositories/open_orders_repository.dart';
import 'package:satonero_mobile/features/community/community.dart';
import 'package:satonero_mobile/features/community/screens/community_selector_screen.dart';
import 'package:satonero_mobile/features/mostro/mostro_nodes_provider.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:satonero_mobile/features/settings/settings_notifier.dart';
import 'package:satonero_mobile/features/settings/settings_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/providers/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../mocks.mocks.dart';

/// A test-only community. It is not a Mostro daemon and never appears in
/// the production community list.
const _communityPubkey =
    '4444444444444444444444444444444444444444444444444444444444444444';

/// The upstream Mostro daemon that Skip used to select implicitly.
const _upstreamPubkey =
    '82fa8cb978b43c79b2156585bac2c011176a21d2aead6d9f7c575c005be88390';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('fresh install defaults', () {
    test('no Mostro daemon is selected unless a build pins one', () async {
      expect(Config.mostroPubKey, isEmpty);

      final notifier = SettingsNotifier(SharedPreferencesAsync());
      await notifier.init();

      expect(notifier.state.mostroPublicKey, isEmpty);
      expect(notifier.state.mostroPublicKey, isNot(_upstreamPubkey));
    });
  });

  group('order subscription', () {
    late MockNostrService nostr;

    setUp(() {
      nostr = MockNostrService();
      when(nostr.isInitialized).thenReturn(true);
      when(nostr.relayGenerationStream)
          .thenAnswer((_) => const Stream<int>.empty());
      when(nostr.subscribeToEvents(any, onEose: anyNamed('onEose')))
          .thenAnswer((_) => const Stream<NostrEvent>.empty());
    });

    test('issues no REQ while no daemon is selected', () {
      OpenOrdersRepository(
        nostr,
        Settings(relays: const [], fullPrivacyMode: false, mostroPublicKey: ''),
      );

      verifyNever(nostr.subscribeToEvents(any, onEose: anyNamed('onEose')));
    });

    test('issues a REQ once an explicit daemon is configured', () {
      // Positive control: proves the verifyNever above can actually fail.
      OpenOrdersRepository(
        nostr,
        Settings(
          relays: const [],
          fullPrivacyMode: false,
          mostroPublicKey: _communityPubkey,
        ),
      );

      verify(nostr.subscribeToEvents(any, onEose: anyNamed('onEose')))
          .called(1);
    });
  });

  group('community selector', () {
    late ProviderContainer container;

    /// Reads the persisted "community selected" flag through real async I/O,
    /// so the assertion does not depend on the provider's init timing.
    Future<bool?> persistedCommunitySelected(WidgetTester tester) =>
        tester.runAsync(() => SharedPreferencesAsync()
            .getBool(SharedPreferencesKeys.communitySelected.value));

    Future<void> pumpSelector(WidgetTester tester) async {
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider
            .overrideWithValue(SharedPreferencesAsync()),
        communityListProvider.overrideWith((ref) async => [
              Community(
                pubkey: _communityPubkey,
                region: 'Argentina',
                name: 'Test AR',
                hasTradeInfo: true,
              ),
            ]),
      ]);
      final router = GoRouter(
        initialLocation: '/community_selector',
        routes: [
          GoRoute(
            path: '/community_selector',
            builder: (_, __) => const CommunitySelectorScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('HOME')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Accept the disclaimer shown on the first frame.
      final ctx = tester.element(find.byType(CommunitySelectorScreen));
      await tester.tap(find.text(S.of(ctx)!.communityDisclaimerAccept));
      await tester.pumpAndSettle();
    }

    testWidgets('Skip explains the situation and connects to nothing',
        (tester) async {
      await pumpSelector(tester);
      final ctx = tester.element(find.byType(CommunitySelectorScreen));

      await tester.tap(find.text(S.of(ctx)!.skipForNow));
      await tester.pumpAndSettle();

      expect(find.text(S.of(ctx)!.skipNoDaemonTitle), findsOneWidget);
      expect(find.text(S.of(ctx)!.skipNoDaemonBody), findsOneWidget);

      expect(container.read(settingsProvider).mostroPublicKey, isEmpty);
      expect(container.read(mostroNodesProvider), isEmpty);
      expect(await persistedCommunitySelected(tester), isNot(true));
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets('dismissing the Skip explanation keeps the user on selector',
        (tester) async {
      await pumpSelector(tester);
      final ctx = tester.element(find.byType(CommunitySelectorScreen));

      await tester.tap(find.text(S.of(ctx)!.skipForNow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.of(ctx)!.skipNoDaemonDismiss));
      await tester.pumpAndSettle();

      expect(find.byType(CommunitySelectorScreen), findsOneWidget);
      expect(container.read(settingsProvider).mostroPublicKey, isEmpty);
      expect(await persistedCommunitySelected(tester), isNot(true));
    });

    testWidgets('explicit community selection still connects to that daemon',
        (tester) async {
      await pumpSelector(tester);
      final ctx = tester.element(find.byType(CommunitySelectorScreen));

      await tester.tap(find.text('Test AR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.of(ctx)!.done));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).mostroPublicKey,
          _communityPubkey);
      expect(await persistedCommunitySelected(tester), isTrue);
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
