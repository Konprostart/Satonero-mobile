//! Client-side Cashu wallet orchestration (NUT-04 mint, NUT-05 melt, NUT-06
//! mint info, NUT-07 proof state check).
//!
//! This module wraps the Cashu Development Kit (`cdk` crate, MIT) with a
//! Redb-backed store (`cdk-redb`, MIT). It is deliberately exposed to Dart as a
//! set of **synchronous** FFI functions: each one `block_on`s the underlying
//! async CDK call on a process-wide Tokio runtime, so the `flutter_rust_bridge`
//! boundary stays simple and the Dart side only ever sees plain strings/u64s
//! (JSON for compound results). No code is copied from the AGPL-licensed
//! upstream `MostroP2P/app` client — everything here is the MIT/Apache-2.0 CDK.
//!
//! A wallet is keyed by its mint URL and cached in a process-wide registry for
//! the lifetime of the app. Proofs, quotes and transactions are persisted by
//! `cdk-redb` in the file at `db_path` (an absolute path supplied by Dart via
//! `path_provider`). The 64-byte signing seed is currently generated per
//! session; NUT-11 P2PK key-persistence across restarts is a documented
//! follow-up (see `docs/architecture/CASHU_WALLET_CLIENT.md`).

use std::collections::HashMap;
use std::path::Path;
use std::sync::{Arc, LazyLock, RwLock};

use anyhow::{anyhow, Context, Result};
use cashu::amount::SplitTarget;
use cashu::nuts::CurrencyUnit;
use cdk::nuts::PaymentMethod;
use cdk::wallet::Wallet;
use cdk_redb::WalletRedbDatabase;
use tokio::runtime::Runtime;

/// Process-wide Tokio runtime used to drive the async CDK wallet from the
/// synchronous FFI surface.
fn runtime() -> &'static Runtime {
    static RT: LazyLock<Runtime> =
        LazyLock::new(|| Runtime::new().expect("failed to build Tokio runtime"));
    &RT
}

/// Live wallets keyed by mint URL.
static WALLETS: LazyLock<RwLock<HashMap<String, Arc<Wallet>>>> =
    LazyLock::new(|| RwLock::new(HashMap::new()));

/// Load (or construct) the wallet for `mint_url`, backed by `db_path`.
fn ensure_wallet(mint_url: &str, db_path: &str) -> Result<Arc<Wallet>> {
    if let Some(wallet) = WALLETS
        .read()
        .map_err(|e| anyhow!("wallet registry poisoned: {e}"))?
        .get(mint_url)
    {
        return Ok(Arc::clone(wallet));
    }

    let mut seed = [0u8; 64];
    getrandom::getrandom(&mut seed).map_err(|e| anyhow!("rng failure: {e}"))?;

    let database = WalletRedbDatabase::new(Path::new(db_path))
        .context("open wallet database (does the parent directory exist?)")?;
    let wallet = Wallet::new(
        mint_url,
        CurrencyUnit::Sat,
        Arc::new(database),
        seed,
        None,
    )
    .map_err(|e| anyhow!("wallet initialization failed: {e}"))?;

    let wallet = Arc::new(wallet);
    WALLETS
        .write()
        .map_err(|e| anyhow!("wallet registry poisoned: {e}"))?
        .insert(mint_url.to_string(), Arc::clone(&wallet));
    Ok(wallet)
}

/// Fetch mint metadata (NUT-06) and return it as a JSON string.
///
/// This is the "Sync with mint" first step: it refreshes the mint's advertised
/// capabilities, keysets and fee schedule.
pub fn mint_info(mint_url: String, db_path: String) -> Result<String> {
    let wallet = ensure_wallet(&mint_url, &db_path)?;
    let info = runtime()
        .block_on(wallet.load_mint_info())
        .map_err(|e| anyhow!("fetch mint info: {e}"))?;
    serde_json::to_string(&info).context("serialize mint info")
}

/// Return the wallet's spendable balance in satoshis.
pub fn wallet_balance(mint_url: String, db_path: String) -> Result<u64> {
    let wallet = ensure_wallet(&mint_url, &db_path)?;
    let amount = runtime()
        .block_on(wallet.total_balance())
        .map_err(|e| anyhow!("read balance: {e}"))?;
    Ok(u64::from(amount))
}

