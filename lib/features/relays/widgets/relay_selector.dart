import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/automation/automation_id.dart';
import 'package:satonero_mobile/core/automation/automation_ids.dart';
import 'package:satonero_mobile/features/relays/relay.dart';
import 'package:satonero_mobile/features/relays/relays_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/utils/snack_bar_helper.dart';
import 'package:satonero_mobile/shared/widgets/mostro_switch.dart';

class RelaySelector extends ConsumerWidget {
  const RelaySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relaysNotifier = ref.watch(relaysProvider.notifier);
    final mostroRelays = relaysNotifier.mostroRelaysWithStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description only
        Text(
          S.of(context)!.relaysDescription,
          style: TextStyle(
            color: AppTheme.colors(context).textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),

        // Relay list
        if (mostroRelays.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.colors(context).cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.colors(context).textSecondary,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context)!.noMostroRelaysAvailable,
                  style: TextStyle(
                    color: AppTheme.colors(context).textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...mostroRelays.map((relayInfo) {
            return _buildRelayItem(context, ref, relayInfo);
          }),

        const SizedBox(height: 24),

        // Add relay button - aligned to the right
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () async {
                await showAddDialog(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors(context).accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                S.of(context)!.addRelay,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ).withAutomationId(AutomationIds.settingsRelaysAdd),
          ],
        ),
      ],
    );
  }

  Widget _buildRelayItem(
      BuildContext context, WidgetRef ref, MostroRelayInfo relayInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Status dot - green if active, grey if inactive
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: relayInfo.isActive ? AppTheme.colors(context).accent : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Relay URL
          Expanded(
            child: Text(
              relayInfo.url,
              style: TextStyle(
                color: AppTheme.colors(context).textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Control - Switch for Mostro/default relays, Delete button for user relays
          relayInfo.source == RelaySource.user
              ? _buildDeleteButton(context, ref, relayInfo)
              : _buildRelaySwitch(context, ref, relayInfo),
        ],
      ),
    ).withAutomationId(AutomationIds.settingsRelayItem(relayInfo.url),
        merge: false);
  }

  Widget _buildDeleteButton(
      BuildContext context, WidgetRef ref, MostroRelayInfo relayInfo) {
    return Container(
      width: 140,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () async {
              await _showDeleteUserRelayDialog(context, ref, relayInfo);
            },
            child: Icon(
              Icons.delete,
              color: AppTheme.colors(context).textPrimary,
              size: 24,
            ),
          ).withAutomationId(AutomationIds.settingsRelayDelete(relayInfo.url)),
        ],
      ),
    );
  }

  Widget _buildRelaySwitch(
      BuildContext context, WidgetRef ref, MostroRelayInfo relayInfo) {
    return MostroSwitch(
      value: relayInfo.isActive,
      onChanged: (value) async {
        await _handleRelayToggle(context, ref, relayInfo);
      },
    );
  }

  /// Show confirmation dialog for deleting user relay
  Future<void> _showDeleteUserRelayDialog(
      BuildContext context, WidgetRef ref, MostroRelayInfo relayInfo) async {
    final relaysNotifier = ref.read(relaysProvider.notifier);

    // Check if this would leave no active relays
    if (relaysNotifier.wouldLeaveNoActiveRelays(relayInfo.url)) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.colors(context).inputBackground,
          title: Text(
            S.of(ctx)!.cannotBlacklistLastRelayTitle,
            style: TextStyle(color: AppTheme.colors(context).textPrimary),
          ),
          content: Text(
            S.of(ctx)!.cannotBlacklistLastRelayMessage,
            style: TextStyle(color: AppTheme.colors(context).textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                S.of(ctx)!.cannotBlacklistLastRelayOk,
                style: TextStyle(color: AppTheme.colors(context).textPrimary),
              ),
            ),
          ],
        ),
      );
      return; // Exit early - don't proceed with deletion
    }

    // If not the last relay, show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.colors(context).inputBackground,
          title: Text(
            S.of(context)!.deleteUserRelayTitle,
            style: TextStyle(color: AppTheme.colors(context).textPrimary),
          ),
          content: Text(
            S.of(context)!.deleteUserRelayMessage,
            style: TextStyle(color: AppTheme.colors(context).textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                S.of(context)!.deleteUserRelayCancel,
                style: TextStyle(color: AppTheme.colors(context).textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                S.of(context)!.deleteUserRelayConfirm,
                style: TextStyle(color: AppTheme.colors(context).accent),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed deletion, remove the relay
    if (shouldDelete == true) {
      await relaysNotifier.removeRelay(relayInfo.url);
    }
  }

  /// Handle relay toggle with safety checks and confirmation dialogs
  Future<void> _handleRelayToggle(
      BuildContext context, WidgetRef ref, MostroRelayInfo relayInfo) async {
    final isCurrentlyBlacklisted = !relayInfo.isActive;
    final relaysNotifier = ref.read(relaysProvider.notifier);

    // Detect relay type (user vs mostro)
    final currentRelays = ref.read(relaysProvider);
    final relay = currentRelays.firstWhere(
      (r) => r.url == relayInfo.url,
      orElse: () => Relay(url: ''), // Empty relay if not found
    );
    final isUserRelay =
        relay.url.isNotEmpty && relay.source == RelaySource.user;

    // If removing from blacklist, proceed directly
    if (isCurrentlyBlacklisted) {
      await relaysNotifier.toggleMostroRelayBlacklist(relayInfo.url);
      return;
    }

    // Check if this would be the last active relay - BLOCK the action
    if (relaysNotifier.wouldLeaveNoActiveRelays(relayInfo.url)) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.colors(context).inputBackground,
            title: Text(
              S.of(context)!.cannotBlacklistLastRelayTitle,
              style: TextStyle(color: AppTheme.colors(context).textPrimary),
            ),
            content: Text(
              S.of(context)!.cannotBlacklistLastRelayMessage,
              style: TextStyle(color: AppTheme.colors(context).textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  S.of(context)!.cannotBlacklistLastRelayOk,
                  style: TextStyle(color: AppTheme.colors(context).textPrimary),
                ),
              ),
            ],
          );
        },
      );
      return; // Block the action - do NOT proceed
    }

    // Handle deactivation based on relay type
    if (isUserRelay) {
      // User relay: Delete completely (no blacklisting needed)
      await relaysNotifier.removeRelay(relayInfo.url);
    } else {
      // Mostro relay: blacklist it directly
      await relaysNotifier.toggleMostroRelayBlacklist(relayInfo.url);
    }
  }

  /// Show dialog to add a new user relay with full validation
  Future<void> showAddDialog(BuildContext context, WidgetRef ref) async {
    final textController = TextEditingController();
    final relaysNotifier = ref.read(relaysProvider.notifier);
    bool isLoading = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.colors(context).cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Text(
                S.of(context)!.addRelayDialogTitle,
                style: TextStyle(
                  color: AppTheme.colors(context).textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.colors(context).inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: textController,
                        enabled: !isLoading,
                        style: TextStyle(color: AppTheme.colors(context).textPrimary),
                        decoration: InputDecoration(
                          labelText: S.of(context)!.addRelayDialogPlaceholder,
                          labelStyle:
                              TextStyle(color: AppTheme.colors(context).textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          hintText:
                              'relay.example.com or wss://relay.example.com',
                          hintStyle:
                              TextStyle(color: AppTheme.colors(context).textSecondary),
                          errorText: errorMessage,
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                        autofocus: true,
                      ).withAutomationId(AutomationIds.settingsRelaysAddUrl),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.colors(context).textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            S.of(context)!.addRelayDialogTesting,
                            style:
                                TextStyle(color: AppTheme.colors(context).textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!isLoading) ...[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      S.of(context)!.addRelayDialogCancel,
                      style: TextStyle(
                        color: AppTheme.colors(context).textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).withAutomationId(AutomationIds.settingsRelaysAddCancel),
                  const SizedBox(width: 12),
                ],
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final input = textController.text.trim();
                          if (input.isEmpty) return;

                          // Capture context values before async operations
                          final localizations = S.of(context)!;
                          final navigator = Navigator.of(dialogContext);

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final result = await relaysNotifier
                                .addRelayWithSmartValidation(
                              input,
                              errorOnlySecure:
                                  localizations.addRelayErrorOnlySecure,
                              errorNoHttp: localizations.addRelayErrorNoHttp,
                              errorInvalidDomain:
                                  localizations.addRelayErrorInvalidDomain,
                              errorAlreadyExists:
                                  localizations.addRelayErrorAlreadyExists,
                              errorNotValid:
                                  localizations.addRelayErrorNotValid,
                            );

                            if (result.success) {
                              navigator.pop();
                              if (context.mounted) {
                                SnackBarHelper.showTopSnackBar(
                                  context,
                                  localizations.addRelaySuccessMessage(
                                      result.normalizedUrl!),
                                  backgroundColor: Colors.green,
                                );
                              }
                            } else {
                              setState(() {
                                errorMessage = result.error;
                                isLoading = false;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              errorMessage = localizations.addRelayErrorGeneric;
                              isLoading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors(context).accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  child: Text(
                    S.of(context)!.addRelayDialogAdd,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).withAutomationId(AutomationIds.settingsRelaysAddConfirm),
              ],
            );
          },
        );
      },
    );
  }
}
