import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/logs/logs_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/services/logger_export_service.dart';
import 'package:satonero_mobile/services/logger_service.dart';

class LogsActionsMenu extends ConsumerWidget {

  const LogsActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);
    final hasLogs = logs.isNotEmpty;

    return PopupMenuButton<String>(
      icon: HeroIcon(
        HeroIcons.ellipsisVertical,
        style: HeroIconStyle.outline,
        color: AppTheme.colors(context).textPrimary,
        size: 24,
      ),
      color: AppTheme.colors(context).scaffoldBackground,
      onSelected: (value) => _handleMenuAction(context, ref, value, logs),
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          'save',
          HeroIcons.arrowDownTray,
          S.of(context)!.saveLogs,
          hasLogs ? AppTheme.colors(context).textPrimary : AppTheme.colors(context).textSecondary,
          enabled: hasLogs,
        ),
        _buildMenuItem(
          context,
          'share',
          HeroIcons.share,
          S.of(context)!.shareLogs,
          hasLogs ? AppTheme.colors(context).textPrimary : AppTheme.colors(context).textSecondary,
          enabled: hasLogs,
        ),
        _buildMenuItem(
          context,
          'clear',
          HeroIcons.trash,
          S.of(context)!.clearLogs,
          hasLogs ? AppTheme.colors(context).danger : AppTheme.colors(context).textSecondary,
          enabled: hasLogs,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context,
    String value,
    HeroIcons icon,
    String label,
    Color color, {
    bool enabled = true,
  }) {
    return PopupMenuItem(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          HeroIcon(
            icon,
            style: HeroIconStyle.outline,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: enabled ? AppTheme.colors(context).textPrimary : AppTheme.colors(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    List<LogEntry> logs,
  ) async {
    switch (action) {
      case 'save':
        await _saveLogsToFolder(context, ref, logs);
        break;
      case 'share':
        await _shareLogsFile(context, logs);
        break;
      case 'clear':
        await _showClearConfirmation(context, ref);
        break;
    }
  }

  Future<void> _saveLogsToFolder(
    BuildContext context,
    WidgetRef ref,
    List<LogEntry> logs,
  ) async {
    final localizations = S.of(context)!;
    final strings = LogExportStrings(
      headerTitle: localizations.logsHeaderTitle,
      generatedLabel: localizations.logsGeneratedLabel,
      totalLabel: localizations.logsTotalLabel,
      emptyMessage: localizations.noLogsAvailable,
    );

    try {
      final filePath = await LoggerExportService.exportLogsToFolder(logs, strings);

      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.logsExportSuccess),
            backgroundColor: AppTheme.colors(context).accent,
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error exporting logs', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.logsExportError),
            backgroundColor: AppTheme.colors(context).danger,
          ),
        );
      }
    }
  }

  Future<void> _shareLogsFile(BuildContext context, List<LogEntry> logs) async {
    final localizations = S.of(context)!;
    final strings = LogExportStrings(
      headerTitle: localizations.logsHeaderTitle,
      generatedLabel: localizations.logsGeneratedLabel,
      totalLabel: localizations.logsTotalLabel,
      emptyMessage: localizations.noLogsAvailable,
    );

    try {
      final file = await LoggerExportService.exportLogsForSharing(logs, strings);
      await LoggerExportService.shareLogs(
        file,
        subject: localizations.logsShareSubject,
        text: localizations.logsShareText,
      );
    } catch (e, stackTrace) {
      logger.e('Error sharing logs', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.shareLogsError),
            backgroundColor: AppTheme.colors(context).danger,
          ),
        );
      }
    }
  }

  Future<void> _showClearConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors(context).scaffoldBackground,
        title: Text(
          S.of(context)!.clearLogs,
          style: TextStyle(color: AppTheme.colors(context).textPrimary),
        ),
        content: Text(
          S.of(context)!.clearLogsConfirmation,
          style: TextStyle(color: AppTheme.colors(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              S.of(context)!.cancel,
              style: TextStyle(color: AppTheme.colors(context).textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              S.of(context)!.clear,
              style: TextStyle(color: AppTheme.colors(context).danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(logsProvider.notifier).clearLogs();
    }
  }
}
