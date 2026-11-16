import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/automation/automation_id.dart';
import 'package:satonero_mobile/core/automation/automation_ids.dart';
import 'package:satonero_mobile/features/order/widgets/form_section.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/widgets/choice_segment.dart';

/// How the sats side of the order is priced: market (exchange rate at
/// take time + optional premium) or fixed (an exact sats amount).
class PriceTypeSection extends StatelessWidget {
  final bool isMarketRate;
  final ValueChanged<bool> onToggle;
  final String? errorMessage;

  /// When false (e.g. the amount is a range), the fixed-price option is
  /// disabled because a range order always trades at market price.
  final bool fixedEnabled;

  const PriceTypeSection({
    super.key,
    required this.isMarketRate,
    required this.onToggle,
    this.errorMessage,
    this.fixedEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: S.of(context)!.priceType,
      icon: Icon(
        Icons.attach_money,
        size: 18,
        color: AppTheme.colors(context).textPrimary,
      ),
      iconBackgroundColor:
          AppTheme.colors(context).accent.withValues(alpha: 0.3),
      infoTooltip: S.of(context)!.priceTypeTooltip,
      infoTitle: S.of(context)!.priceType,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceSegment<bool>(
            value: isMarketRate,
            onChanged: onToggle,
            options: [
              ChoiceSegmentOption<bool>(
                value: true,
                label: S.of(context)!.market,
              ),
              ChoiceSegmentOption<bool>(
                value: false,
                label: S.of(context)!.fixed,
                key: const Key('fixedSwitch'),
                enabled: fixedEnabled,
              ),
            ],
          ).withAutomationId(AutomationIds.orderCreatePriceType),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.colors(context).danger.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.colors(context).danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: AppTheme.colors(context).danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
