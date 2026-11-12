import 'dart:async';

import 'package:flutter/material.dart';

/// Height of the app's embedded bottom navigation bar
/// (`lib/shared/widgets/bottom_nav_bar.dart`).
const double _bottomNavBarHeight = 80.0;

/// Extra breathing room between the legacy SnackBar and the widgets around it.
const double _bottomMarginGap = 8.0;

/// Horizontal inset used by both the banner and the legacy floating SnackBar.
const double _horizontalMargin = 16.0;

/// Distance between the top app-bar area and the banner.
const double _topGap = 4.0;

/// Conservative vertical room reserved for the SnackBar content when bounding
/// the legacy margins on short viewports.
const double _contentHeightBudget = 200.0;

/// Compact, top-anchored transient notification.
///
/// The banner is inserted into the root [Overlay] just below the status bar and
/// app-bar area, so it never covers the bottom navigation bar, the trade action
/// row or any other bottom control. The previous implementation used a
/// bottom-anchored floating [SnackBar]; a transient toast there could intercept
/// taps meant for the action button underneath it (observed in the Phase 6B
/// regtest run) and needed a full-screen margin that tripped Flutter's
/// "Floating SnackBar presented off screen" assertion.
///
/// Both public entry points keep their original signatures. The async variant
/// accepts an optional [OverlayState] because a [ScaffoldMessengerState] sits
/// above the [Navigator] and cannot reach an overlay; callers capture
/// `Overlay.of(context, rootOverlay: true)` before the async gap and pass it
/// here. When no overlay is supplied the legacy bounded floating SnackBar is
/// used, so existing call sites keep working.
class SnackBarHelper {
  /// The single banner currently on screen, if any.
  static OverlayEntry? _entry;

  /// Auto-dismiss timer for the banner in [_entry].
  static Timer? _timer;

  /// Shows a transient banner below the top app-bar area.
  ///
  /// [context] - BuildContext used to find the root overlay
  /// [message] - Text message to display
  /// [duration] - How long to show the banner (default: 2 seconds)
  /// [backgroundColor] - Optional background color for the banner
  static void showTopSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != null) {
      _showBanner(
        overlay: overlay,
        message: message,
        duration: duration,
        backgroundColor: backgroundColor,
      );
      return;
    }

    // No overlay in this subtree (for example a context above MaterialApp).
    // Keep the notification visible with the legacy bounded SnackBar.
    _showLegacySnackBar(
      messenger: ScaffoldMessenger.of(context),
      screenHeight: mediaQuery.size.height,
      statusBarHeight: mediaQuery.padding.top,
      bottomSafeArea: mediaQuery.viewPadding.bottom,
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }

  /// Async-safe version for showing a banner after async gaps.
  ///
  /// Capture [messenger], [screenHeight], [statusBarHeight] and [overlay]
  /// before the await and pass them here. [overlay] is preferred: when it is
  /// null or no longer mounted the legacy floating SnackBar is used.
  static void showTopSnackBarAsync({
    required ScaffoldMessengerState messenger,
    required double screenHeight,
    required double statusBarHeight,
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    OverlayState? overlay,
  }) {
    if (overlay != null && overlay.mounted) {
      _showBanner(
        overlay: overlay,
        message: message,
        duration: duration,
        backgroundColor: backgroundColor,
      );
      return;
    }

    final mediaQuery =
        messenger.mounted ? MediaQuery.maybeOf(messenger.context) : null;
    _showLegacySnackBar(
      messenger: messenger,
      screenHeight: screenHeight,
      statusBarHeight: statusBarHeight,
      bottomSafeArea: mediaQuery?.viewPadding.bottom ?? 0.0,
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
    );
  }

  /// Removes the visible banner immediately, if any.
  ///
  /// Exposed for tests and for callers that want to clear the notification when
  /// leaving a screen.
  static void dismiss() {
    _dismissBanner();
  }

  /// Inserts the banner and schedules its dismissal.
  static void _showBanner({
    required OverlayState overlay,
    required String message,
    required Duration duration,
    required Color? backgroundColor,
  }) {
    // Only one transient notification is visible at a time.
    _dismissBanner();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        // This context lives under the root Overlay, above the route's
        // Scaffold, so its padding is the untrimmed system inset.
        final topInset = MediaQuery.of(context).padding.top;
        final background = backgroundColor ?? scheme.inverseSurface;
        final foreground =
            backgroundColor == null ? scheme.onInverseSurface : Colors.white;

        return Positioned(
          top: topInset + kToolbarHeight + _topGap,
          left: _horizontalMargin,
          right: _horizontalMargin,
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Material(
              color: background,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (identical(_entry, entry)) {
                    _dismissBanner();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Text(
                    message,
                    style: TextStyle(color: foreground),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, () {
      if (identical(_entry, entry)) {
        _dismissBanner();
      }
    });
  }

  /// Removes the banner and cancels its timer.
  static void _dismissBanner() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  /// Legacy bounded floating SnackBar used when no overlay is available.
  static void _showLegacySnackBar({
    required ScaffoldMessengerState messenger,
    required double screenHeight,
    required double statusBarHeight,
    required double bottomSafeArea,
    required String message,
    Duration? duration,
    Color? backgroundColor,
  }) {
    // Keep the SnackBar below the status bar and app bar.
    final topMargin = statusBarHeight + kToolbarHeight + _topGap;

    // Keep it above the embedded 80dp bottom navigation bar, which itself
    // sits above the bottom safe-area inset.
    final desiredBottomMargin =
        _bottomNavBarHeight + bottomSafeArea + _bottomMarginGap;

    // Bound the margin so the floating SnackBar always fits on screen. The
    // previous implementation used `screenHeight - topMargin - estimatedHeight`
    // unbounded, which made the layout box as tall as the screen and tripped
    // Flutter's "Floating SnackBar presented off screen" assertion.
    final maxBottomMargin = screenHeight - topMargin - _contentHeightBudget;
    final bottomMargin = desiredBottomMargin < maxBottomMargin
        ? desiredBottomMargin
        : maxBottomMargin;
    final safeBottomMargin = bottomMargin < 0 ? 0.0 : bottomMargin;

    // Clear any existing SnackBars to prevent stacking.
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
          bottom: safeBottomMargin,
        ),
      ),
    );
  }
}
