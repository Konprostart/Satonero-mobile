// Phase 6A-0 / 6A / 6B — real Satonero mobile app against a Satonero daemon.
//
// This is the end-to-end test in which the Android application itself talks to
// a running `mostrod` on a disposable regtest stack. It replaces the CLI-only
// evidence of Phase 4G/4H/5A for the app-to-daemon leg.
//
// The test is driven entirely through the production entry point
// (`bootstrapAndRun`) and the production UI. No production code is changed and
// no service is faked: the app connects to the harness relay over a real
// WebSocket, receives the maker's kind-38383 order, takes it with a real
// `take-sell` DM, submits the buyer payout invoice from the harness, and then
// observes the daemon move the trade to `active`.
//
// Phase 6B adds one more user action: the buyer marks the fiat as sent, the
// harness maker (seller) releases, and the daemon settles the seller hold
// invoice, pays this buyer payout invoice and finalises the order as `success`.
// The test only taps the production `fiat-sent` control; it never releases,
// settles or pays anything itself.
//
// Phase 6C adds the post-settlement reputation leg: the buyer rates the seller
// through the production rating screen, observes the daemon's `rate-received`
// acknowledgement, and then reads back the seller's updated reputation on a
// fresh pending order the harness maker publishes after the rating.
//
// Everything is seeded before bootstrap so the app never shows onboarding and
// never touches a public bootstrap relay or a third-party Mostro node:
//
//   --dart-define=REGTEST_DAEMON_PUBKEY=<64-hex daemon Nostr pubkey>
//   --dart-define=REGTEST_ORDER_ID=<uuid of the CLI maker's sell order>
//   --dart-define=REGTEST_BUYER_INVOICE=<lnbcrt1... payout invoice for bob_lnd>
//   --dart-define=REGTEST_RELAY_URL=ws://10.0.2.2:8080   (optional, this default)
//   --dart-define=REGTEST_REPUTATION_ORDER_AMOUNT=1234   (optional, this default)
//
// Run with:
//   flutter test integration_test/regtest_mobile_daemon_test.dart \
//     -d <android device> --dart-define=REGTEST_DAEMON_PUBKEY=... ...
//
// Must never be run against mainnet: the invoice is asserted to be a regtest
// bolt11 before anything is submitted, and the harness is regtest-only.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satonero_mobile/core/app.dart';
import 'package:satonero_mobile/core/app_bootstrap.dart';
import 'package:satonero_mobile/data/models/enums/action.dart' as mostro;
import 'package:satonero_mobile/data/models/enums/role.dart';
import 'package:satonero_mobile/data/models/enums/status.dart';
import 'package:satonero_mobile/data/models/enums/storage_keys.dart';
import 'package:satonero_mobile/data/models/nostr_event.dart';
import 'package:satonero_mobile/features/home/providers/home_order_providers.dart';
import 'package:satonero_mobile/features/home/widgets/order_list_item.dart';
import 'package:satonero_mobile/features/order/models/order_state.dart';
import 'package:satonero_mobile/features/order/providers/order_notifier_provider.dart';
import 'package:satonero_mobile/features/rate/rate_counterpart_screen.dart';
import 'package:satonero_mobile/features/rate/star_rating.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:satonero_mobile/shared/providers/navigation_notifier_provider.dart';
import 'package:satonero_mobile/shared/providers/session_notifier_provider.dart';

// --- Harness inputs (non-secret, so they travel as Dart defines) -----------

/// Nostr pubkey the daemon signs its kind-0/38385/10002/14 events with.
const String _daemonPubkey = String.fromEnvironment('REGTEST_DAEMON_PUBKEY');

/// Id of the pending sell order the CLI maker published before the app starts.
const String _makerOrderId = String.fromEnvironment('REGTEST_ORDER_ID');

/// Regtest payout invoice for `bob_lnd`, minted by the harness.
const String _buyerInvoice = String.fromEnvironment('REGTEST_BUYER_INVOICE');

