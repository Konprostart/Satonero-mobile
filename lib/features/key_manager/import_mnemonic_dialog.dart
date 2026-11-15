import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/automation/automation_id.dart';
import 'package:satonero_mobile/core/automation/automation_ids.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/utils/mnemonic_validator.dart';

class ImportMnemonicDialog extends StatefulWidget {
  const ImportMnemonicDialog({super.key});

  @override
  State<ImportMnemonicDialog> createState() => _ImportMnemonicDialogState();
}

class _ImportMnemonicDialogState extends State<ImportMnemonicDialog> {
  final TextEditingController _mnemonicController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  bool _validateMnemonic(String mnemonic) {
    final trimmed = mnemonic.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorMessage = null;
      });
      return false;
    }

    // Use BIP39 checksum validation
    final isValid = validateMnemonic(trimmed);

    setState(() {
      _errorMessage = isValid ? null : S.of(context)!.invalidMnemonic;
    });

    return isValid;
  }

  void _handleImport() {
    final mnemonic = _mnemonicController.text.trim();

    if (_validateMnemonic(mnemonic)) {
      if (mounted) {
        Navigator.of(context).pop(mnemonic);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.colors(context).cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context)!.importMostroUserDialogTitle,
                style: TextStyle(
                  color: AppTheme.colors(context).textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoPoint(S.of(context)!.importMostroUserInfo1),
              const SizedBox(height: 12),
              _buildInfoPoint(S.of(context)!.importMostroUserInfo2),
              const SizedBox(height: 12),
              _buildInfoPoint(S.of(context)!.importMostroUserInfo3),
              const SizedBox(height: 24),
              Text(
                S.of(context)!.secretWordsLabel,
                style: TextStyle(
                  color: AppTheme.colors(context).textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mnemonicController,
                minLines: 4,
                maxLines: 6,
                style: TextStyle(
                  color: AppTheme.colors(context).textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: S.of(context)!.secretWordsPlaceholder,
                  hintStyle: TextStyle(
                    color: AppTheme.colors(context).textSecondary.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppTheme.colors(context).inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppTheme.colors(context).accent,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:  BorderSide(
                      color: AppTheme.colors(context).danger,
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:  BorderSide(
                      color: AppTheme.colors(context).danger,
                      width: 2,
                    ),
                  ),
                  errorText: _errorMessage,
                  errorStyle:  TextStyle(
                    color: AppTheme.colors(context).danger,
                    fontSize: 12,
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ).withAutomationId(AutomationIds.keysImportMnemonic),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                  ).withAutomationId(AutomationIds.keysImportCancel),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colors(context).accent,
                      foregroundColor: AppTheme.colors(context).onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      S.of(context)!.importMostroUser,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).withAutomationId(AutomationIds.keysImportConfirm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            '• ',
            style: TextStyle(
              color: AppTheme.colors(context).textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.colors(context).textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
