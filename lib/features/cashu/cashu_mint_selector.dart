import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';

/// Lets a maker choose the Cashu mint that will hold the order's escrow.
///
/// Rendered only when the connected node runs Cashu escrow; when the node is
/// Lightning (or its info event has not arrived yet) it collapses to an empty
/// widget so the caller can drop it inline unconditionally.
///
/// Two shapes, matching the daemon's mint policy:
/// - the node advertises an allow-list of mints → a dropdown of those mints;
/// - the node is open (no advertised mints) → a free-form URL field.
class CashuMintSelector extends ConsumerStatefulWidget {
  const CashuMintSelector({
    super.key,
    required this.selectedMintUrl,
    required this.onChanged,
  });

  /// The mint the maker has chosen so far (may be null).
  final String? selectedMintUrl;

  /// Called with the chosen mint URL, or null when the choice is cleared.
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<CashuMintSelector> createState() => _CashuMintSelectorState();
}

class _CashuMintSelectorState extends ConsumerState<CashuMintSelector> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    final info = ref.watch(nodeEscrowInfoProvider).valueOrNull;

    // Not a Cashu node (or info still loading): nothing to choose.
    if (info == null || !info.isCashu) {
      return const SizedBox.shrink();
    }

    final mints = info.mintUrls;
    final selected =
        widget.selectedMintUrl ?? (mints.length == 1 ? mints.first : null);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.coins,
                  color: AppTheme.colors(context).accent, size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context)!.cashuMint,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context)!.cashuMintDescription,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (mints.isNotEmpty)
            DropdownButtonFormField<String>(
              value: selected,
              decoration: InputDecoration(
                labelText: S.of(context)!.selectCashuMint,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final mint in mints.map(CashuMint.new))
                  DropdownMenuItem(
                    value: mint.url,
                    child: Text(mint.displayName),
                  ),
              ],
              onChanged: (value) => widget.onChanged(value),
            )
          else
            TextFormField(
              controller: _customController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: S.of(context)!.selectCashuMint,
                hintText: 'https://mint.example.com',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onChanged: (value) {
                final trimmed = value.trim();
                widget.onChanged(trimmed.isEmpty ? null : trimmed);
              },
            ),
        ],
      ),
    );
  }
}