/// Relay the emulator can reach: the harness publishes the relay on :8080.
const String _relayUrl = String.fromEnvironment(
  'REGTEST_RELAY_URL',
  defaultValue: 'ws://10.0.2.2:8080',
);

/// Sats amount of the fresh pending sell order the harness maker publishes
/// after the buyer's rating, so the app can render the seller's updated
/// reputation. Distinct from the traded order's amount on purpose.
const String _reputationOrderAmount = String.fromEnvironment(
  'REGTEST_REPUTATION_ORDER_AMOUNT',
  defaultValue: '1234',
);

/// The daemon advertises its container-internal relay URL in its kind-10002
/// list. The emulator cannot resolve that host, so it is blacklisted up front
/// instead of being appended to the live relay set.
const String _daemonInternalRelayUrl = 'ws://nostr_relay:8080';

const Duration _uiTimeout = Duration(seconds: 120);
const Duration _activeTimeout = Duration(seconds: 240);

/// The daemon acks `fiat-sent` with `fiat-sent-ok` almost immediately; the
/// allowance is for the round trip through the relay, not for the release.
const Duration _fiatSentTimeout = Duration(seconds: 180);

/// Settlement is driven by the harness maker (release) and then by the
/// daemon's payout retry loop, so it gets a wider allowance than the DM hops.
const Duration _settlementTimeout = Duration(seconds: 420);

/// The rating round trip is a DM hop plus the daemon's rating-event tick, so
/// it is generous but bounded.
const Duration _ratingTimeout = Duration(seconds: 240);

