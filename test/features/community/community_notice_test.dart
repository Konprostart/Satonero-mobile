import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satonero_mobile/data/models/enums/storage_keys.dart';
import 'package:satonero_mobile/features/community/community.dart';
import 'package:satonero_mobile/features/community/providers/community_selector_provider.dart';
import 'package:satonero_mobile/features/community/screens/community_selector_screen.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/providers/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// A test-only community. It is not a Mostro daemon and never appears in
/// the production community list.
const _communityPubkey =
    '4444444444444444444444444444444444444444444444444444444444444444';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<bool?> persistedNoticeAccepted(WidgetTester tester) =>
      tester.runAsync<bool?>(() => SharedPreferencesAsync().getBool(
            SharedPreferencesKeys.communityNoticeAccepted.value,
          ));

  Future<void> pumpSelector(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(SharedPreferencesAsync()),
      communityListProvider.overrideWith((ref) async => [
            Community(
              pubkey: _communityPubkey,
              region: 'Argentina',
              name: 'Test AR',
              hasTradeInfo: true,
            ),
          ]),
    ]);
    addTearDown(container.dispose);

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
  }

  testWidgets('notice is shown on first visit and Accept is persisted',
      (tester) async {
    await pumpSelector(tester);
    final ctx = tester.element(find.byType(CommunitySelectorScreen));

    expect(find.text(S.of(ctx)!.communityDisclaimerBody), findsOneWidget);

    await tester.tap(find.text(S.of(ctx)!.communityDisclaimerAccept));
    await tester.pumpAndSettle();

    expect(find.text(S.of(ctx)!.communityDisclaimerBody), findsNothing);
    expect(await persistedNoticeAccepted(tester), isTrue);
  });

  testWidgets('an accepted notice is not shown again on the next visit',
      (tester) async {
    await tester.runAsync(() => SharedPreferencesAsync().setBool(
          SharedPreferencesKeys.communityNoticeAccepted.value,
          true,
        ));

    await pumpSelector(tester);
    final ctx = tester.element(find.byType(CommunitySelectorScreen));

    expect(find.byType(CommunitySelectorScreen), findsOneWidget);
    expect(find.text(S.of(ctx)!.communityDisclaimerBody), findsNothing);
    expect(await persistedNoticeAccepted(tester), isTrue);
  });
}
