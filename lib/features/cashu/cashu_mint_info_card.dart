import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';

/// Read-only escrow summary shown on the take-order screen.
///
/// It tells the taker which escrow backend the order settles through, and —
/// for a Cashu order — exactly which mint is being trusted to hold the funds
/// before the trade settles. No wallet or cryptography runs here: the mint URL
/// is published by the maker's order event (`cashu_mint_url` tag) and the
/// backend / locktime come from the connected node's kind-38385 info event.
class CashuMintInfoCard extends ConsumerWidget {
  const CashuMintInfoCard({
    super.key,
    required this.mintUrl,
  });

  /// The mint named by the order event, or null for a Lightning order.
  final String? mintUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colors(context);
    final info = ref.watch(nodeEscrowInfoProvider).valueOrNull;

    // A Cashu order always carries a mint; a node advertising Cashu escrow
    // also marks the backend. Prefer the node's advertised mode, but a mint on
    // the order is itself proof of Cashu escrow even before the info event
    // arrives.
    final isCashu = mintUrl != null || (info != null && info.isCashu);

    final escrowModeLabel =
        isCashu ? S.of(context)!.escrowCashu : S.of(context)!.escrowLightning;

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
              Icon(
                isCashu ? LucideIcons.coins : LucideIcons.zap,
                color: isCashu
                    ? AppTheme.colors(context).accent
                    : AppTheme.colors(context).lightningBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context)!.cashuEscrowMode,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _EscrowModeChip(label: escrowModeLabel, isCashu: isCashu),
            ],
          ),
          if (isCashu) ...[
            const SizedBox(height: 12),
            Text(
              S.of(context)!.cashuMint,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mintUrl == null || mintUrl!.isEmpty
                  ? CashuMint(S.of(context)!.notAvailable).displayName
                  : CashuMint(mintUrl!).displayName,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (mintUrl != null && mintUrl!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                mintUrl!,
                style: TextStyle(
                  color: colors.textInactive,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              S.of(context)!.cashuMintTrustNotice,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (info != null && info.escrowLocktimeDays != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.lock,
                    color: colors.textInactive,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${S.of(context)!.escrowLocktimeLabel}: '
                    '${S.of(context)!.escrowLocktimeDays(info.escrowLocktimeDays!)}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Text(
              S.of(context)!.lightningNetwork,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small rounded pill labelling the active escrow backend.
class _EscrowModeChip extends StatelessWidget {
  const _EscrowModeChip({required this.label, required this.isCashu});

  final String label;
  final bool isCashu;

  @override
  Widget build(BuildContext context) {
    final foreground = isCashu
        ? AppTheme.colors(context).accent
        : AppTheme.colors(context).lightningBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