/// The harness maker publishes the reputation order only after the daemon has
/// published the rating event, so this covers the whole rater sequence.
const Duration _reputationTimeout = Duration(seconds: 360);
const Duration _pollInterval = Duration(milliseconds: 250);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The automation identifiers live on Semantics nodes (`Semantics.identifier`),
  // which only exist when the semantics tree is enabled. Mortsom's entry point
  // does the same; here the test arms it because it starts the production
  // entry point.
  final SemanticsHandle semantics = SemanticsBinding.instance.ensureSemantics();

  tearDownAll(() {
    semantics.dispose();
  });

  testWidgets(
    'app takes a sell order and reaches active against a Satonero daemon',
    (tester) async {
      _expectHarnessInputs();

      // Fresh install state: wipe whatever a previous run left behind so the
      // assertions below always describe this run.
      await _seedSettings();

      await bootstrapAndRun();
      await tester.pump();

      final container = _containerOf(tester);

      // ---- Gate 1: the maker's order is visible in the real order book ----
      await _waitFor(
        tester,
        () => container.read(filteredOrdersProvider).isNotEmpty,
        label: 'order book to receive the maker order',
      );

      final book = container.read(filteredOrdersProvider);
      final visibleIds = book.map((order) => order.orderId).toList();
      expect(
        visibleIds,
        contains(_makerOrderId),
        reason: 'the CLI maker order must reach the app through the relay, '
            'got $visibleIds',
      );
      // The provider can hold the order one frame before the list renders.
      await _waitFor(
        tester,
        () => find.byType(OrderListItem).evaluate().isNotEmpty,
        label: 'order book list item',
      );
      expect(
        find.byType(OrderListItem),
        findsOneWidget,
        reason: 'exactly the maker order is pending on this fresh regtest',
      );
      debugPrint('REGTEST_GATE1_ORDER_VISIBLE order=$_makerOrderId '
          'items=${book.length}');

      // ---- Gate 2: take-sell, then submit the buyer payout invoice --------
      await tester.tap(find.byType(OrderListItem).first);
      await _waitFor(
        tester,
        () => find
            .bySemanticsIdentifier('order.take.confirm')
            .evaluate()
            .isNotEmpty,
        label: 'take-order screen',
      );

      await tester.tap(find.bySemanticsIdentifier('order.take.confirm').first);
      await tester.pump(const Duration(milliseconds: 500));

      // The fixture is a fixed-price order, so taking it needs no amount
      // dialog. A range order would open one first; handle it defensively so
      // a fixture change fails on an assertion, not on a missing tap.
      if (find
          .bySemanticsIdentifier('order.take.amount')
          .evaluate()
          .isNotEmpty) {
        await tester.enterText(find.byType(TextField).last, '10');
        await tester.pump();
        await tester
            .tap(find.bySemanticsIdentifier('order.take.amount.confirm'));
        await tester.pump(const Duration(milliseconds: 500));
      }

      // The daemon answers the take-sell with `add-invoice`, which makes the
      // app open the buyer invoice screen on its own.
      await _waitFor(
        tester,
        () => find.bySemanticsIdentifier('invoice.text').evaluate().isNotEmpty,
        label: 'buyer invoice screen (daemon add-invoice)',
      );
      debugPrint('REGTEST_GATE2_TAKE_ACCEPTED order=$_makerOrderId');

      await tester.enterText(
        find.byKey(const Key('invoiceTextField')),
        _buyerInvoice,
      );
      await tester.pump();

      expect(
        find.bySemanticsIdentifier('invoice.submit'),
        findsOneWidget,
        reason: 'the invoice submit control carries its automation id',
      );
      await tester.tap(find.byKey(const Key('submitInvoiceButton')));
      await tester.pump();

      // ---- Gate 2: follow the daemon-driven status transitions ------------
      // Subscribe before waiting: a status that the app passes through for a
      // few hundred milliseconds (the seller hold invoice is paid by the
      // harness seconds after it appears) must not be missed by polling.
      // `add-invoice` maps to `waiting-buyer-invoice`, `waiting-seller-to-pay`
      // maps to `waiting-payment`, and `hold-invoice-payment-accepted` maps to
      // `active` once the seller has paid the hold invoice.
      final observed = <Status>[];
      final subscription = container.listen<OrderState>(
        orderNotifierProvider(_makerOrderId),
        (previous, next) {
          if (observed.isEmpty || observed.last != next.status) {
            observed.add(next.status);
          }
        },
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await _waitFor(
        tester,
        () =>
            container.read(orderNotifierProvider(_makerOrderId)).status ==
            Status.active,
        timeout: _activeTimeout,
        label: 'trade to reach active',
      );

      final finalState = container.read(orderNotifierProvider(_makerOrderId));
      final sequence = observed.map((status) => status.value).toList();
      debugPrint('REGTEST_GATE2_STATUS_SEQUENCE=${sequence.join(',')}');
      debugPrint('REGTEST_GATE2_FINAL_STATUS=${finalState.status.value}');
      debugPrint('REGTEST_GATE2_SAW_WAITING_PAYMENT='
          '${sequence.contains(Status.waitingPayment.value)}');

      // The daemon processed the take-sell: it answered with the add-invoice
      // request that the app rendered, and the trade later reached active.
      expect(
        sequence,
        contains(Status.waitingBuyerInvoice.value),
        reason: 'the daemon must answer the take-sell with add-invoice, saw '
            '$sequence',
      );
      expect(finalState.status, Status.active);

      final sessions = container.read(sessionNotifierProvider);
      final session =
          sessions.where((s) => s.orderId == _makerOrderId).toList();
      expect(session, hasLength(1), reason: 'exactly one trade session');
      expect(session.single.role, Role.buyer);

      debugPrint('REGTEST_GATE2_ACTIVE order=$_makerOrderId '
          'role=buyer status=${finalState.status.value}');

      // ---- Gate 3 (Phase 6B): fiat-sent, then settlement and success -------
      // Submitting the buyer invoice sends the app back to the home screen, so
      // bring the active trade back up through the production navigation state
      // before looking for the action control.
      container
          .read(navigationProvider.notifier)
          .go('/trade_detail/$_makerOrderId');
      await tester.pump(const Duration(milliseconds: 500));

      // The only settlement-side input the app contributes: the buyer marks
      // the fiat as sent. The harness maker (seller) answers with `release`;
      // the daemon settles the hold invoice, pays the buyer payout invoice and
      // finalises the order. Nothing here releases or settles.
      await _waitFor(
        tester,
        () =>
            find.bySemanticsIdentifier('trade.fiatSent').evaluate().isNotEmpty,
        label: 'buyer fiat-sent control on the active trade',
      );

      // The daemon's `active` notification is delivered through the app's top
      // snackbar, which floats just above the embedded bottom navigation bar
      // and therefore covers the action row at the bottom of this screen for
      // about two seconds. A tap issued while it is visible lands on the
      // snackbar instead of the control (observed in run 43244609877), so wait
      // for it to clear and re-tap only when the round trip clearly did not
      // happen — never spamming a second action speculatively.
      var fiatSentSent = false;
      for (var attempt = 0; attempt < 3 && !fiatSentSent; attempt++) {
        await _waitFor(
          tester,
          () => find.byType(SnackBar).evaluate().isEmpty,
          timeout: const Duration(seconds: 15),
          label: 'the trade-status snackbar to clear before tapping fiat-sent',
        );
        await tester.pump(const Duration(milliseconds: 300));
        final control = find.bySemanticsIdentifier('trade.fiatSent');
        if (control.evaluate().isEmpty) {
          // The control already left the tree: the action was accepted.
          fiatSentSent = true;
          break;
        }
        await tester.ensureVisible(control.first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(control.first);
        await tester.pump(const Duration(milliseconds: 500));
        // Allow the relay round trip before deciding the tap missed.
        for (var i = 0; i < 16 && !fiatSentSent; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          fiatSentSent =
              container.read(orderNotifierProvider(_makerOrderId)).status !=
                  Status.active;
        }
      }
      debugPrint('REGTEST_GATE3_FIAT_SENT_TAPPED order=$_makerOrderId');

      // `fiat-sent-ok` moves the buyer to `fiat-sent`.
      await _waitFor(
        tester,
        () =>
            container.read(orderNotifierProvider(_makerOrderId)).status ==
            Status.fiatSent,
        timeout: _fiatSentTimeout,
        label: 'trade to reach fiat-sent after the buyer marks the fiat sent',
      );
      debugPrint('REGTEST_GATE3_STATUS_FIAT_SENT=true');

      // The seller release produces `released`/`settled-hold-invoice` and then,
      // once the payout settles, `purchase-completed` plus `rate`, both of
      // which the app maps to `success`.
      await _waitFor(
        tester,
        () =>
            container.read(orderNotifierProvider(_makerOrderId)).status ==
            Status.success,
        timeout: _settlementTimeout,
        label: 'trade to settle and reach success',
      );

      final settledState = container.read(orderNotifierProvider(_makerOrderId));
      final settledSequence = observed.map((status) => status.value).toList();
      debugPrint('REGTEST_GATE3_STATUS_SEQUENCE=${settledSequence.join(',')}');
      expect(
        settledSequence,
        contains(Status.fiatSent.value),
        reason: 'the daemon must ack the fiat-sent action, saw '
            '$settledSequence',
      );
      expect(settledState.status, Status.success);
      debugPrint('REGTEST_GATE3_SUCCESS order=$_makerOrderId '
          'role=buyer status=${settledState.status.value}');

      // ---- Gate 4 (Phase 6C): rate the seller, then read the reputation ----
      // `rate` is the buyer's only remaining action at `success`. The daemon
      // accepts the rating because the harness maker created the order with a
      // proven identity key distinct from its trade key: mostro-core silently
      // drops a rating aimed at a full-privacy counterpart. The accepted rating
      // makes the daemon publish the seller's aggregate as a signed kind-38384
      // event and answer this app with `rate-received`, which maps to
      // `success` with the `rateReceived` action (and no follow-up button).
      container
          .read(navigationProvider.notifier)
          .go('/trade_detail/$_makerOrderId');
      await tester.pump(const Duration(milliseconds: 500));

      await _waitFor(
        tester,
        () => find.bySemanticsIdentifier('trade.rate').evaluate().isNotEmpty,
        timeout: _ratingTimeout,
        label: 'the RATE control on the successful trade',
      );

      // As with fiat-sent: the status snackbar floats over the action row for
      // about two seconds and would absorb the tap. Re-tap only if the route
      // clearly did not open.
      var rateOpened = false;
      for (var attempt = 0; attempt < 3 && !rateOpened; attempt++) {
        await _waitFor(
          tester,
          () => find.byType(SnackBar).evaluate().isEmpty,
          timeout: const Duration(seconds: 15),
          label: 'the trade-status snackbar to clear before tapping RATE',
        );
        await tester.pump(const Duration(milliseconds: 300));
        final control = find.bySemanticsIdentifier('trade.rate');
        if (control.evaluate().isEmpty) {
          // Already past the rate screen (route opened and the control left).
          rateOpened = find.byType(StarRating).evaluate().isNotEmpty;
          break;
        }
        await tester.ensureVisible(control.first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(control.first);
        await tester.pump(const Duration(milliseconds: 800));
        rateOpened = find.byType(StarRating).evaluate().isNotEmpty;
      }
      expect(rateOpened, isTrue,
          reason: 'the RATE control must open the counterpart rating screen');
      debugPrint('REGTEST_GATE4_RATE_OPENED order=$_makerOrderId');

      // The rating screen is the production star row; the fifth outlined star
      // sets a 5/5 rating and fills all five.
      final stars = find.descendant(
        of: find.byType(StarRating),
        matching: find.byIcon(Icons.star_border),
      );
      await _waitFor(
        tester,
        () => stars.evaluate().length == 5,
        label: 'the five rating stars',
      );
      await tester.tap(stars.at(4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.star).evaluate().length, 5,
          reason: 'tapping the fifth star must fill all five');

      final submit = find.descendant(
        of: find.byType(RateCounterpartScreen),
        matching: find.byType(ElevatedButton),
      );
      expect(submit, findsOneWidget,
          reason: 'the rate screen has exactly one submit control');
      await tester.tap(submit);
      await tester.pump(const Duration(milliseconds: 500));
      debugPrint(
          'REGTEST_GATE4_RATING_SUBMITTED order=$_makerOrderId rating=5');

      await _waitFor(
        tester,
        () =>
            container.read(orderNotifierProvider(_makerOrderId)).action ==
            mostro.Action.rateReceived,
        timeout: _ratingTimeout,
        label: 'the daemon rate-received acknowledgement',
      );
      final ratedState = container.read(orderNotifierProvider(_makerOrderId));
      expect(ratedState.status, Status.success,
          reason: 'rate-received keeps the trade at success');
      debugPrint('REGTEST_GATE4_RATE_RECEIVED order=$_makerOrderId '
          'action=${ratedState.action.name} status=${ratedState.status.value}');

      // The daemon stored the seller's aggregate and the harness maker then
      // published one fresh pending sell order. The daemon attaches the rated
      // reputation to every pending order of that seller, so the app's own
      // order book renders it. mostro-core weights the first review by 1/2
      // (User::update_rating), so a single 5-star rating reads 2.5 / 1 review.
      const expectedTotalRating = 2.5;
      bool hasRatedOrder() => container.read(filteredOrdersProvider).any((o) =>
          o.amount == _reputationOrderAmount &&
          o.rating != null &&
          o.rating!.totalReviews == 1 &&
          o.rating!.totalRating == expectedTotalRating);

      container.read(navigationProvider.notifier).go('/');
      await tester.pump(const Duration(milliseconds: 500));
      await _waitFor(
        tester,
        hasRatedOrder,
        timeout: _reputationTimeout,
        label: 'the rated seller reputation on a fresh pending order',
      );
      final ratedOrder = container.read(filteredOrdersProvider).firstWhere(
          (o) =>
              o.amount == _reputationOrderAmount &&
              o.rating != null &&
              o.rating!.totalReviews == 1 &&
              o.rating!.totalRating == expectedTotalRating);
      await _waitFor(
        tester,
        () => tester
            .widgetList<OrderListItem>(find.byType(OrderListItem))
            .any((w) => w.order.orderId == ratedOrder.orderId),
        timeout: _uiTimeout,
        label: 'the rated order rendered in the order book',
      );
      final rendered = tester
          .widgetList<OrderListItem>(find.byType(OrderListItem))
          .firstWhere((w) => w.order.orderId == ratedOrder.orderId);
      expect(rendered.order.rating?.totalReviews, 1);
      expect(rendered.order.rating?.totalRating, expectedTotalRating);
      debugPrint('REGTEST_GATE4_REPUTATION order=${ratedOrder.orderId} '
          'amount=${ratedOrder.amount} total_reviews='
          '${rendered.order.rating?.totalReviews} total_rating='
          '${rendered.order.rating?.totalRating}');
    },
    timeout: const Timeout(Duration(minutes: 25)),
  );
}

/// Fails fast, and legibly, when a define is missing.
void _expectHarnessInputs() {
  expect(
    _daemonPubkey,
    matches(RegExp(r'^[0-9a-f]{64}$')),
    reason: '--dart-define=REGTEST_DAEMON_PUBKEY must be the daemon Nostr '
        'pubkey (64 lowercase hex)',
  );
  expect(
    _makerOrderId,
    matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
        r'[0-9a-f]{12}$')),
    reason: '--dart-define=REGTEST_ORDER_ID must be the maker order uuid',
  );
  expect(
    _buyerInvoice,
    startsWith('lnbcrt1'),
    reason: 'the buyer invoice must be a regtest invoice (lnbcrt1...), '
        'never mainnet',
  );
  expect(
    _relayUrl,
    startsWith('ws://'),
    reason: 'the regtest relay is plain ws:// on the emulator host alias',
  );
}

