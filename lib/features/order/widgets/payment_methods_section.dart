import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/core/automation/automation_id.dart';
import 'package:satonero_mobile/core/automation/automation_ids.dart';
import 'package:satonero_mobile/features/order/providers/payment_methods_provider.dart';
import 'package:satonero_mobile/features/order/widgets/form_section.dart';
import 'package:satonero_mobile/shared/providers/exchange_service_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/core/app_theme.dart';

class PaymentMethodsSection extends ConsumerWidget {
  final List<String> selectedMethods;
  final TextEditingController customController;
  final Function(List<String>) onMethodsChanged;

  /// Custom methods committed via the "Add" button (unlimited).
  final List<String> customMethods;

  /// Invoked when the user taps "Add" with a non-empty custom method.
  final VoidCallback? onAddCustomMethod;

  /// Invoked when the user removes a committed custom method chip.
  final void Function(String method)? onRemoveCustomMethod;

  /// Helper function to translate payment method names
  String _translatePaymentMethod(String method, BuildContext context) {
    switch (method) {
      case 'Bank Transfer':
        return S.of(context)!.bankTransfer;
      case 'Cash in person':
        return S.of(context)!.cashInPerson;
      case 'Other':
        return S.of(context)!.other;
      default:
        return method;
    }
  }

  const PaymentMethodsSection({
    super.key,
    required this.selectedMethods,
    required this.customController,
    required this.onMethodsChanged,
    this.customMethods = const [],
    this.onAddCustomMethod,
    this.onRemoveCustomMethod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFiatCode = ref.watch(selectedFiatCodeProvider);

    final paymentMethodsData = ref.watch(paymentMethodsDataProvider);

    return FormSection(
      title: S.of(context)!.paymentMethodsForCurrency(selectedFiatCode ?? ''),
      icon:
          Icon(Icons.credit_card, color: AppTheme.colors(context).accent, size: 18),
      iconBackgroundColor: AppTheme.colors(context).accent.withValues(alpha: 0.3),
      extraContent: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('paymentMethodField'),
                    controller: customController,
                    style: TextStyle(
                        color: AppTheme.colors(context).textPrimary,
                        fontSize: 15),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onAddCustomMethod?.call(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: S.of(context)!.enterCustomPaymentMethod,
                      hintStyle: TextStyle(
                          color: AppTheme.colors(context).textInactive,
                          fontSize: 13),
                    ),
                  ).withAutomationId(AutomationIds.orderCreatePaymentMethod),
                ),
                IconButton(
                  key: const Key('addCustomPaymentMethodButton'),
                  onPressed: onAddCustomMethod,
                  tooltip: S.of(context)!.add,
                  icon: Icon(
                    Icons.add_circle,
                    color: AppTheme.colors(context).accent,
                    size: 28,
                  ),
                ),
              ],
            ),
            if (customMethods.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: customMethods
                    .map((method) => Chip(
                          label: Text(
                            method,
                            style: TextStyle(
                                color: AppTheme.colors(context).textPrimary),
                          ),
                          backgroundColor: AppTheme.colors(context)
                              .accent
                              .withValues(alpha: 0.15),
                          side: BorderSide(
                              color: AppTheme.colors(context).accent),
                          deleteIconColor:
                              AppTheme.colors(context).textSecondary,
                          onDeleted: onRemoveCustomMethod == null
                              ? null
                              : () => onRemoveCustomMethod!(method),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      child: paymentMethodsData.when(
        loading: () => Text(S.of(context)!.loadingPaymentMethods,
            style: TextStyle(color: AppTheme.colors(context).textPrimary)),
        error: (error, _) => Text(
            S.of(context)!.errorLoadingPaymentMethods(error.toString()),
            style:  TextStyle(color: AppTheme.colors(context).danger)),
        data: (data) {
          final displayText = selectedMethods.isEmpty
              ? S.of(context)!.selectPaymentMethods
              : selectedMethods.join(', ');

          List<String> availableMethods = [];
          if (data.containsKey(selectedFiatCode)) {
            availableMethods = List<String>.from(data[selectedFiatCode])
                .map((method) => _translatePaymentMethod(method, context))
                .toList();
          } else {
            availableMethods = List<String>.from(data['default'] ??
                    ['Bank Transfer', 'Cash in person', 'Other'])
                .map((method) => _translatePaymentMethod(method, context))
                .toList();
          }

          return InkWell(
            onTap: () {
              _showPaymentMethodsDialog(
                context,
                availableMethods,
                selectedMethods,
                onMethodsChanged,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedMethods.isEmpty
                          ? AppTheme.colors(context).textInactive
                          : AppTheme.colors(context).textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    color: AppTheme.colors(context).textPrimary),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPaymentMethodsDialog(
    BuildContext context,
    List<String> availableMethods,
    List<String> selectedMethods,
    Function(List<String>) onMethodsChanged,
  ) {
    // Remove "Other" from available methods since custom field is always visible
    final translatedOther = _translatePaymentMethod('Other', context);
    availableMethods =
        availableMethods.where((m) => m != translatedOther).toList();

    // Normalize to current locale so checkbox states align with localized labels
    final localizedSelected = selectedMethods
        .map((m) => _translatePaymentMethod(m, context))
        .where((m) => m != translatedOther)
        .toList();
    List<String> dialogSelectedMethods = List<String>.from(localizedSelected);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.colors(context).cardBackground,
              title: Text(
                S.of(context)!.selectPaymentMethodsTitle,
                style: TextStyle(color: AppTheme.colors(context).textPrimary, fontSize: 18),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: availableMethods
                        .map((method) => CheckboxListTile(
                              title: Text(method,
                                  style: TextStyle(
                                      color: AppTheme.colors(context)
                                          .textPrimary)),
                              value: dialogSelectedMethods.contains(method),
                              activeColor: AppTheme.colors(context).accent,
                              checkColor: AppTheme.colors(context).onAccent,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (selected) {
                                setDialogState(() {
                                  if (selected == true) {
                                    dialogSelectedMethods.add(method);
                                  } else {
                                    dialogSelectedMethods.remove(method);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    S.of(context)!.cancel,
                    style: TextStyle(
                      color: AppTheme.colors(context).textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    onMethodsChanged(dialogSelectedMethods);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors(context).accent,
                    foregroundColor: AppTheme.colors(context).onAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    S.of(context)!.confirm,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
