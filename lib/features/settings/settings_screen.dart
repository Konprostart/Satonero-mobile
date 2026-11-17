import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/automation/automation_id.dart';
import 'package:satonero_mobile/core/automation/automation_ids.dart';
import 'package:satonero_mobile/core/config.dart';
import 'package:satonero_mobile/features/mostro/mostro_nodes_provider.dart';
import 'package:satonero_mobile/features/mostro/widgets/add_custom_node_dialog.dart';
import 'package:satonero_mobile/features/mostro/widgets/mostro_node_avatar.dart';
import 'package:satonero_mobile/features/mostro/widgets/mostro_node_selector.dart';
import 'package:satonero_mobile/features/mostro/widgets/trusted_badge.dart';
import 'package:satonero_mobile/features/relays/widgets/relay_selector.dart';
import 'package:satonero_mobile/features/restore/restore_manager.dart';
import 'package:satonero_mobile/features/settings/settings_provider.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:satonero_mobile/features/telegram/telegram_deep_link.dart';
import 'package:satonero_mobile/features/telegram/telegram_link_provider.dart';
import 'package:satonero_mobile/features/telegram/telegram_link_service.dart';
import 'package:satonero_mobile/services/logger_service.dart';
import 'package:satonero_mobile/shared/widgets/currency_selection_dialog.dart';
import 'package:satonero_mobile/shared/providers/exchange_service_provider.dart';
import 'package:satonero_mobile/shared/widgets/language_selector.dart';
import 'package:satonero_mobile/shared/widgets/mostro_switch.dart';
import 'package:satonero_mobile/shared/widgets/trade_history_selector.dart';
import 'package:satonero_mobile/shared/utils/snack_bar_helper.dart';
import 'package:satonero_mobile/features/wallet/widgets/wallet_status_card.dart';
import 'package:satonero_mobile/features/cashu/widgets/cashu_wallet_card.dart';
import 'package:satonero_mobile/generated/l10n.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _lightningAddressController;
  bool _linkingTelegram = false;
  bool _switchingServerNode = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _lightningAddressController =
        TextEditingController(text: settings.defaultLightningAddress ?? '');
  }

  @override
  void dispose() {
    _lightningAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    // Listen to settings changes and update controllers
    ref.listen<Settings>(settingsProvider, (previous, next) {
      if (previous?.defaultLightningAddress != next.defaultLightningAddress) {
        final newText = next.defaultLightningAddress ?? '';
        if (_lightningAddressController.text != newText) {
          _lightningAddressController.text = newText;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(HeroIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ).withAutomationId(AutomationIds.appBarBack),
        title: Text(
          S.of(context)!.settings,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: colors.scaffoldBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance Card
                  _buildAppearanceCard(context),
                  const SizedBox(height: 16),

                  // Language Card
                  _buildLanguageCard(context),
                  const SizedBox(height: 16),

                  // Currency Card
                  _buildCurrencyCard(context),
                  const SizedBox(height: 16),

                  // Lightning Address Card
                  _buildLightningAddressCard(context),
                  const SizedBox(height: 16),

                  // Wallet Card (Lightning / NWC)
                  const WalletStatusCard(),
                  const SizedBox(height: 16),

                  // Cashu Mint Wallet Card (separate from the Lightning wallet)
                  const CashuWalletCard(),
                  const SizedBox(height: 16),

                  // Relays Card
                  _buildRelaysCard(context),
                  const SizedBox(height: 16),

                  // Server (Mostro node) Card
                  _buildMostroCard(context),
                  const SizedBox(height: 16),

                  // Private Mode Card
                  _buildPrivateModeCard(context),
                  const SizedBox(height: 16),

                  // Notification Settings Card
                  _buildNotificationSettingsCard(context),
                  const SizedBox(height: 16),

                  // Telegram Notifications Card
                  _buildTelegramNotificationsCard(context),
                  const SizedBox(height: 16),

                  // Trade History Card
                  _buildTradeHistoryCard(context),
                  const SizedBox(height: 16),

                  // Dev Tools Card
                  _buildDevToolsCard(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    final colors = AppTheme.colors(context);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sunMoon,
                    color: AppTheme.colors(context).lightningBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  S.of(context)!.appearance,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context)!.appearanceDescription,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeModePreference>(
                segments: [
                  ButtonSegment(
                    value: ThemeModePreference.system,
                    label: Text(S.of(context)!.themeSystem),
                    icon: const Icon(LucideIcons.monitor, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeModePreference.light,
                    label: Text(S.of(context)!.themeLight),
                    icon: const Icon(LucideIcons.sun, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeModePreference.dark,
                    label: Text(S.of(context)!.themeDark),
                    icon: const Icon(LucideIcons.moon, size: 16),
                  ),
                ],
                selected: {themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateThemeMode(selection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateModeCard(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.shield,
                    color: AppTheme.colors(context).accent, size: 24),
                const SizedBox(width: 12),
                Text(S.of(context)!.privateModeTitle,
                    style: TextStyle(
                        color: AppTheme.colors(context).textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showPrivateModeInfo(context),
                  child: Icon(Icons.help_outline,
                      color: AppTheme.colors(context).textSecondary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(S.of(context)!.privateModeDescription,
                style: TextStyle(
                    color: AppTheme.colors(context).textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    settings.privateMode
                        ? S.of(context)!.privateModeOn
                        : S.of(context)!.privateModeOff,
                    style: TextStyle(
                        color: AppTheme.colors(context).textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                Switch(
                  value: settings.privateMode,
                  onChanged: (value) async {
                    if (!value) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(S.of(context)!.privateModeTitle),
                          content:
                              Text(S.of(context)!.privateModeDisableWarning),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: Text(S.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: Text(S.of(context)!.privateModeClose),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                    }
                    await ref
                        .read(settingsProvider.notifier)
                        .updatePrivateMode(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              settings.privateMode
                  ? S.of(context)!.privateModeStatusOn
                  : S.of(context)!.privateModeStatusOff,
              style:
                  TextStyle(color: AppTheme.colors(context).textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivateModeInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context)!.privateModeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context)!.privateModeInfoText),
            const SizedBox(height: 12),
            Text(S.of(context)!.privateModeSetupText),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context)!.privateModeClose)),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.bell,
                  color: AppTheme.colors(context).accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context)!.notificationSettings,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context)!.notificationSettingsDescription,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/notification_settings'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.colors(context).inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.settings,
                        color: AppTheme.colors(context).accent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context)!.pushNotifications,
                              style: TextStyle(
                                color: AppTheme.colors(context).textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              S.of(context)!.pushNotificationsDescription,
                              style: TextStyle(
                                color: AppTheme.colors(context).textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppTheme.colors(context).textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelegramNotificationsCard(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.telegram,
                  color: AppTheme.colors(context).accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    S.of(context)!.telegramNotifications,
                    style: TextStyle(
                      color: AppTheme.colors(context).textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                MostroSwitch(
                  value: settings.telegramNotificationsEnabled,
                  onChanged:
                      Config.telegramConfigured ? _handleTelegramToggle : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context)!.telegramNotificationsDescription,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
            ),
            if (_linkingTelegram) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.colors(context).accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context)!.telegramLinking,
                    style: TextStyle(
                      color: AppTheme.colors(context).textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            if (!Config.telegramConfigured) ...[
              const SizedBox(height: 8),
              Text(
                S.of(context)!.telegramBotNotConfigured,
                style: TextStyle(
                  color: AppTheme.colors(context).textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleTelegramToggle(bool enabled) async {
    // Local persistence only. The preference is committed immediately and the
    // switch never waits on — or gets reverted by — the network handshake, so
    // toggling on/off always works even when the daemon is slow or unreachable.
    await ref
        .read(settingsProvider.notifier)
        .updateTelegramNotificationsEnabled(enabled);

    if (!enabled) {
      // Disabling is purely local: nothing to request from the daemon.
      return;
    }

    // The switch is disabled when Telegram is not configured, so this is a
    // defensive guard only.
    if (!Config.telegramConfigured) {
      return;
    }

    // Fire-and-forget the linking handshake so it can never block the toggle.
    // A second tap while a request is already in flight is a no-op.
    if (_linkingTelegram) return;
    unawaited(_linkTelegram());
  }

  Future<void> _linkTelegram() async {
    setState(() => _linkingTelegram = true);
    try {
      final code = await ref.read(telegramLinkServiceProvider).requestCode();
      // The screen may have been disposed while the request was in flight.
      if (!mounted) return;
      // The user may have toggled Telegram off while the request was in
      // flight; in that case do not surface the deep link.
      if (!ref.read(settingsProvider).telegramNotificationsEnabled) {
        return;
      }
      final uri = buildTelegramDeepLink(Config.telegramBotUsername, code);
      final opened = await openTelegramDeepLink(uri);
      if (!opened) {
        throw const TelegramLinkException(
          'Could not open Telegram',
          kind: TelegramLinkFailure.openFailed,
        );
      }
    } catch (e) {
      logger.w('Telegram link failed', error: e);
      if (mounted) {
        _showTelegramError(_telegramErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _linkingTelegram = false);
      }
    }
  }

  void _showTelegramError(String message) {
    SnackBarHelper.showTopSnackBar(
      context,
      message,
      duration: const Duration(seconds: 3),
      backgroundColor: AppTheme.colors(context).danger,
    );
  }

  /// Maps a [TelegramLinkException] failure kind to a distinct, actionable
  /// message. Everything else falls back to the generic link-failed string.
  String _telegramErrorMessage(Object error) {
    if (error is! TelegramLinkException) {
      return S.of(context)!.telegramLinkFailed;
    }
    switch (error.kind) {
      case TelegramLinkFailure.timeout:
      case TelegramLinkFailure.serverUnreachable:
        return S.of(context)!.telegramLinkTimeout;
      case TelegramLinkFailure.rateLimited:
        return S.of(context)!.telegramLinkRateLimited;
      case TelegramLinkFailure.unavailable:
        return S.of(context)!.telegramLinkUnavailable;
      case TelegramLinkFailure.notConfigured:
        return S.of(context)!.telegramBotNotConfigured;
      case TelegramLinkFailure.openFailed:
      case TelegramLinkFailure.badReply:
      case TelegramLinkFailure.inProgress:
      case TelegramLinkFailure.unexpected:
        return S.of(context)!.telegramLinkFailed;
    }
  }

  Widget _buildTradeHistoryCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.history,
                  color: AppTheme.colors(context).accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context)!.tradeHistory,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context)!.tradeHistoryDescription,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const TradeHistorySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDevToolsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.bug,
                  color: AppTheme.colors(context).accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context)!.devTools,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context)!.devToolsWarning,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/logs'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.colors(context).inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.fileText,
                        color: AppTheme.colors(context).accent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context)!.logsReport,
                              style: TextStyle(
                                color: AppTheme.colors(context).textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              S.of(context)!.viewAndExportLogs,
                              style: TextStyle(
                                color: AppTheme.colors(context).textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppTheme.colors(context).textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.globe,
                  color: AppTheme.colors(context).accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context)!.language,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showInfoDialog(
                    context,
                    S.of(context)!.language,
                    S.of(context)!.languageInfoText,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context)!.chooseLanguageDescription,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const LanguageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.coins,
                  color: AppTheme.colors(context).accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context)!.currency,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showInfoDialog(
                    context,
                    S.of(context)!.currency,
                    S.of(context)!.currencyInfoText,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context)!.setDefaultFiatCurrency,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildCurrencySelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLightningAddressCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.zap,
                  color: AppTheme.colors(context).accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context)!.defaultLightningAddress,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showInfoDialog(
                    context,
                    S.of(context)!.defaultLightningAddress,
                    S.of(context)!.lightningAddressInfoText,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context)!.setDefaultLightningAddress,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
              ),
              child: TextFormField(
                controller: _lightningAddressController,
                style: TextStyle(color: AppTheme.colors(context).textPrimary),
                onChanged: (value) {
                  final cleanValue = value.trim().isEmpty ? null : value.trim();
                  ref
                      .read(settingsProvider.notifier)
                      .updateDefaultLightningAddress(cleanValue);

                  // Force sync immediately for empty values
                  if (cleanValue == null) {
                    _lightningAddressController.text = '';
                  }
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: S.of(context)!.lightningAddressOptional,
                  labelStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
                  hintText: S.of(context)!.enterLightningAddress,
                  hintStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelaysCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.radio,
                  color: AppTheme.colors(context).accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context)!.relays,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showInfoDialog(
                    context,
                    S.of(context)!.relays,
                    S.of(context)!.relaysInfoText,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            RelaySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildMostroCard(BuildContext context) {
    ref.watch(mostroNodesProvider);
    ref.watch(settingsProvider);
    final notifier = ref.read(mostroNodesProvider.notifier);
    final selectedNode = notifier.selectedNode;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.server,
                  color: AppTheme.colors(context).accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context)!.serverNode,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showInfoDialog(
                    context,
                    S.of(context)!.serverNode,
                    S.of(context)!.mostroInfoText,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context)!.serverNodeDescription,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => MostroNodeSelector.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.colors(context).inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selectedNode != null) ...[
                        MostroNodeAvatar(node: selectedNode),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      selectedNode.displayName,
                                      style: TextStyle(
                                        color: AppTheme.colors(context).textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (selectedNode.isTrusted) ...[
                                    const SizedBox(width: 8),
                                    const TrustedBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedNode.pubkey,
                                style: TextStyle(
                                  color: AppTheme.colors(context).textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ).withAutomationId(
                                  AutomationIds.settingsMostroNodePubkey),
                              const SizedBox(height: 2),
                              Text(
                                S.of(context)!.tapToSelectNode,
                                style: TextStyle(
                                  color: AppTheme.colors(context).textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Expanded(
                          child: Text(
                            S.of(context)!.selectMostroNode,
                            style: TextStyle(
                              color: AppTheme.colors(context).textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ],
                  ),
                ),
              ).withAutomationId(AutomationIds.settingsMostroNode,
                  merge: false),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _switchingServerNode ? null : _addServerNode,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.colors(context).inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.colors(context).accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        color: AppTheme.colors(context).accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context)!.addYourServer,
                        style: TextStyle(
                          color: AppTheme.colors(context).accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).withAutomationId(AutomationIds.settingsMostroNodeAdd,
                  merge: false),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.colors(context).divider),
              ),
              child: Text(
                S.of(context)!.communityDisclaimerBody,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.colors(context).textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the "add server" dialog directly, then connects the newly added
  /// node so the user's own daemon is actually used (not just listed).
  Future<void> _addServerNode() async {
    final pubkeysBefore =
        ref.read(mostroNodesProvider).map((n) => n.pubkey).toSet();
    await AddCustomNodeDialog.show(context, ref);
    if (!mounted) return;

    final pubkeysAfter =
        ref.read(mostroNodesProvider).map((n) => n.pubkey).toSet();
    final newPubkeys = pubkeysAfter.difference(pubkeysBefore);
    if (newPubkeys.isEmpty) return;

    await _selectServerNode(newPubkeys.first);
  }

  /// Selects [pubkey] as the active Mostro node and re-runs the restore
  /// process (relay reconnection + session restore), mirroring the node
  /// selector's switch flow.
  Future<void> _selectServerNode(String pubkey) async {
    if (_switchingServerNode) return;
    setState(() => _switchingServerNode = true);

    final colors = AppTheme.colors(context);
    final notifier = ref.read(mostroNodesProvider.notifier);
    final oldPubkey = ref.read(settingsProvider).mostroPublicKey;

    try {
      await notifier.selectNode(pubkey);

      if (oldPubkey != pubkey) {
        final restoreService = ref.read(restoreServiceProvider);
        final success = await restoreService.initRestoreProcess();
        if (!mounted) return;
        if (!success) {
          SnackBarHelper.showTopSnackBar(
            context,
            S.of(context)!.errorSwitchingNode,
            backgroundColor: colors.danger,
          );
          return;
        }
      }

      if (!mounted) return;
      final nodeName = notifier.selectedNode?.displayName ?? pubkey;
      SnackBarHelper.showTopSnackBar(
        context,
        S.of(context)!.nodeSwitchedSuccess(nodeName),
        backgroundColor: colors.success,
      );
    } catch (e) {
      logger.w('Server node switch failed', error: e);
      if (mounted) {
        SnackBarHelper.showTopSnackBar(
          context,
          S.of(context)!.errorSwitchingNode,
          backgroundColor: colors.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _switchingServerNode = false);
      }
    }
  }

  Widget _buildCurrencySelector(BuildContext context) {
    final currenciesAsync = ref.watch(currencyCodesProvider);
    final settings = ref.watch(settingsProvider);
    final selectedFiatCode = settings.defaultFiatCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: currenciesAsync.when(
        loading: () => const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => Row(
          children: [
            Text(S.of(context)!.errorLoadingCurrencies),
            TextButton(
              onPressed: () => ref.refresh(currencyCodesProvider),
              child: Text(S.of(context)!.retry),
            ),
          ],
        ),
        data: (currencies) {
          String displayText;
          if (selectedFiatCode != null) {
            final selectedCurrency = currencies[selectedFiatCode];
            displayText = selectedCurrency != null
                ? '${selectedCurrency.emoji.isNotEmpty ? selectedCurrency.emoji : '🏳️'} $selectedFiatCode - ${selectedCurrency.name}'
                : selectedFiatCode;
          } else {
            displayText = S.of(context)!.noCurrencySelected;
          }

          return InkWell(
            onTap: () async {
              final selectedCode = await CurrencySelectionDialog.show(
                context,
                ref,
                title: S.of(context)!.defaultFiatCurrency,
                currentSelection: selectedFiatCode,
              );
              if (selectedCode != null && context.mounted) {
                ref
                    .read(settingsProvider.notifier)
                    .updateDefaultFiatCode(selectedCode);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context)!.defaultFiatCurrency,
                          style: TextStyle(
                            color: AppTheme.colors(context).textInactive,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayText,
                          style: TextStyle(
                            color: AppTheme.colors(context).textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.colors(context).textInactive,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.colors(context).cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: AppTheme.colors(context).textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            content,
            style: TextStyle(
              color: AppTheme.colors(context).textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                S.of(context)!.ok,
                style: TextStyle(
                  color: AppTheme.colors(context).accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