/// Seeds the complete settings object the app reads at startup.
///
/// `Settings.fromJson` casts `fullPrivacyMode` and `mostroPublicKey`, so a
/// partial JSON would throw and silently fall back to defaults; every field is
/// therefore written. Seeding `first_run_complete` and `community_selected`
/// skips onboarding, so the app never selects the third-party Mostro default
/// node and never asks the community selector for metadata.
Future<void> _seedSettings() async {
  final prefs = SharedPreferencesAsync();
  await prefs.clear();

  final settings = Settings(
    relays: const [_relayUrl],
    fullPrivacyMode: false,
    privateMode: false,
    mostroPublicKey: _daemonPubkey,
    defaultFiatCode: 'USD',
    selectedLanguage: 'en',
    userRelays: [
      {
        'url': _relayUrl,
        'isHealthy': true,
        'source': 'user',
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      },
    ],
    blacklistedRelays: const [_daemonInternalRelayUrl],
  );

  await prefs.setString(
    SharedPreferencesKeys.appSettings.value,
    jsonEncode(settings.toJson()),
  );
  await prefs.setBool(SharedPreferencesKeys.firstRunComplete.value, true);
  await prefs.setBool(SharedPreferencesKeys.communitySelected.value, true);
  // Our daemon is not the legacy upstream node, so the migration is a no-op;
  // writing the marker keeps it from rewriting the seeded settings.
  await prefs.setBool(SharedPreferencesKeys.legacyDaemonMigrated.value, true);
}

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(SatoneroApp)),
      listen: false,
    );

/// Pumps frames until [condition] holds, failing the test on timeout.
Future<void> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  required String label,
  Duration timeout = _uiTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await tester.pump(_pollInterval);
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for $label');
}
