# Cashu Escrow Client (mint selection)

**Status:** Active (client-side selection + architecture)
**Scope:** `lib/features/cashu/`, `lib/features/mostro/mostro_instance.dart`,
`lib/data/models/order.dart`, `lib/data/models/nostr_event.dart`

The daemon (`mostrod`) already implements Cashu escrow (NUT-11 P2PK, 2-of-3
multisig). This document covers the **mobile client** side: how the app reads
the node's escrow capability from the kind-38385 info event and lets a maker
choose the mint before publishing an order. The wallet cryptography runs on the
daemon; the client only selects and carries a mint URL.

## License note (MIT)

Nothing in this feature is copied from the upstream `MostroP2P/app` (AGPL-3.0)
client. The client integrates by:

- parsing the **open kind-38385 tag contract** the daemon already emits
  (`escrow_mode`, `cashu_mint_url`, `cashu_escrow_locktime_days`);
- carrying `cashu_mint_url` on the `Order` wire message, which is defined by the
  MIT-licensed `satonero-core` (`SmallOrder.cashu_mint_url`).

The Cashu NUT specifications and the Cashu CDK (MIT OR Apache-2.0) remain the
MIT-compatible building blocks for any future client-side wallet work.

## Kind-38385 tags

The daemon emits these tags on its addressable kind-38385 info event:

| Tag | Meaning |
|---|---|
| `escrow_mode` | `"lightning"` or `"cashu"`. Absent = legacy Lightning daemon. |
| `cashu_mint_url` | One tag per mint a maker may choose (repeated). Absent on an open node (`mint_urls = []`), which accepts any public mint. |
| `cashu_escrow_locktime_days` | Seller-recovery locktime floor for a Cashu escrow token. |

Order events (kind 38383/38384) carry a single `cashu_mint_url` tag naming the
mint a maker locked in, so a taker sees it before taking the order
(issue #1046).

## Parsing

`MostroInstanceExtensions` (`lib/features/mostro/mostro_instance.dart`) adds:

- `EscrowMode` enum (`lightning`, `cashu`);
- `escrowMode` — `"cashu"` → cashu, anything else → lightning;
- `cashuMintUrls` — all values of the repeated `cashu_mint_url` tag;
- `cashuEscrowLocktimeDays` — optional int.

`NostrEventExtensions.cashuMintUrl` (`lib/data/models/nostr_event.dart`) reads
the single mint tag on order events, used by `Order.fromEvent`.

## Providers

`nodeEscrowInfoProvider` (`lib/features/cashu/cashu_mint_provider.dart`) is a
`StreamProvider<NodeEscrowInfo>` bridging `OpenOrdersRepository.mostroInstance`
with `mostroInstanceStream`, so the mint selector appears as soon as the node's
`escrow_mode` is known. `NodeEscrowInfo` carries `escrowMode`, `mintUrls` and
`escrowLocktimeDays`.

## Mint selection

`CashuMintSelector` (`lib/features/cashu/cashu_mint_selector.dart`) renders
only for Cashu nodes and matches the daemon's mint policy
(`cashu::mint_policy::resolve_order_mint`):

- **allow-list node** (one or more advertised mints) → a dropdown of those
  mints;
- **open node** (no advertised mints) → a free-form URL field.

The `AddOrderScreen` stores the choice in `_cashuMintUrl`. On submit it:

1. awaits the node info event;
2. when the node is Cashu, requires a mint — defaulting to the single
   advertised mint when exactly one exists;
3. attaches the mint to the `Order` as `cashuMintUrl`, serialized to the
   `cashu_mint_url` field of the `new-order` message (omitted when null, so a
   Lightning order never carries the field).

## Order model

`Order` gains a nullable `cashuMintUrl` with round-trip support in
`toJson` / `fromJson` / `toMap` / `fromMap` / `props`, and is populated from
`event.cashuMintUrl` in `Order.fromEvent`.
