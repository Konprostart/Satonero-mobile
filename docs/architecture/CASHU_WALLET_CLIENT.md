# Cashu Wallet Client (NUT-11 P2PK 2-of-3) — architecture prep

**Status:** Preparation (scaffolding + design; no FFI wired into the app build yet)
**Scope:** `rust/`, `lib/features/cashu/wallet/`, `flutter_rust_bridge.yaml`

This document records the architecture for the **future client-side Cashu wallet**.
Today the app only *selects and displays* the mint (`CashuMintSelector`,
`CashuMintInfoCard`) and the daemon performs all escrow cryptography. A future
release will move mint interaction and NUT-11 P2PK 2-of-3 signing into the app
so the wallet can lock, release, cancel and refund escrow tokens directly.

## License note (MIT)

Everything introduced here is written from scratch against the open Cashu
protocol and MIT-licensed building blocks:

| Component | License |
|---|---|
| Cashu CDK Rust crates (`cashu`, `cdk`) | MIT OR Apache-2.0 |
| `flutter_rust_bridge` | MIT |
| Cashu NUT specifications (NUT-11 P2PK, NUT-07 token state check, …) | Open spec |
| Satonero Dart/Rust code in this repo | MIT |

No code is copied from the upstream `MostroP2P/app` client (AGPL-3.0). The
CDK itself ships official Dart bindings under `bindings/dart` (UniFFI-based),
but this repo targets `flutter_rust_bridge` so the bridge stays a plain, audited
Rust function surface rather than importing the AGPL client's glue.

## Why Rust/CDK instead of pure Dart

There is no mature, maintained pure-Dart Cashu library on pub.dev. The CDK is
the reference implementation and already provides:

- NUT-11 `SpendingConditions` / `P2PKConditions` and `sign_p2pk`
  (`cashu::nuts::nut11`) — exactly the 2-of-3 multisig the daemon uses;
- mint client APIs (mint/swap/check-state) behind the `wallet` feature;
- BIP-340 signing through the `bitcoin` crate.

Bridging the `cashu` crate through `flutter_rust_bridge` therefore gives us the
proven primitives without reimplementing secp256k1/musig2 in Dart.

## Architecture

```text
Dart (lib/features/cashu/wallet/)
  CashuWalletApi  ── abstract interface (MIT, testable with a fake)
        │  implemented by
        ▼
  CashuWalletFfi ── thin flutter_rust_bridge caller (generated)
        │  FFI (async, one Dart isolate → Rust)
        ▼
Rust (rust/)
  satonero_cashu lib ── escrow module (NUT-11 P2PK 2-of-3)
        │
        ▼
  cashu crate (CDK) ── SpendingConditions, sign_p2pk, mint client
```

The Dart side depends only on the `CashuWalletApi` abstraction, never on the
generated FFI types directly. That keeps the business logic unit-testable and
lets the Rust bridge stay a pure adapter.

### NUT-11 P2PK 2-of-3 flow

1. **Lock** — the buyer (maker) mints/selects proofs and wraps them with a P2PK
   spending condition requiring signatures from any **2 of 3** keys: buyer,
   seller, and the daemon's escrow key. The token also carries the
   seller-recovery `locktime` floor (`cashu_escrow_locktime_days`).
2. **Release** — seller + daemon (or buyer + daemon) co-sign to spend the token
   to the seller.
3. **Cooperative cancel** — buyer + daemon co-sign to return funds to the buyer.
4. **Refund after locktime** — after `locktime`, the seller alone can spend the
   token (single-party path).

The wallet must check the token state (NUT-07) against the mint before trusting
any "locked" proof, because a mint can lie. That check is the client-side trust
boundary the take-order screen's mint display makes visible to the user.

## Directory layout

| Path | Purpose |
|---|---|
| `flutter_rust_bridge.yaml` | Bridge codegen config (rust root, dart output) |
| `rust/Cargo.toml` | `satonero_cashu` crate, depends on `cashu` (CDK) |
| `rust/src/lib.rs` | Crate root; exposes `escrow` module |
| `rust/src/escrow.rs` | NUT-11 P2PK 2-of-3 types + operation signatures |
| `lib/features/cashu/wallet/cashu_wallet_api.dart` | Dart types + `CashuWalletApi` interface |

## Build integration (later work, not wired yet)

- Add `flutter_rust_bridge` (Dart) to `pubspec.yaml`.
- Generate `lib/features/cashu/wallet/bridge_generated.dart` +
  `rust/src/frb_generated.rs` with `flutter_rust_bridge_codegen generate`.
- Android: `cargo-ndk` to produce the ARM64/ARMv7/x86_64 `.so` targets; the
  workspace toolchain already provides JDK 17 / Android SDK 36 / ARM64 Build
  Tools. iOS: `cargo lipo`/`cargo-xcode`. The CDK's `cashu` crate is
  `unsafe_code = forbid`, so it builds for all those targets.
- Keep the `CashuWalletFfi` behind an `ffi`-conditional import so the web build
  (no Rust CDK target) keeps compiling with a Dart fallback.

## Current status

- [x] Design + license matrix (this doc).
- [x] Rust crate skeleton (`rust/`), bridge config, Dart API interface.
- [x] Real NUT-11 P2PK primitives in `rust/src/escrow.rs`
      (`build_escrow_spending_conditions`, `sign_proof`, `verify_proof_p2pk`)
      delegating to the CDK, with Rust unit tests.
- [x] `flutter_rust_bridge` codegen wired in (`flutter_rust_bridge` 2.12.0 in
      `pubspec.yaml`/`Cargo.toml`, generated glue under
      `lib/features/cashu/wallet/bridge/` + `rust/src/frb_generated.rs`).
- [x] `CashuWalletFfi` (`lib/features/cashu/wallet/cashu_wallet_ffi.dart`)
      implementing `CashuWalletApi` and exposing the three primitives.
- [ ] Android/iOS `.so` cross-compilation (needs the NDK; the bridge falls back
      to `CashuWalletException('wallet_unavailable')` until the native library
      is built for the target).
- [ ] Mint session + proof selection orchestrator, so `lockEscrow` /
      `releaseEscrow` / `cancelEscrow` / `refundAfterLocktime` can run end to
      end and be consumed by the order screens.
