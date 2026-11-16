import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint_provider.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_api.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_controller.dart';
import 'package:satonero_mobile/generated/l10n.dart';

/// Sentinel value for "no mint selected" in the mint dropdown.
const _noneSentinel = '__none__';

/// Sentinel value for the "Custom mint URL" entry in the mint dropdown.
const _customSentinel = '__custom__';

/// Dedicated screen for the Cashu mint wallet.
///
/// This is a deliberately separate entity from the Lightning (NWC) wallet: the
/// Lightning wallet screens (`WalletSettingsScreen`, `ConnectWalletScreen`) are
/// untouched. Here the user can actually use ecash — Receive (NUT-04 mint),
/// Send (NUT-05 melt), redeem a NUT-00 token, and Sync with mint (NUT-07 + 06).
class CashuWalletScreen extends ConsumerStatefulWidget {
  const CashuWalletScreen({super.key});

  @override
  ConsumerState<CashuWalletScreen> createState() => _CashuWalletScreenState();
}

class _CashuWalletScreenState extends ConsumerState<CashuWalletScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    final wallet = ref.watch(cashuWalletProvider);
    final info = ref.watch(nodeEscrowInfoProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(HeroIcons.arrowLeft, color: colors.textPrimary),
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
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorBody(context, e.toString()),
        data: (snapshot) => ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          children: [
            const _HeroCard(),
            const SizedBox(height: 16),
            _WalletBalanceCard(snapshot: snapshot, onSync: _sync),
            const SizedBox(height: 16),
            _MintSelectorCard(
              snapshot: snapshot,
              onSelect: _selectMint,
              onCustom: _showCustomMintDialog,
            ),
            const SizedBox(height: 16),
            _ActionsCard(
              snapshot: snapshot,
              onReceive: _showReceiveDialog,
              onSend: _showSendDialog,
              onRedeem: _showRedeemDialog,
            ),
            const SizedBox(height: 16),
            _EscrowBackendCard(info: info),
          ],
        ),
      ),
    );
  }

  Widget _errorBody(BuildContext context, String message) {
    final colors = AppTheme.colors(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // --- Wallet operations ----------------------------------------------------

  Future<void> _sync() async {
    final controller = ref.read(cashuWalletProvider.notifier);
    final l10n = S.of(context)!;
    try {
      final freed = await controller.sync();
      final balance = ref.read(cashuWalletProvider).valueOrNull?.balance;
      _showSnack(
        freed > BigInt.zero
            ? l10n.cashuWalletFreed(freed.toString())
            : l10n.cashuWalletSyncDone(
                balance?.toString() ?? '0',
              ),
      );
    } on CashuWalletException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _selectMint(String? value) {
    if (value == null || value.isEmpty || value == _noneSentinel) {
      return;
    }
    if (value == _customSentinel) {
      _showCustomMintDialog();
      return;
    }
    ref.read(cashuWalletProvider.notifier).selectMint(value);
  }

  Future<void> _showCustomMintDialog() async {
    final controller = TextEditingController();
    final l10n = S.of(context)!;
    final colors = AppTheme.colors(context);

    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text(
          l10n.cashuWalletCustomMint,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.cashuWalletCustomMint,
            hintText: 'https://mint.example.com',
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.cashuWalletConnect),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      await ref.read(cashuWalletProvider.notifier).selectMint(url);
      if (mounted) {
        final snapshot = ref.read(cashuWalletProvider).valueOrNull;
        if (snapshot?.hasMint == true && snapshot?.mintName == null) {
          // Mint info fetch failed silently; surface a neutral notice.
          _showSnack(l10n.cashuWalletConnect);
        }
      }
    }
  }

  Future<void> _showReceiveDialog() async {
    final l10n = S.of(context)!;
    final colors = AppTheme.colors(context);
    final amountController = TextEditingController();

    final amountText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text(
          l10n.cashuWalletReceiveTitle,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: TextField(
          controller: amountController,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.cashuWalletAmountLabel,
            hintText: '1000',
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(amountController.text.trim()),
            child: Text(l10n.cashuWalletCreateInvoice),
          ),
        ],
      ),
    );

    if (amountText == null || amountText.isEmpty) return;
    final amount = BigInt.tryParse(amountText);
    if (amount == null || amount <= BigInt.zero) {
      _showError(l10n.cashuWalletAmountLabel);
      return;
    }

    try {
      final quote =
          await ref.read(cashuWalletProvider.notifier).receive(amount);
      if (!mounted) return;
      await _showInvoiceDialog(quote);
    } on CashuWalletException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _showInvoiceDialog(CashuReceiveQuote quote) async {
    final l10n = S.of(context)!;
    final colors = AppTheme.colors(context);

    final minted = await showDialog<BigInt>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text(
          l10n.cashuWalletInvoiceTitle,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(
                  data: quote.invoice,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.cashuWalletInvoiceHint,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                quote.invoice,
                style: TextStyle(
                  color: colors.textInactive,
                  fontSize: 12,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: quote.invoice));
              if (mounted) _showSnack(l10n.copiedToClipboard);
            },
            child: Text(l10n.copy),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final minted = await ref
                    .read(cashuWalletProvider.notifier)
                    .mint(quote.quoteId);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(minted);
                }
              } on CashuWalletException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: Text(l10n.cashuWalletMintTokens),
          ),
        ],
      ),
    );

    if (minted != null && mounted) {
      _showSnack(l10n.cashuWalletMinted(minted.toString()));
    }
  }

  Future<void> _showSendDialog() async {
    final l10n = S.of(context)!;
    final colors = AppTheme.colors(context);
    final invoiceController = TextEditingController();

    final bolt11 = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text(
          l10n.cashuWalletSendTitle,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: TextField(
          controller: invoiceController,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.cashuWalletInvoiceFieldLabel,
            hintText: l10n.cashuWalletInvoiceFieldHint,
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(invoiceController.text.trim()),
            child: Text(l10n.cashuWalletSendAction),
          ),
        ],
      ),
    );

    if (bolt11 == null || bolt11.isEmpty) return;

    try {
      final result = await ref.read(cashuWalletProvider.notifier).send(bolt11);
      if (mounted) {
        _showSnack(l10n.cashuWalletSent(result.amountSats.toString()));
      }
    } on CashuWalletException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _showRedeemDialog() async {
    final l10n = S.of(context)!;
    final colors = AppTheme.colors(context);
    final tokenController = TextEditingController();

    final token = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text(
          l10n.cashuWalletRedeemTitle,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: TextField(
          controller: tokenController,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.cashuWalletTokenLabel,
            hintText: l10n.cashuWalletTokenHint,
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(tokenController.text.trim()),
            child: Text(l10n.cashuWalletRedeemAction),
          ),
        ],
      ),
    );

    if (token == null || token.isEmpty) return;

    try {
      final received =
          await ref.read(cashuWalletProvider.notifier).redeemToken(token);
      if (mounted) _showSnack(l10n.cashuWalletReceived(received.toString()));
    } on CashuWalletException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
            content: Text('${S.of(context)!.cashuWalletErrorTitle}: $message')),
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

