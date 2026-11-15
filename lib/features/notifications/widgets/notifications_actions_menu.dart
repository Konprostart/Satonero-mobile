import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/notifications/providers/notifications_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/utils/snack_bar_helper.dart';

class NotificationsActionsMenu extends ConsumerWidget {
  const NotificationsActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: HeroIcon(
        HeroIcons.ellipsisVertical,
        style: HeroIconStyle.outline,
        color: AppTheme.colors(context).textPrimary,
        size: 24,
      ),
      color: AppTheme.colors(context).scaffoldBackground,
      onSelected: (value) => _handleMenuAction(context, ref, value),
      itemBuilder: (context) => [
        _buildMarkAllAsReadMenuItem(context),
        _buildClearAllMenuItem(context),
      ],
    );
  }

  PopupMenuItem<String> _buildMarkAllAsReadMenuItem(BuildContext context) {
    return PopupMenuItem(
      value: 'mark_all_read',
      child: Row(
        children: [
          HeroIcon(
            HeroIcons.checkCircle,
            style: HeroIconStyle.outline,
            size: 20,
            color: AppTheme.colors(context).accent,
          ),
          const SizedBox(width: 12),
          Text(
            S.of(context)!.markAllAsRead,
            style: TextStyle(color: AppTheme.colors(context).textPrimary),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildClearAllMenuItem(BuildContext context) {
    return PopupMenuItem(
      value: 'clear_all',
      child: Row(
        children: [
          HeroIcon(
            HeroIcons.trash,
            style: HeroIconStyle.outline,
            size: 20,
            color: AppTheme.colors(context).danger,
          ),
          const SizedBox(width: 12),
          Text(
            S.of(context)!.clearAll,
            style: TextStyle(color: AppTheme.colors(context).textPrimary),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    final repository = ref.read(notificationsDatabaseProvider);
    
    switch (action) {
      case 'mark_all_read':
        repository.markAllAsRead();
        SnackBarHelper.showTopSnackBar(
          context,
          S.of(context)!.markAllAsRead,
          backgroundColor: AppTheme.colors(context).accent,
        );
        break;
      case 'clear_all':
        _showClearAllConfirmationDialog(context, ref);
        break;
    }
  }

  void _showClearAllConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors(context).scaffoldBackground,
        title: Text(
          S.of(context)!.clearAll,
          style: TextStyle(color: AppTheme.colors(context).textPrimary),
        ),
        content: Text(
          S.of(context)!.confirmClearAll,
          style: TextStyle(color: AppTheme.colors(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context)!.cancel,
              style: TextStyle(color: AppTheme.colors(context).textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationsDatabaseProvider).clearAll();
              Navigator.of(context).pop();
              SnackBarHelper.showTopSnackBar(
                context,
                S.of(context)!.clearAll,
                backgroundColor: AppTheme.colors(context).danger,
              );
            },
            child: Text(
              S.of(context)!.clearAll,
              style: TextStyle(color: AppTheme.colors(context).danger),
            ),
          ),
        ],
      ),
    );
  }
}