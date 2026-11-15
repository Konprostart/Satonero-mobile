//! Cashu escrow wallet bridge for Satonero (NUT-11 P2PK 2-of-3).
//!
//! This crate is the Rust half of the future `flutter_rust_bridge` boundary.
//! It is intentionally kept free of `flutter_rust_bridge` macros so it builds
//! as a plain Rust library during the preparation phase; `#[frb]` annotations
//! and codegen are added when the FFI is wired into the app build.
//!
//! The actual mint interaction and NUT-11 cryptography come from the Cashu
//! Development Kit (`cashu` crate, MIT OR Apache-2.0). See
//! `docs/architecture/CASHU_WALLET_CLIENT.md` for the full design and license
//! matrix.

pub mod escrow;
