# Production Hardening Audit — Satonero-mobile

Deep audit of the mobile app targeting production readiness for 1000+ concurrent
users. This document records the issues found, the fixes applied, and the
remaining follow-ups.

Scope: relay management, Nostr transport, restore flow, Telegram linking, settings
persistence, and async/UI-thread/error-handling correctness.

---

## 1. Fixed — relay validation knocked the app's live relays offline (CRITICAL)

**Finding.** `RelaysNotifier._testNostrProtocol` (in `lib/features/relays/relays_notifier.dart`)
created a throwaway `Nostr()` instance for the two-tier relay validation, but its
`catch` block called `_cleanupTestConnection(Nostr.instance)` — the **production
singleton** the real app connections use. Any exception during relay validation
(a malformed URL, a `startEventsSubscriptionAsync` timeout, etc.) called
`disconnectFromRelays()` on the live connections, knocking the whole app offline
as a side effect of a user adding a relay.

**Fix.** The throwaway `testNostr` instance is now declared outside the `try`, and
both the success path and the `catch` path clean up that throwaway instance —
never `Nostr.instance`.

## 2. Fixed — temporary relay fetch leaked relays permanently (MAJOR)

**Finding.** `NostrService._fetchFromSpecificRelays` captured the original relay
list, mutated settings to add temporary relays, then "restored" via
`updateSettings(settings)` — but the `settings` getter reads the **already-mutated**
value, so the `ListEquality` check short-circuited ("Relay list unchanged") and the
temporary relays were never removed.

**Fix.** The full `Settings` snapshot is captured **before** mutating, and both the
success and the error path restore from that snapshot.

## 3. Fixed — fire-and-forget `handleEvent` used `ref`/`state` after dispose (MAJOR)

**Finding.** `AbstractMostroNotifier.handleEvent` (fired via `unawaited(…)`) awaits
the centralized notification extraction and then reads `ref` and assigns `state`
with no `mounted` guard. If the notifier is disposed mid-flight (a concurrent
cancel/timeout deletes the session), the post-await `ref.read`/`state =` throws out
of an unawaited future.

**Fix.** Added `if (!mounted) return;` after the extraction await, covering the
fire-and-forget path.

## 4. Fixed — settings persistence robustness (MAJOR/MINOR)

- `SettingsNotifier._saveToPrefs` now catches and logs persistence failures instead
  of letting them propagate as unhandled async errors out of discarded `update*`
  futures (the settings toggle handlers are fire-and-forget).
- `isLoggingEnabled` is now persisted: added to `Settings.toJson`/`fromJson` and
  `updateLoggingEnabled` now calls `_saveToPrefs()` (previously it reset to `false`
  on every app restart).

## 5. Fixed — missing `mounted` guards (MINOR)

- `AddCustomNodeDialog` — added `if (!mounted) return;` after the
  `addCustomNode` persistence await (the dialog is barrier-dismissible).
- `settings_screen.dart` private-mode switch — added `if (!mounted) return;` after
  the `showDialog` await before `ref.read`.
- `BackupReminderNotifier._loadBackupReminderState` — added `if (!mounted) return;`
  before the async `state =` write.

## 6. Fixed — fire-and-forget without `unawaited` (MINOR)

`MostroNodesNotifier.updateNodeMetadata` now wraps the best-effort
`_saveCustomNodes` in `unawaited(…)` (the function already logs failures and
returns `false` instead of throwing).

---

## 7. Remaining follow-ups (documented, lower severity)

- `restore_manager.dart` hardcodes a 10-second `Future.delayed` for historical
  message arrival and duplicates a 10-second timeout inline. Both should be
  extracted to a named constant and/or gated on a deterministic "history complete"
  signal.
- `restore_manager.dart` `_handleTempSubscriptionsResponse` completes on the first
  event without validating it against the current stage; a straggler copy of a
  previous stage's response could satisfy the wrong stage's completer.
- `deep_link_service.dart` / `nostr_service.dart` collapse a relay/network failure
  into `null`, surfacing "order not found" on a transient connectivity error; they
  should distinguish "network failure" from "not found" for a retryable message.

## 8. Verified correct / intentional (no action needed)

- Telegram linking toggle (`settings_screen.dart`) — persistence is committed
  immediately and the network handshake is `unawaited` with `mounted` guards; the
  toggle never waits on or is reverted by the network.
- Push-token registration, node-metadata cache persistence, and chat-cursor
  advancement are intentional fire-and-forget with `.catchError` handlers.
- `RestoreProgressNotifier` guards every state write with `mounted`.
- `add_lightning_invoice_screen` and the NWC widgets already `if (!mounted) return;`
  after every await and map distinct failure kinds to distinct messages.

## 9. Verification

```sh
flutter analyze   # No issues found
flutter test      # full suite
```
