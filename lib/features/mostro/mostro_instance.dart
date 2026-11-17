import 'package:dart_nostr/nostr/model/event/event.dart';

/// Anti-abuse bond policy advertised by a Mostro daemon via the kind-38385
/// info event.
///
/// Three states must be distinguished:
/// - [unsupported]: the daemon does not emit the `bond_enabled` tag at all
///   (legacy daemon that predates the anti-abuse bond feature).
/// - [disabled]: the daemon emits `bond_enabled="false"`; the operator has
///   not enabled the feature.
/// - [enabled]: the daemon emits `bond_enabled="true"`; the bond is active
///   and the remaining six bond tags are present.
enum BondPolicy { unsupported, disabled, enabled }

/// Which side of a trade a bond applies to.
enum BondApplyTo { take, make, both }

/// The escrow backend a node runs, advertised via the kind-38385 `escrow_mode`
/// tag. A node runs exactly one: Lightning (LND hold invoices) or Cashu
/// (NUT-11 P2PK escrow on the mint each order names). A missing tag means a
/// legacy daemon that predates Cashu escrow, treated as Lightning.
enum EscrowMode { lightning, cashu }

class MostroInstance {
  final String pubKey;
  final String mostroVersion;
  final String commitHash;
  final int maxOrderAmount;
  final int minOrderAmount;
  final int expirationHours;
  final int expirationSeconds;
  final double fee;
  final int pow;
  final int holdInvoiceExpirationWindow;
  final int holdInvoiceCltvDelta;
  final int invoiceExpirationWindow;
  final String lndVersion;
  final String lndNodePublicKey;
  final String lndCommitHash;
  final String lndNodeAlias;
  final String supportedChains;
  final String supportedNetworks;
  final String lndNodeUri;
  final String fiatCurrenciesAccepted;
  final int maxOrdersPerResponse;

  /// Wire transport advertised via the `protocol_version` tag (§2 of the
  /// transport v2 migration), or `null` when the node does not advertise it.
  ///
  /// Kept nullable so "not advertised" stays distinguishable from an explicit
  /// version: that is the distinction [resolveTransport] negotiates on, and
  /// collapsing it to `1` here would also make the About screen report v1 for
  /// a node the app is actually speaking v2 to.
  final int? protocolVersion;

  /// Stiffer NIP-13 PoW a *first-contact* sender must clear, advertised via
  /// the `pow_first_contact` tag. `null` when the node does not advertise it
  /// (legacy daemon, or no first-contact toll). When advertised it is always
  /// `>= pow`; a sender that cannot know whether the node already recognises
  /// its trade key should mine at this value.
  final int? powFirstContact;

  /// Bond policy state. See [BondPolicy] for the three-state semantics.
  final BondPolicy bondPolicy;

  /// The following six fields carry the bond parameters and are only
  /// meaningful when [bondPolicy] is [BondPolicy.enabled]. They are null
  /// otherwise.
  final BondApplyTo? bondApplyTo;
  final bool? bondSlashOnWaitingTimeout;
  final double? bondAmountPct;
  final int? bondBaseAmountSats;
  final double? bondSlashNodeSharePct;
  final int? bondPayoutClaimWindowDays;

  /// Escrow backend advertised by the node. See [EscrowMode].
  final EscrowMode escrowMode;

  /// The Cashu mints a maker may choose for an order's escrow. Empty when the
  /// node is open (`mint_urls = []`) and accepts any mint, or when the node is
  /// in Lightning mode.
  final List<String> cashuMintUrls;

  /// Seller-recovery locktime floor (days) a Cashu escrow token must carry.
  /// Null when the node is in Lightning mode.
  final int? cashuEscrowLocktimeDays;

  MostroInstance(
    this.pubKey,
    this.mostroVersion,
    this.commitHash,
    this.maxOrderAmount,
    this.minOrderAmount,
    this.expirationHours,
    this.expirationSeconds,
    this.fee,
    this.pow,
    this.holdInvoiceExpirationWindow,
    this.holdInvoiceCltvDelta,
    this.invoiceExpirationWindow,
    this.lndVersion,
    this.lndNodePublicKey,
    this.lndCommitHash,
    this.lndNodeAlias,
    this.supportedChains,
    this.supportedNetworks,
    this.lndNodeUri,
    this.fiatCurrenciesAccepted,
    this.maxOrdersPerResponse, {
    this.protocolVersion,
    this.powFirstContact,
    this.bondPolicy = BondPolicy.unsupported,
    this.bondApplyTo,
    this.bondSlashOnWaitingTimeout,
    this.bondAmountPct,
    this.bondBaseAmountSats,
    this.bondSlashNodeSharePct,
    this.bondPayoutClaimWindowDays,
    this.escrowMode = EscrowMode.lightning,
    this.cashuMintUrls = const [],
    this.cashuEscrowLocktimeDays,
  });

