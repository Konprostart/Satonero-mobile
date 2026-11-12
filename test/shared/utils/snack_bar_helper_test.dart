import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/shared/utils/snack_bar_helper.dart';

const String _message = 'hello snackbar';
const double _safeBottom = 24.0;
const double _navBarHeight = 80.0;
const Size _screenSize = Size(400, 800);
const Key _embeddedBarKey = Key('embedded_bottom_bar');
const Key _scaffoldBarKey = Key('scaffold_bottom_bar');

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

Widget _app({
  required Widget body,
  Widget? bottomNavigationBar,
}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('title')),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    ),
  );
}

/// The visible SnackBar surface. The [SnackBar] widget's own box includes the
/// (transparent) margins, so geometry that must not cover the bottom bar is
/// measured on the [Material] inside it.
Rect _snackBarMaterialRect(WidgetTester tester) {
  return tester.getRect(
    find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(Material),
    ),
  );
}

void main() {
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
          error.toString(), contains('Floating SnackBar presented off screen'));

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'floating snackbar stays above the embedded 80dp bottom bar and never '
    'goes off screen',
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
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);

      final Rect snackBarRect = tester.getRect(find.byType(SnackBar));
      final Rect materialRect = _snackBarMaterialRect(tester);
      final Rect textRect = tester.getRect(find.text(_message));
      final Rect barRect = tester.getRect(find.byKey(_embeddedBarKey));

      // Flutter's assertion is `snackBarTop >= 0`.
      expect(snackBarRect.top, greaterThanOrEqualTo(0.0));
      // Below the status bar / app bar area.
      expect(textRect.top, greaterThanOrEqualTo(kToolbarHeight));
      // Fully above the embedded 80dp bar.
      expect(textRect.bottom, lessThanOrEqualTo(barRect.top));
      // The whole layout box is far smaller than the screen (the old bug).
      expect(snackBarRect.height, lessThan(_screenSize.height - _safeBottom));
      // The visible SnackBar never covers the bar. The outer SnackBar box
      // includes the transparent margin, so measure the Material itself.
      expect(
        materialRect.overlaps(barRect),
        isFalse,
        reason: 'snackbar material $materialRect overlaps bar $barRect',
      );
    },
  );

  testWidgets(
    'floating snackbar stays above Scaffold.bottomNavigationBar and never '
    'goes off screen',
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
          bottomNavigationBar: Container(
            key: _scaffoldBarKey,
            height: _navBarHeight,
            color: Colors.black,
          ),
        ),
      );

      SnackBarHelper.showTopSnackBar(context, _message);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);

      final Rect snackBarRect = tester.getRect(find.byType(SnackBar));
      final Rect materialRect = _snackBarMaterialRect(tester);
      final Rect textRect = tester.getRect(find.text(_message));
      final Rect barRect = tester.getRect(find.byKey(_scaffoldBarKey));

      expect(snackBarRect.top, greaterThanOrEqualTo(0.0));
      expect(textRect.top, greaterThanOrEqualTo(kToolbarHeight));
      expect(textRect.bottom, lessThanOrEqualTo(barRect.top));
      expect(
        materialRect.overlaps(barRect),
        isFalse,
        reason: 'snackbar material $materialRect overlaps bar $barRect',
      );
    },
  );

  testWidgets(
    'async helper keeps the public behaviour: clears previous snackbars, '
    'uses the requested colour and duration',
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
        message: 'first',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      SnackBarHelper.showTopSnackBarAsync(
        messenger: messenger,
        screenHeight: size.height,
        statusBarHeight: 24,
        message: _message,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('first'), findsNothing);
      expect(find.text(_message), findsOneWidget);

      final SnackBar snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
      expect(snackBar.duration, const Duration(seconds: 5));
      expect(snackBar.behavior, SnackBarBehavior.floating);
    },
  );
}
