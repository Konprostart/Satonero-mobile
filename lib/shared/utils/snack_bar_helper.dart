import 'package:flutter/material.dart';

/// Helper class for showing SnackBars anchored to the bottom of the Scaffold.
///
/// A [SnackBarBehavior.fixed] SnackBar is laid out by the Scaffold inside its
/// content area, so it is placed above a `Scaffold.bottomNavigationBar` or
/// persistent footer instead of overlapping them.
class SnackBarHelper {
  /// Shows a SnackBar anchored to the bottom of the Scaffold
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
    _showSnackBarInternal(
      messenger: ScaffoldMessenger.of(context),
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }

  /// Async-safe version for showing SnackBar after async gaps.
  /// Capture context values before await and pass them here.
  ///
  /// [screenHeight] and [statusBarHeight] are retained for API compatibility
  /// with existing call sites; the Scaffold positions the SnackBar itself.
  static void showTopSnackBarAsync({
    required ScaffoldMessengerState messenger,
    required double screenHeight,
    required double statusBarHeight,
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    _showSnackBarInternal(
      messenger: messenger,
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }

  /// Shared internal logic for both sync and async SnackBar methods
  static void _showSnackBarInternal({
    required ScaffoldMessengerState messenger,
    required String message,
    Duration? duration,
    Color? backgroundColor,
  }) {
    // Clear any existing SnackBars to prevent stacking
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        // A fixed SnackBar is laid out by the Scaffold inside its content
        // area, so it sits above Scaffold.bottomNavigationBar and persistent
        // footer buttons. This replaces the previous full-screen bottomMargin
        // trick that made the floating SnackBar fail the "Floating SnackBar
        // presented off screen" assertion.
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}