  factory MostroInstance.fromEvent(NostrEvent event) {
    return MostroInstance(
      event.pubKey,
      event.mostroVersion,
      event.commitHash,
      event.maxOrderAmount,
      event.minOrderAmount,
      event.expirationHours,
      event.expirationSeconds,
      event.fee,
      event.pow,
      event.holdInvoiceExpirationWindow,
      event.holdInvoiceCltvDelta,
      event.invoiceExpirationWindow,
      event.lndVersion,
      event.lndNodePublicKey,
      event.lndCommitHash,
      event.lndNodeAlias,
      event.supportedChains,
      event.supportedNetworks,
      event.lndNodeUri,
      event.fiatCurrenciesAccepted,
      event.maxOrdersPerResponse,
      protocolVersion: event.protocolVersion,
      powFirstContact: event.powFirstContact,
      bondPolicy: event.bondPolicy,
      bondApplyTo: event.bondApplyTo,
      bondSlashOnWaitingTimeout: event.bondSlashOnWaitingTimeout,
      bondAmountPct: event.bondAmountPct,
      bondBaseAmountSats: event.bondBaseAmountSats,
      bondSlashNodeSharePct: event.bondSlashNodeSharePct,
      bondPayoutClaimWindowDays: event.bondPayoutClaimWindowDays,
      escrowMode: event.escrowMode,
      cashuMintUrls: event.cashuMintUrls,
      cashuEscrowLocktimeDays: event.cashuEscrowLocktimeDays,
    );
  }
}

extension MostroInstanceExtensions on NostrEvent {
  String _getTagValue(String key) {
    final tag = tags?.firstWhere(
      (t) => t.isNotEmpty && t[0] == key,
      orElse: () => const <String>[],
    );
    return (tag != null && tag.length > 1) ? tag[1] : 'Tag: $key not found';
  }

  /// Returns the tag value, or null when the tag is missing or empty.
  ///
  /// Use this for optional tags where absence is semantically meaningful
  /// (e.g. anti-abuse bond tags, which only appear on modern daemons).
  ///
  /// Empty or whitespace-only values are treated as missing so they cannot
  /// be misparsed as legitimate data downstream (e.g. an empty
  /// `bond_enabled=""` would otherwise be classified as `disabled` instead
  /// of `unsupported`, breaking the three-state semantics).
  String? _getOptionalTagValue(String key) {
    final tag = tags?.firstWhere(
      (t) => t.isNotEmpty && t[0] == key,
      orElse: () => const <String>[],
    );
    if (tag == null || tag.length < 2) return null;
    final value = tag[1].trim();
    return value.isEmpty ? null : value;
  }

  String get pubKey => _getTagValue('d');
  String get mostroVersion => _getTagValue('mostro_version');
  String get commitHash => _getTagValue('mostro_commit_hash');
  int get maxOrderAmount => int.parse(_getTagValue('max_order_amount'));
  int get minOrderAmount => int.parse(_getTagValue('min_order_amount'));
  int get expirationHours => int.parse(_getTagValue('expiration_hours'));
  int get expirationSeconds => int.parse(_getTagValue('expiration_seconds'));
  double get fee => double.parse(_getTagValue('fee'));
  int get pow => int.parse(_getTagValue('pow'));
  int get holdInvoiceExpirationWindow =>
      int.parse(_getTagValue('hold_invoice_expiration_window'));
  int get holdInvoiceCltvDelta =>
      int.parse(_getTagValue('hold_invoice_cltv_delta'));
  int get invoiceExpirationWindow =>
      int.parse(_getTagValue('invoice_expiration_window'));
  String get lndVersion => _getTagValue('lnd_version');
  String get lndNodePublicKey => _getTagValue('lnd_node_pubkey');
  String get lndCommitHash => _getTagValue('lnd_commit_hash');
  String get lndNodeAlias => _getTagValue('lnd_node_alias');
  String get supportedChains => _getTagValue('lnd_chains');
  String get supportedNetworks => _getTagValue('lnd_networks');
  String get lndNodeUri => _getTagValue('lnd_uris');
  String get fiatCurrenciesAccepted => _getTagValue('fiat_currencies_accepted');
  int get maxOrdersPerResponse =>
      int.parse(_getTagValue('max_orders_per_response'));

  /// Parses the wire transport version from the `protocol_version` tag (§2).
  ///
  /// Returns `null` when the tag is absent or unparseable. [resolveTransport]
  /// treats `null` as v2 (NIP-44), the live transport; the nullable form is
  /// preserved so it can distinguish "not advertised" from an explicit
  /// `protocol_version=1`, the one value that still selects gift wrap.
  int? get protocolVersion {
    final raw = _getOptionalTagValue('protocol_version');
    return raw == null ? null : int.tryParse(raw);
  }

  /// Parses the anti-spam first-contact PoW difficulty from the
  /// `pow_first_contact` tag. Returns `null` when absent or unparseable so
  /// callers fall back to [pow]; the daemon's advertised value already folds
  /// the base PoW in (`max(pow, effective_pow_first_contact)`).
  int? get powFirstContact {
    final raw = _getOptionalTagValue('pow_first_contact');
    return raw == null ? null : int.tryParse(raw);
  }