/// Spendable balance + mint identity + Sync with mint.
class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.snapshot, required this.onSync});

  final CashuWalletSnapshot snapshot;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return _SectionCard(
      icon: LucideIcons.wallet,
      iconColor: colors.accent,
      title: S.of(context)!.cashuWalletBalance,
      trailing: IconButton(
        icon: snapshot.syncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(LucideIcons.refreshCw, size: 18, color: colors.textPrimary),
        tooltip: S.of(context)!.cashuWalletSync,
        onPressed: snapshot.canOperate && !snapshot.syncing ? onSync : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatSats(snapshot.balance),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'sats',
            style: TextStyle(
              color: colors.textInactive,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (snapshot.mintName != null || snapshot.mintVersion != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (snapshot.mintName != null) snapshot.mintName!,
                if (snapshot.mintVersion != null) 'v${snapshot.mintVersion}',
              ].join(' · '),
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mint selection: node-advertised mints + a custom URL entry.
class _MintSelectorCard extends StatelessWidget {
  const _MintSelectorCard({
    required this.snapshot,
    required this.onSelect,
    required this.onCustom,
  });

  final CashuWalletSnapshot snapshot;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    final l10n = S.of(context)!;

    final options = <String>[...snapshot.mintOptions];
    final current = snapshot.mintUrl;
    if (current != null && !options.contains(current)) {
      options.add(current);
    }

    final items = <String>[_noneSentinel, ...options, _customSentinel];

    return _SectionCard(
      icon: LucideIcons.globe,
      iconColor: colors.lightningBlue,
      title: l10n.selectCashuMint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(current ?? _noneSentinel),
            value: current ?? _noneSentinel,
            isExpanded: true,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            dropdownColor: colors.cardBackground,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.divider),
              ),
            ),
            items: items.map((value) {
              if (value == _noneSentinel) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    l10n.selectCashuMint,
                    style: TextStyle(color: colors.textInactive),
                  ),
                );
              }
              if (value == _customSentinel) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(l10n.cashuWalletCustomMint),
                );
              }
              return DropdownMenuItem(
                value: value,
                child: Text(CashuMint(value).displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value == _customSentinel) {
                onCustom();
              } else {
                onSelect(value);
              }
            },
          ),
          if (!snapshot.nativeAvailable) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: LucideIcons.alertCircle,
              iconColor: colors.warning,
              text: S.of(context)!.cashuWalletNativeUnavailableNotice,
              textColor: colors.textSecondary,
            ),
          ] else if (!snapshot.hasMint) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: LucideIcons.info,
              iconColor: colors.info,
              text: S.of(context)!.cashuWalletNoMintSelected,
              textColor: colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// Receive / Send / Redeem actions.
class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.snapshot,
    required this.onReceive,
    required this.onSend,
    required this.onRedeem,
  });

  final CashuWalletSnapshot snapshot;
  final VoidCallback onReceive;
  final VoidCallback onSend;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    final enabled = snapshot.canOperate && !snapshot.syncing;

    return _SectionCard(
      icon: LucideIcons.zap,
      iconColor: colors.accent,
      title: S.of(context)!.cashuWalletCapabilities,
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.arrowDownCircle,
              label: S.of(context)!.cashuWalletReceive,
              color: colors.accent,
              enabled: enabled,
              onTap: onReceive,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.arrowUpCircle,
              label: S.of(context)!.cashuWalletSend,
              color: colors.lightningBlue,
              enabled: enabled,
              onTap: onSend,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.ticket,
              label: S.of(context)!.cashuWalletRedeem,
              color: colors.info,
              enabled: enabled,
              onTap: onRedeem,
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the three wallet action buttons.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color:
              enabled ? color.withValues(alpha: 0.12) : colors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.35) : colors.divider,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: enabled ? color : colors.textInactive, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? colors.textPrimary : colors.textInactive,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

/// Format a satoshi amount with thousands separators.
String _formatSats(BigInt sats) {
  final digits = sats.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
