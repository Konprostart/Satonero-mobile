import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/generated/l10n.dart';

/// Settings card for the Cashu mint wallet — a deliberately separate entity
/// from the Lightning (NWC) wallet card shown above it.
///
/// This is a lightweight navigation entry only: the live escrow backend, mint
/// list and native library status live on `CashuWalletScreen`. Keeping the card
/// static means the settings list never pulls in the Nostr/order repository
/// dependency chain, and the Lightning wallet card/logic stays untouched.
class CashuWalletCard extends StatelessWidget {
  const CashuWalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

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
                Icon(
                  LucideIcons.coins,
                  color: AppTheme.colors(context).lightningYellow,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context)!.cashuMintWallet,
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
              S.of(context)!.cashuWalletDescription,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/cashu_wallet'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.coins,
                        color: AppTheme.colors(context).lightningYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          S.of(context)!.cashuMintWallet,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colors.textSecondary,
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
}
