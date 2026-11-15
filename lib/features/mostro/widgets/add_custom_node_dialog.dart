import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/automation/automation_id.dart';
import 'package:satonero_mobile/core/automation/automation_ids.dart';
import 'package:satonero_mobile/features/mostro/mostro_node.dart';
import 'package:satonero_mobile/features/mostro/mostro_nodes_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/shared/utils/nostr_utils.dart';
import 'package:satonero_mobile/shared/utils/snack_bar_helper.dart';

class AddCustomNodeDialog {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    // Capture parent context values before entering dialog
    final parentMessenger = ScaffoldMessenger.of(context);
    final parentMediaQuery = MediaQuery.of(context);
    final parentOverlay = Overlay.of(context, rootOverlay: true);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return _AddCustomNodeDialogContent(
          ref: ref,
          parentMessenger: parentMessenger,
          screenHeight: parentMediaQuery.size.height,
          overlay: parentOverlay,
          statusBarPadding: parentMediaQuery.padding.top,
        );
      },
    );
  }

  static String _convertToHex(String input) {
    if (input.startsWith('npub1')) {
      return NostrUtils.decodeBech32(input);
    }
    return input;
  }
}

class _AddCustomNodeDialogContent extends StatefulWidget {
  final WidgetRef ref;
  final ScaffoldMessengerState parentMessenger;
  final OverlayState overlay;
  final double screenHeight;
  final double statusBarPadding;

  const _AddCustomNodeDialogContent({
    required this.ref,
    required this.parentMessenger,
    required this.overlay,
    required this.screenHeight,
    required this.statusBarPadding,
  });

  @override
  State<_AddCustomNodeDialogContent> createState() =>
      _AddCustomNodeDialogContentState();
}

class _AddCustomNodeDialogContentState
    extends State<_AddCustomNodeDialogContent> {
  late final TextEditingController pubkeyController;
  late final TextEditingController nameController;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    pubkeyController = TextEditingController();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    pubkeyController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.colors(context).cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Text(
        S.of(context)!.addCustomNodeTitle,
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
            // Pubkey input
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: pubkeyController,
                style: TextStyle(color: AppTheme.colors(context).textPrimary),
                decoration: InputDecoration(
                  labelText: S.of(context)!.enterNodePubkey,
                  labelStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: S.of(context)!.pubkeyHint,
                  hintStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
                  errorText: errorMessage,
                  errorStyle: const TextStyle(color: Colors.red),
                ),
                autofocus: true,
              ).withAutomationId(AutomationIds.nodeCustomPubkey),
            ),
            const SizedBox(height: 12),
            // Name input
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: nameController,
                style: TextStyle(color: AppTheme.colors(context).textPrimary),
                decoration: InputDecoration(
                  labelText: S.of(context)!.enterNodeName,
                  labelStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: S.of(context)!.nodeNameHint,
                  hintStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
                ),
              ).withAutomationId(AutomationIds.nodeCustomName),
            ),
          ],
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
        ).withAutomationId(AutomationIds.nodeCustomCancel),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () async {
            final input = pubkeyController.text.trim();
            final name = nameController.text.trim();
            final localizations = S.of(context)!;
            final navigator = Navigator.of(context);

            if (input.isEmpty) {
              setState(() {
                errorMessage = localizations.pubkeyRequired;
              });
              return;
            }

            // Reject nsec private keys
            if (input.startsWith('nsec')) {
              setState(() {
                errorMessage = localizations.invalidPubkeyFormat;
              });
              return;
            }

            // Convert npub to hex if needed, then normalize
            String hexPubkey;
            try {
              hexPubkey =
                  AddCustomNodeDialog._convertToHex(input).toLowerCase();
            } catch (_) {
              setState(() {
                errorMessage = localizations.invalidPubkeyFormat;
              });
              return;
            }

            // Validate hex format
            if (!MostroNode.isValidHexPubkey(hexPubkey)) {
              setState(() {
                errorMessage = localizations.invalidPubkeyFormat;
              });
              return;
            }

            // Check duplicates
            final nodes = widget.ref.read(mostroNodesProvider);
            if (nodes.any((n) => n.pubkey == hexPubkey)) {
              setState(() {
                errorMessage = localizations.nodeAlreadyExists;
              });
              return;
            }

            final notifier = widget.ref.read(mostroNodesProvider.notifier);
            final added = await notifier.addCustomNode(
              hexPubkey,
              name: name.isEmpty ? null : name,
            );

            if (added) {
              // Fire-and-forget: errors are logged inside fetchNodeMetadata
              unawaited(notifier.fetchNodeMetadata(hexPubkey));

              navigator.pop();
              SnackBarHelper.showTopSnackBarAsync(
                messenger: widget.parentMessenger,
                screenHeight: widget.screenHeight,
                statusBarHeight: widget.statusBarPadding,
                overlay: widget.overlay,
                message: localizations.nodeAddedSuccess,
                backgroundColor: Colors.green,
              );
            } else {
              setState(() {
                errorMessage = localizations.nodeAlreadyExists;
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
              horizontal: 12,
              vertical: 12,
            ),
          ),
          child: Text(
            S.of(context)!.addCustomNode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ).withAutomationId(AutomationIds.nodeCustomConfirm),
      ],
    );
  }
}
