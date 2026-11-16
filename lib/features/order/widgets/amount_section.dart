import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/automation/automation_id.dart';
import 'package:satonero_mobile/core/automation/automation_ids.dart';
import 'package:satonero_mobile/data/models/enums/order_type.dart';
import 'package:satonero_mobile/features/order/widgets/form_section.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/widgets/choice_segment.dart';

/// The maker's fiat amount for the order: a single fixed amount or a range
/// (min..max). The mode is chosen through an explicit segmented control rather
/// than the previous implicit "type then tap the second field" flow.
class AmountSection extends StatefulWidget {
  final OrderType orderType;
  final Function(int? minAmount, int? maxAmount) onAmountChanged;
  final String? Function(double)? validateSatsRange;
  final String? validationError;
  final ValueChanged<bool>? onRangeModeChanged;

  /// Currently selected fiat code, used to label the amount field
  /// (e.g. "Enter the amount of USD you want to receive"). Null/empty falls
  /// back to the generic word "fiat".
  final String? fiatCode;

  const AmountSection({
    super.key,
    required this.orderType,
    required this.onAmountChanged,
    this.validateSatsRange,
    this.validationError,
    this.onRangeModeChanged,
    this.fiatCode,
  });

  @override
  State<AmountSection> createState() => _AmountSectionState();
}

class _AmountSectionState extends State<AmountSection> {
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  bool _isRangeMode = false;

  @override
  void initState() {
    super.initState();
    _minAmountController.addListener(_onAmountFieldChanged);
    _maxAmountController.addListener(_onAmountFieldChanged);
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _onModeChanged(bool isRange) {
    if (isRange == _isRangeMode) return;
    setState(() {
      _isRangeMode = isRange;
      if (!isRange) {
        _maxAmountController.clear();
      }
    });
    widget.onRangeModeChanged?.call(isRange);
    _notifyAmountChanged();
  }

  void _onAmountFieldChanged() {
    _notifyAmountChanged();
  }

  void _notifyAmountChanged() {
    final minAmount = int.tryParse(_minAmountController.text);
    final maxAmount = int.tryParse(_maxAmountController.text);
    widget.onAmountChanged(minAmount, maxAmount);
  }

  String _getTitle() {
    if (_isRangeMode) {
      return widget.orderType == OrderType.buy
          ? S.of(context)!.creatingRangeOrderBuySend
          : S.of(context)!.creatingRangeOrder;
    }
    final currency = (widget.fiatCode != null && widget.fiatCode!.isNotEmpty)
        ? widget.fiatCode!
        : 'fiat';
    return widget.orderType == OrderType.buy
        ? S.of(context)!.enterAmountYouWantToSendCurrency(currency)
        : S.of(context)!.enterAmountYouWantToReceiveCurrency(currency);
  }

  String? _validateMinAmount(String? value) {
    // Only validate format - all error messages handled by validationError widget
    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
      return ''; // Return empty string to trigger form validation but not show message
    }
    return null;
  }

  String? _validateMaxAmount(String? value) {
    // Only validate format - all error messages handled by validationError widget
    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
      return ''; // Return empty string to trigger form validation but not show message
    }
    return null;
  }

  Widget _buildValidationMessage() {
    if (widget.validationError == null) return const SizedBox.shrink();

    return Container(
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
              widget.validationError!,
              style: TextStyle(
                color: AppTheme.colors(context).danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: _getTitle(),
      icon: Icon(Icons.money, color: AppTheme.colors(context).accent, size: 18),
      iconBackgroundColor:
          AppTheme.colors(context).accent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceSegment<bool>(
            value: _isRangeMode,
            onChanged: _onModeChanged,
            options: [
              ChoiceSegmentOption<bool>(
                value: false,
                label: S.of(context)!.amountSingle,
              ),
              ChoiceSegmentOption<bool>(
                value: true,
                label: S.of(context)!.amountRange,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input row (single amount, or min + max for a range).
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('fiatAmountField'),
                  controller: _minAmountController,
                  style: TextStyle(color: AppTheme.colors(context).textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _isRangeMode
                        ? S.of(context)!.minAmount
                        : S.of(context)!.enterAmountHint,
                    hintStyle:
                        TextStyle(color: AppTheme.colors(context).textInactive),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validateMinAmount,
                ).withAutomationId(AutomationIds.orderCreateFiatAmount),
              ),
              if (_isRangeMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    S.of(context)!.to,
                    style: TextStyle(
                      color: AppTheme.colors(context).textInactive,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    key: const Key('maxAmountField'),
                    controller: _maxAmountController,
                    style:
                        TextStyle(color: AppTheme.colors(context).textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: S.of(context)!.maxAmount,
                      hintStyle: TextStyle(
                          color: AppTheme.colors(context).textInactive),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateMaxAmount,
                  ).withAutomationId(AutomationIds.orderCreateFiatAmountMax),
                ),
              ],
            ],
          ),

          // Validation message (shown inside card when there's an error)
          if (widget.validationError != null) ...[
            const SizedBox(height: 12),
            _buildValidationMessage(),
          ],
        ],
      ),
    );
  }
}
