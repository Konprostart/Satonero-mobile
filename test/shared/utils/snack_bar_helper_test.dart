import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/shared/utils/snack_bar_helper.dart';

const String _message = 'hello notification';
const double _safeBottom = 24.0;
const double _navBarHeight = 80.0;
const Size _screenSize = Size(400, 800);
const Key _embeddedBarKey = Key('embedded_bottom_bar');
const Key _actionButtonKey = Key('bottom_action_button');

/// Applies the phone-shaped viewport and the bottom safe-area inset used by
/// every test in this file.
void _configureView(WidgetTester tester) {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: _safeBottom);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: _safeBottom);
  addTearDown(tester.view.reset);
}

/// Mirrors the app's real bottom navigation bar pattern: a fixed 80dp bar
/// placed inside the Scaffold body and wrapped in a bottom SafeArea
/// (`lib/shared/widgets/bottom_nav_bar.dart`).
class _EmbeddedBottomBar extends StatelessWidget {
  const _EmbeddedBottomBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: _embeddedBarKey,
        width: double.infinity,
        height: _navBarHeight,
        color: Colors.black,
      ),
    );
  }
}

Widget _app({required Widget body, Widget? bottomNavigationBar}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('title')),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    ),
  );
}

/// The banner surface (the [Material] rendered by the helper).
Rect _bannerRect(WidgetTester tester) {
  return tester.getRect(
    find
        .ancestor(
          of: find.text(_message),
          matching: find.byType(Material),
        )
        .first,
  );
}

void main() {
  tearDown(SnackBarHelper.dismiss);

  testWidgets(
    'the previous full-screen margin still triggers the off-screen assertion '
    '(guards this regression test)',
    (tester) async {
      _configureView(tester);
      late BuildContext context;
      await tester.pumpWidget(
        _app(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      // Reimplements the pre-fix helper: a floating SnackBar whose bottom
      // margin makes the layout box as tall as the screen.
      final double topMargin =
          MediaQuery.of(context).padding.top + kToolbarHeight + 4;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('legacy'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: topMargin,
            left: 16,
            right: 16,
            bottom: _screenSize.height - topMargin - 60,
          ),
        ),
      );
      await tester.pump();
      // Let the entrance animation reach its final height: the Scaffold
      // asserts on the laid-out (not the collapsed) SnackBar.
      await tester.pump(const Duration(milliseconds: 300));

      final Object? error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('Floating SnackBar presented off screen'),
      );

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'the banner is rendered at the top, below the app bar, and never overlaps '
    'the embedded bottom bar',
    (tester) async {
      _configureView(tester);
      late BuildContext context;
      await tester.pumpWidget(
        _app(
          body: Stack(
            children: [
              Center(
                child: Builder(
                  builder: (ctx) {
                    context = ctx;
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: _EmbeddedBottomBar(),
              ),
            ],
          ),
        ),
      );

      SnackBarHelper.showTopSnackBar(context, _message);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(_message), findsOneWidget);
      // The notification is no longer a bottom SnackBar.
      expect(find.byType(SnackBar), findsNothing);

      final Rect banner = _bannerRect(tester);
      final Rect bar = tester.getRect(find.byKey(_embeddedBarKey));

      // Below the status bar / app bar area.
      expect(
        banner.top,
        greaterThanOrEqualTo(24.0 + kToolbarHeight),
      );
      // Always in the top half of the viewport.
      expect(banner.center.dy, lessThan(_screenSize.height / 2));
      // Never covers the embedded 80dp bottom bar.
      expect(
        banner.overlaps(bar),
        isFalse,
        reason: 'banner $banner overlaps bottom bar $bar',
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    },
  );

  testWidgets(
    'the banner never covers a bottom action row and the action stays tappable',
    (tester) async {
      _configureView(tester);
      var taps = 0;
      late BuildContext context;

      await tester.pumpWidget(
        _app(
          body: Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (ctx) {
                    context = ctx;
                    return const SizedBox.expand();
                  },
                ),
              ),
              // Mirrors the trade detail action row pinned to the bottom of
              // the body, above the bottom safe area.
              SafeArea(
                top: false,
                child: SizedBox(
                  height: _navBarHeight,
                  child: Center(
                    child: ElevatedButton(
                      key: _actionButtonKey,
                      onPressed: () => taps++,
                      child: const Text('fiat sent'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      SnackBarHelper.showTopSnackBar(context, _message);
      await tester.pump();
      expect(find.text(_message), findsOneWidget);

      final Rect banner = _bannerRect(tester);
      final Rect action = tester.getRect(find.byKey(_actionButtonKey));
      expect(
        banner.overlaps(action),
        isFalse,
        reason: 'banner $banner overlaps action $action',
      );

      // The transient notification must not intercept the action tap.
      await tester.tap(find.byKey(_actionButtonKey));
      await tester.pump();
      expect(taps, 1);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    },
  );

  testWidgets('the banner auto-dismisses after the requested duration',
      (tester) async {
    _configureView(tester);
    late BuildContext context;
    await tester.pumpWidget(
      _app(
        body: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.expand();
          },
        ),
      ),
    );

    SnackBarHelper.showTopSnackBar(
      context,
      _message,
      duration: const Duration(seconds: 5),
    );
    await tester.pump();
    expect(find.text(_message), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text(_message), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(_message), findsNothing);
  });

  testWidgets('a newer notification replaces the visible one', (tester) async {
    _configureView(tester);
    late BuildContext context;
    await tester.pumpWidget(
      _app(
        body: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.expand();
          },
        ),
      ),
    );

    SnackBarHelper.showTopSnackBar(context, 'first');
    await tester.pump();
    expect(find.text('first'), findsOneWidget);

    SnackBarHelper.showTopSnackBar(context, _message);
    await tester.pump();

    expect(find.text('first'), findsNothing);
    expect(find.text(_message), findsOneWidget);
    expect(find.byType(Material), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });

  testWidgets('async helper uses the supplied overlay and keeps the colour',
      (tester) async {
    _configureView(tester);
    late ScaffoldMessengerState messenger;
    late OverlayState overlay;
    await tester.pumpWidget(
      _app(
        body: Builder(
          builder: (ctx) {
            messenger = ScaffoldMessenger.of(ctx);
            overlay = Overlay.of(ctx, rootOverlay: true);
            return const SizedBox.expand();
          },
        ),
      ),
    );

    final Size size = tester.getSize(find.byType(Scaffold));
    SnackBarHelper.showTopSnackBarAsync(
      messenger: messenger,
      screenHeight: size.height,
      statusBarHeight: 24,
      message: _message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
      overlay: overlay,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(_message), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    final Material material = tester.widget<Material>(
      find
          .ancestor(
            of: find.text(_message),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, Colors.red);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets(
    'async helper without an overlay keeps the legacy SnackBar fallback',
    (tester) async {
      _configureView(tester);
      late ScaffoldMessengerState messenger;
      await tester.pumpWidget(
        _app(
          body: Builder(
            builder: (ctx) {
              messenger = ScaffoldMessenger.of(ctx);
              return const SizedBox.expand();
            },
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(Scaffold));
      SnackBarHelper.showTopSnackBarAsync(
        messenger: messenger,
        screenHeight: size.height,
        statusBarHeight: 24,
        message: _message,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
      final SnackBar snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);

      messenger.removeCurrentSnackBar();
      await tester.pumpAndSettle();
    },
  );
}
