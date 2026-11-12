import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Height of the app's embedded bottom navigation bar
/// (`lib/shared/widgets/bottom_nav_bar.dart`).
const double _bottomNavBarHeight = 80.0;

/// Extra breathing room between the SnackBar and the widgets around it.
const double _bottomMarginGap = 8.0;
const double _topMarginGap = 4.0;

/// Horizontal inset used by the floating SnackBar.
const double _horizontalMargin = 16.0;

/// Conservative vertical room reserved for the SnackBar content when bounding
/// the margins on short viewports. Flutter asserts that a floating SnackBar
/// whose top edge ends up above the viewport is "presented off screen".
const double _contentHeightBudget = 200.0;

/// Helper class to show floating SnackBars below the top app-bar area.
///
/// A [SnackBarBehavior.floating] SnackBar is offset from the bottom of the
/// Scaffold by its `margin`. Passing a bounded margin keeps the SnackBar
/// above the embedded 80dp bottom navigation bar while avoiding the
/// full-screen margin that used to trip the
/// "Floating SnackBar presented off screen" assertion.
class SnackBarHelper {
  /// Shows a SnackBar below the top app-bar area
  ///
  /// [context] - BuildContext for showing the SnackBar
  /// [message] - Text message to display
  /// [duration] - How long to show the SnackBar (default: 2 seconds)
  /// [backgroundColor] - Optional background color for the SnackBar
  static void showTopSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    final mediaQuery = MediaQuery.of(context);

    _showSnackBarInternal(
      messenger: ScaffoldMessenger.of(context),
      screenHeight: mediaQuery.size.height,
      statusBarHeight: mediaQuery.padding.top,
      bottomSafeArea: mediaQuery.viewPadding.bottom,
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }

  /// Async-safe version for showing SnackBar after async gaps.
  /// Capture context values before await and pass them here.
  ///
  /// [screenHeight] and [statusBarHeight] are captured by the caller before the
  /// async gap. The bottom safe-area inset is read from the messenger's
  /// context when it is still mounted, falling back to zero otherwise.
  static void showTopSnackBarAsync({
    required ScaffoldMessengerState messenger,
    required double screenHeight,
    required double statusBarHeight,
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    final mediaQuery =
        messenger.mounted ? MediaQuery.maybeOf(messenger.context) : null;

    _showSnackBarInternal(
      messenger: messenger,
      screenHeight: screenHeight,
      statusBarHeight: statusBarHeight,
      bottomSafeArea: mediaQuery?.viewPadding.bottom ?? 0.0,
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }

  /// Shared internal logic for both sync and async SnackBar methods
  static void _showSnackBarInternal({
    required ScaffoldMessengerState messenger,
    required double screenHeight,
    required double statusBarHeight,
    required double bottomSafeArea,
    required String message,
    Duration? duration,
    Color? backgroundColor,
  }) {
    // Keep the SnackBar below the status bar and app bar.
    final topMargin = statusBarHeight + kToolbarHeight + _topMarginGap;

    // Keep it above the embedded 80dp bottom navigation bar, which itself
    // sits above the bottom safe-area inset.
    final desiredBottomMargin =
        _bottomNavBarHeight + bottomSafeArea + _bottomMarginGap;

    // Bound the margin so the floating SnackBar always fits on screen, even on
    // short viewports or with a tall SnackBar. The previous implementation used
    // `screenHeight - topMargin - estimatedHeight` as the bottom margin, which
    // made the layout box as tall as the screen and tripped Flutter's
    // "Floating SnackBar presented off screen" assertion once the bottom
    // safe-area inset was taken into account.
    final maxBottomMargin =
        math.max(0.0, screenHeight - topMargin - _contentHeightBudget);
    final bottomMargin = math.min(desiredBottomMargin, maxBottomMargin);

    // Clear any existing SnackBars to prevent stacking
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: topMargin,
          left: _horizontalMargin,
          right: _horizontalMargin,
          bottom: bottomMargin,
        ),
      ),
    );
  }
}