  /// NIP-13 difficulty a *first-contact* sender must mine at on this node.
  ///
  /// The daemon advertises `pow_first_contact` already resolved to
  /// `max(pow, effective_pow_first_contact)`, so when present it is the only
  /// value a sender that does not know whether the node recognises its trade
  /// key should use. Legacy daemons omit the tag, in which case the base
  /// `pow` is the right difficulty.
  int get effectiveFirstContactPow => powFirstContact ?? pow;

  /// Parses the anti-abuse bond policy from the `bond_enabled` tag.
  ///
  /// - Tag absent → [BondPolicy.unsupported] (legacy daemon).
  /// - `"true"` → [BondPolicy.enabled].
  /// - `"false"` → [BondPolicy.disabled].
  /// - Any other value → [BondPolicy.unsupported] (defensive: malformed
  ///   payloads must not masquerade as an intentional policy state).
  BondPolicy get bondPolicy {
    final raw = _getOptionalTagValue('bond_enabled')?.toLowerCase();
    switch (raw) {
      case 'true':
        return BondPolicy.enabled;
      case 'false':
        return BondPolicy.disabled;
      default:
        return BondPolicy.unsupported;
    }
  }

  BondApplyTo? get bondApplyTo {
    final raw = _getOptionalTagValue('bond_apply_to');
    switch (raw) {
      case 'take':
        return BondApplyTo.take;
      case 'make':
        return BondApplyTo.make;
      case 'both':
        return BondApplyTo.both;
      default:
        return null;
    }
  }

  /// Parses `bond_slash_on_waiting_timeout`. Returns `null` for any value
  /// other than `"true"` or `"false"` (case-insensitive) so malformed data
  /// is not silently collapsed into a valid policy state.
  bool? get bondSlashOnWaitingTimeout {
    final raw =
        _getOptionalTagValue('bond_slash_on_waiting_timeout')?.toLowerCase();
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return null;
  }

  /// Bond fraction of the order amount. Must be a percentage in `[0.0, 1.0]`;
  /// out-of-range values are treated as invalid and yield `null`.
  double? get bondAmountPct {
    final raw = _getOptionalTagValue('bond_amount_pct');
    final value = raw == null ? null : double.tryParse(raw);
    if (value == null) return null;
    return (value >= 0.0 && value <= 1.0) ? value : null;
  }

  /// Minimum bond floor in sats. Negative values are treated as invalid.
  int? get bondBaseAmountSats {
    final raw = _getOptionalTagValue('bond_base_amount_sats');
    final value = raw == null ? null : int.tryParse(raw);
    if (value == null) return null;
    return value >= 0 ? value : null;
  }

  /// Node share of a slashed bond. Spec constrains this to `[0.0, 1.0]`;
  /// out-of-range values are treated as invalid and yield `null`.
  double? get bondSlashNodeSharePct {
    final raw = _getOptionalTagValue('bond_slash_node_share_pct');
    final value = raw == null ? null : double.tryParse(raw);
    if (value == null) return null;
    return (value >= 0.0 && value <= 1.0) ? value : null;
  }

  /// Payout claim window in days. Must be positive; non-positive or
  /// unparseable values yield `null`.
  int? get bondPayoutClaimWindowDays {
    final raw = _getOptionalTagValue('bond_payout_claim_window_days');
    final value = raw == null ? null : int.tryParse(raw);
    if (value == null) return null;
    return value > 0 ? value : null;
  }

  /// Every value of a repeated tag (the daemon emits one `cashu_mint_url`
  /// tag per mint), trimmed and filtered of blanks. Single-value tags also
  /// work through this helper.
  List<String> _getTagValues(String key) {
    final result = <String>[];
    for (final t in tags ?? const <List<String>>[]) {
      if (t.isNotEmpty && t[0] == key && t.length > 1) {
        final value = t[1].trim();
        if (value.isNotEmpty) result.add(value);
      }
    }
    return result;
  }

  /// Escrow backend. The daemon treats a missing `escrow_mode` tag as
  /// Lightning, so any value other than `"cashu"` resolves to
  /// [EscrowMode.lightning] (defensive default for malformed payloads).
  EscrowMode get escrowMode {
    final raw = _getOptionalTagValue('escrow_mode')?.toLowerCase();
    return raw == 'cashu' ? EscrowMode.cashu : EscrowMode.lightning;
  }

  /// The mints a maker may choose. Empty on a Lightning node or on an open
  /// Cashu node that accepts any mint.
  List<String> get cashuMintUrls => _getTagValues('cashu_mint_url');

  /// Seller-recovery locktime floor in days. Non-negative and unparseable
  /// values yield `null`.
  int? get cashuEscrowLocktimeDays {
    final raw = _getOptionalTagValue('cashu_escrow_locktime_days');
    final value = raw == null ? null : int.tryParse(raw);
    if (value == null) return null;
    return value >= 0 ? value : null;
  }
}
