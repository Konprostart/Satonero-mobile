import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';

/// One option inside a [ChoiceSegment] control.
class ChoiceSegmentOption<T> {
  const ChoiceSegmentOption({
    required this.value,
    required this.label,
    this.key,
    this.enabled = true,
  });

  /// The value reported back through [ChoiceSegment.onChanged].
  final T value;

  /// Short, user-facing label.
  final String label;

  /// Optional key so a single option can be targeted by automation tests.
  final Key? key;

  /// When false the option is dimmed and not tappable.
  final bool enabled;
}

/// A clean, theme-aware single-choice segmented control.
///
/// Used for binary toggles such as Single/Range (order amount) and Market/Fixed
/// (order price). Each option is a full-height tappable area so it can carry a
/// [Key] directly, which Flutter's built-in `SegmentedButton` does not allow.
class ChoiceSegment<T> extends StatelessWidget {
  const ChoiceSegment({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.padding = const EdgeInsets.all(4),
  });

  /// The currently selected value.
  final T value;

  /// Called with the tapped option's value.
  final ValueChanged<T> onChanged;

  /// The options rendered in order.
  final List<ChoiceSegmentOption<T>> options;

  /// Inner padding around the options.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
                child: _OptionTile<T>(
                    option: option,
                    selected: option.value == value,
                    onTap: () => onChanged(option.value))),
        ],
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ChoiceSegmentOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    final Color background;
    final Color foreground;
    if (!option.enabled) {
      background = Colors.transparent;
      foreground = colors.textInactive;
    } else if (selected) {
      background = colors.accent;
      foreground = colors.onAccent;
    } else {
      background = Colors.transparent;
      foreground = colors.textSecondary;
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: option.enabled,
      child: GestureDetector(
        key: option.key,
        behavior: HitTestBehavior.opaque,
        onTap: option.enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
