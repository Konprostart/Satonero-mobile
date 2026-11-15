import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/config.dart';
import 'package:satonero_mobile/features/settings/settings_provider.dart';
import 'package:satonero_mobile/shared/widgets/mostro_switch.dart';
import 'package:satonero_mobile/generated/l10n.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  bool get _isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool get _isPushSupported => _isPlatformSupported && Config.pushConfigured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(HeroIcons.arrowLeft, color: AppTheme.colors(context).textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          S.of(context)!.notifications,
          style: TextStyle(
            color: AppTheme.colors(context).textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: AppTheme.colors(context).scaffoldBackground,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPushNotificationsCard(context, ref, settings),
            const SizedBox(height: 16),
            _buildNotificationPreferencesCard(context, ref, settings),
            const SizedBox(height: 16),
            _buildPrivacyInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPushNotificationsCard(
    BuildContext context,
    WidgetRef ref,
    settings,
  ) {
    final isEnabled = settings.pushNotificationsEnabled;

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
                Expanded(
                  child: Text(
                    S.of(context)!.pushNotifications,
                    style: TextStyle(
                      color: AppTheme.colors(context).textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                MostroSwitch(
                  value: isEnabled,
                  onChanged: _isPushSupported
                      ? (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .updatePushNotificationsEnabled(value);
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context)!.pushNotificationsDescription,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
            ),
            if (!_isPushSupported) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                     Icon(
                      LucideIcons.alertTriangle,
                      color: AppTheme.colors(context).accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isPlatformSupported
                            ? S.of(context)!.pushNotificationsNotConfigured
                            : S.of(context)!.pushNotificationsNotSupported,
                        style:  TextStyle(
                          color: AppTheme.colors(context).accent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferencesCard(
    BuildContext context,
    WidgetRef ref,
    settings,
  ) {
    final pushEnabled = settings.pushNotificationsEnabled;
    final soundEnabled = settings.notificationSoundEnabled;
    final vibrationEnabled = settings.notificationVibrationEnabled;

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
                  LucideIcons.settings,
                  color: AppTheme.colors(context).accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context)!.notificationPreferences,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPreferenceToggle(
              context: context,
              icon: LucideIcons.volume2,
              title: S.of(context)!.notificationSound,
              subtitle: S.of(context)!.notificationSoundDescription,
              value: soundEnabled,
              enabled: pushEnabled && _isPushSupported,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .updateNotificationSoundEnabled(value);
              },
            ),
            const SizedBox(height: 16),
            _buildPreferenceToggle(
              context: context,
              icon: LucideIcons.vibrate,
              title: S.of(context)!.notificationVibration,
              subtitle: S.of(context)!.notificationVibrationDescription,
              value: vibrationEnabled,
              enabled: pushEnabled && _isPushSupported,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .updateNotificationVibrationEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.colors(context).inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.colors(context).accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.colors(context).textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.colors(context).textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            MostroSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyInfoCard(BuildContext context) {
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
                  LucideIcons.shield,
                  color: AppTheme.colors(context).accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context)!.privacyInfo,
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context)!.pushNotificationsPrivacyInfo,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildPrivacyBullet(
              context,
              LucideIcons.check,
              S.of(context)!.privacyBulletSilentPush,
              AppTheme.colors(context).success,
            ),
            const SizedBox(height: 8),
            _buildPrivacyBullet(
              context,
              LucideIcons.check,
              S.of(context)!.privacyBulletEncryptedTokens,
              AppTheme.colors(context).success,
            ),
            const SizedBox(height: 8),
            _buildPrivacyBullet(
              context,
              LucideIcons.check,
              S.of(context)!.privacyBulletLocalDecryption,
              AppTheme.colors(context).success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyBullet(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.colors(context).textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