/// Create a NUT-04 mint quote and return its Lightning invoice + quote id.
///
/// The caller pays the returned `invoice`; once paid it calls [`mint_tokens`]
/// with `quote_id` to settle the deposit into ecash proofs.
///
/// Returns JSON: `{"quote_id": "...", "invoice": "..."}`.
pub fn receive_invoice(mint_url: String, db_path: String, amount_sats: u64) -> Result<String> {
    let wallet = ensure_wallet(&mint_url, &db_path)?;
    let amount = cashu::Amount::from(amount_sats);
    let quote = runtime()
        .block_on(wallet.mint_quote(
            PaymentMethod::BOLT11,
            Some(amount),
            Some("Satonero Cashu wallet deposit".to_string()),
            None,
        ))
        .map_err(|e| anyhow!("create mint quote: {e}"))?;

    let value = serde_json::json!({
        "quote_id": quote.id,
        "invoice": quote.request,
        "amount_sats": amount_sats,
    });
    serde_json::to_string(&value).context("serialize mint quote")
}

/// Settle a paid NUT-04 mint quote, returning the amount minted in satoshis.
pub fn mint_tokens(mint_url: String, db_path: String, quote_id: String) -> Result<u64> {
    let wallet = ensure_wallet(&mint_url, &db_path)?;
    let proofs = runtime()
        .block_on(wallet.mint(&quote_id, SplitTarget::None, None))
        .map_err(|e| anyhow!("mint tokens: {e}"))?;

    let minted: u64 = proofs.iter().map(|p| u64::from(p.amount)).sum();
    Ok(minted)
}

/// Receive an encoded Cashu token (NUT-00), returning the amount in satoshis.
pub fn receive_token(mint_url: String, db_path: String, token: String) -> Result<u64> {
    let wallet = ensure_wallet(&mint_url, &db_path)?;
    let amount = runtime()
        .block_on(wallet.receive(&token, cdk::wallet::ReceiveOptions::default()))
        .map_err(|e| anyhow!("receive token: {e}"))?;
    Ok(u64::from(amount))
}

/// Pay a Lightning invoice (NUT-05 melt), returning the payment preimage.
pub fn send_invoice(mint_url: String, db_path: String, bolt11: String) -> Result<String> {
    let wallet = ensure_wallet(&mint_url, &db_path)?;
    let quote = runtime()
        .block_on(wallet.melt_quote(PaymentMethod::BOLT11, &bolt11, None, None))
        .map_err(|e| anyhow!("create melt quote: {e}"))?;

    let prepared = runtime()
        .block_on(wallet.prepare_melt(&quote.id, HashMap::new()))
        .map_err(|e| anyhow!("prepare melt: {e}"))?;

    let finalized = runtime()
        .block_on(prepared.confirm())
        .map_err(|e| anyhow!("melt payment: {e}"))?;

    let value = serde_json::json!({
        "preimage": finalized.payment_proof(),
        "amount_sats": u64::from(finalized.amount()),
    });
    serde_json::to_string(&value).context("serialize melt result")
}

/// Synchronize the wallet with the mint.
///
/// Checks the spend state of every pending proof (NUT-07), then refreshes mint
/// metadata (NUT-06). Returns JSON:
/// `{"balance_sats": ..., "freed_sats": ..., "mint_name": "...", "mint_version": "..."}`.
pub fn sync_wallet(mint_url: String, db_path: String) -> Result<String> {
    let wallet = ensure_wallet(&mint_url, &db_path)?;

    let freed = runtime()
        .block_on(wallet.check_all_pending_proofs())
        .map_err(|e| anyhow!("check pending proofs: {e}"))?;

    let balance = runtime()
        .block_on(wallet.total_balance())
        .map_err(|e| anyhow!("read balance: {e}"))?;

    let info = runtime()
        .block_on(wallet.load_mint_info())
        .map_err(|e| anyhow!("refresh mint info: {e}"))?;

    let value = serde_json::json!({
        "balance_sats": u64::from(balance),
        "freed_sats": u64::from(freed),
        "mint_name": info.name,
        "mint_version": info.version,
    });
    serde_json::to_string(&value).context("serialize sync summary")
}
