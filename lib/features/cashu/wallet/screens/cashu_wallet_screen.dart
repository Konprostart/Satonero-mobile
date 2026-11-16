import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint_provider.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_status_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';

/// Dedicated screen for the Cashu mint wallet.
///
/// This is a deliberately separate entity from the Lightning (NWC) wallet: the
/// Lightning wallet screens (`WalletSettingsScreen`, `ConnectWalletScreen`) are
/// untouched. Here the user sees the connected node's escrow backend, the
/// mints it advertises, whether the native NUT-11 P2PK library is bundled in
/// this build, and what the client wallet will be able to do.
class CashuWalletScreen extends ConsumerWidget {
  const CashuWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colors(context);
    final info = ref.watch(nodeEscrowInfoProvider).valueOrNull;
    final nativeLibrary = ref.watch(cashuNativeWalletAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(
            HeroIcons.arrowLeft,
            color: colors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          S.of(context)!.cashuMintWallet,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: colors.scaffoldBackground,
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
            const _HeroCard(),
            const SizedBox(height: 16),
            _EscrowBackendCard(info: info),
            const SizedBox(height: 16),
            _NativeLibraryCard(nativeLibrary: nativeLibrary),
            const SizedBox(height: 16),
            const _CapabilitiesCard(),
          ],
        ),
      ),
    );
  }
}

/// Branded header distinguishing the Cashu wallet from the Lightning wallet.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.colors(context).accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.colors(context).accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.coins,
              color: AppTheme.colors(context).accent,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context)!.cashuMintWallet,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context)!.cashuWalletDescription,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The connected node's escrow backend and, for Cashu nodes, its mints.
class _EscrowBackendCard extends ConsumerWidget {
  const _EscrowBackendCard({required this.info});

  final NodeEscrowInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colors(context);

    final bool? isCashu;
    if (info == null) {
      isCashu = null;
    } else {
      isCashu = info!.isCashu;
    }

    return _SectionCard(
      icon: LucideIcons.zap,
      iconColor: isCashu == true
          ? AppTheme.colors(context).accent
          : AppTheme.colors(context).lightningBlue,
      title: S.of(context)!.cashuEscrowMode,
      trailing: _EscrowChip(isCashu: isCashu),
      child: _buildBody(context, colors, isCashu),
    );
  }

  Widget _buildBody(BuildContext context, AppColors colors, bool? isCashu) {
    if (isCashu == null) {
      return Text(
        S.of(context)!.cashuWalletBackendUnknown,
        style: TextStyle(color: colors.textSecondary, fontSize: 14),
      );
    }

    if (!isCashu) {
      return Text(
        S.of(context)!.cashuWalletLightningNotice,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      );
    }

    final mints = info!.mintUrls;
    final locktimeDays = info!.escrowLocktimeDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.cashuWalletMints,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (mints.isEmpty)
          _InfoRow(
            icon: LucideIcons.globe,
            text: S.of(context)!.cashuWalletOpenMint,
          )
        else
          ...mints.map((url) {
            final mint = CashuMint(url);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mint.displayName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mint.url,
                      style: TextStyle(
                        color: colors.textInactive,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        if (locktimeDays != null) ...[
          const SizedBox(height: 4),
          _InfoRow(
            icon: LucideIcons.lock,
            text: '${S.of(context)!.escrowLocktimeLabel}: '
                '${S.of(context)!.escrowLocktimeDays(locktimeDays)}',
          ),
        ],
        const SizedBox(height: 8),
        Text(
          S.of(context)!.cashuMintTrustNotice,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Whether the native `satonero_cashu` library is bundled in this build.
class _NativeLibraryCard extends StatelessWidget {
  const _NativeLibraryCard({required this.nativeLibrary});

  final AsyncValue<bool> nativeLibrary;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return nativeLibrary.when(
      loading: () => _SectionCard(
        icon: LucideIcons.zap,
        iconColor: AppTheme.colors(context).accent,
        title: S.of(context)!.cashuWalletNativeLibrary,
        child: Text(
          S.of(context)!.cashuWalletNativeChecking,
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
      ),
      error: (_, __) => _nativeStatusCard(context, false),
      data: (available) => _nativeStatusCard(context, available),
    );
  }

  Widget _nativeStatusCard(BuildContext context, bool available) {
    final colors = AppTheme.colors(context);

    return _SectionCard(
      icon: LucideIcons.zap,
      iconColor: available
          ? AppTheme.colors(context).success
          : AppTheme.colors(context).warning,
      title: S.of(context)!.cashuWalletNativeLibrary,
      child: _InfoRow(
        icon: available ? LucideIcons.check : LucideIcons.alertCircle,
        iconColor: available
            ? AppTheme.colors(context).success
            : AppTheme.colors(context).warning,
        text: available
            ? S.of(context)!.cashuWalletNativeAvailable
            : S.of(context)!.cashuWalletNativeUnavailable,
        textColor: colors.textSecondary,
      ),
    );
  }
}

/// Static capability overview + what is coming next.
class _CapabilitiesCard extends StatelessWidget {
  const _CapabilitiesCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return _SectionCard(
      icon: LucideIcons.shield,
      iconColor: AppTheme.colors(context).lightningBlue,
      title: S.of(context)!.cashuWalletCapabilities,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context)!.cashuWalletP2pkTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context)!.cashuWalletP2pkDescription,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.info.withValues(alpha: 0.3)),
            ),
            child: Text(
              S.of(context)!.cashuWalletComingSoon,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card scaffold for the wallet screen sections.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Small icon + text row used for status lines.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? colors.textInactive, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded pill labelling the escrow backend (Cashu / Lightning / unknown).
class _EscrowChip extends StatelessWidget {
  const _EscrowChip({required this.isCashu});

  final bool? isCashu;

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context)!;

    final String label;
    final Color foreground;
    if (isCashu == null) {
      label = l10n.cashuWalletBackendUnknown;
      foreground = AppTheme.colors(context).textInactive;
    } else if (isCashu!) {
      label = l10n.escrowCashu;
      foreground = AppTheme.colors(context).accent;
    } else {
      label = l10n.escrowLightning;
      foreground = AppTheme.colors(context).lightningBlue;
    }

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
