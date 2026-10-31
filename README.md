# Satonero

Satonero is a Satonero-branded Android/desktop client for the
[Mostro](https://github.com/MostroP2P/protocol) peer-to-peer Bitcoin protocol.
It is a fork of [MostroP2P/mobile](https://github.com/MostroP2P/mobile).

Satonero is **not** operated by the Mostro project, and it is **not** a claim
that Satonero owns or operates the Mostro network.

## What Satonero changes

- Android package/application ID: `com.konprostart.satonero`
- iOS/macOS bundle ID: `com.konprostart.satonero`
- Dart package: `satonero_mobile`
- Satonero name, icon, splash, wordmark, and orange (`#FF9C24`) theme
- Removed Mostro-owned Firebase project files and the Google Services Gradle plugin
- Removed the `https://mostro-push-server.fly.dev` default
- Removed the `wss://mostro-p2p.tech` bootstrap relay
- Satonero repository links and a clear upstream-attribution notice

## What remains and what is blocked

- **Mostro protocol:** `mostro:` deep links, Nostr event kinds, and Mostro
  daemon messages are retained for compatibility. Mostro daemon classes and
  protocol terminology are intentionally kept.
- **Mostro daemons:** Satonero does not run a Mostro daemon. The app connects to
  third-party Mostro instances. The default community list is a convenience,
  not a Satonero-operated service.
- **Nostr relays:** Bootstrap relays are public relays (`wss://nos.lol`,
  `wss://relay.damus.io`) and are not operated by Satonero. Users can configure
  their own relays.
- **Push notifications:** Disabled by default. Satonero ships no Firebase
  project and no push server. To enable push, supply your own Firebase values
  and push server at build time:
  ```bash
  flutter build apk --release \
    --dart-define=FIREBASE_API_KEY=... \
    --dart-define=FIREBASE_APP_ID=... \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
    --dart-define=FIREBASE_PROJECT_ID=... \
    --dart-define=PUSH_SERVER_URL=https://your-push-server.example
  ```
- **Trading end-to-end:** Not verified in this repository without a live Mostro
  daemon and Lightning setup. Unit/widget tests are run in CI; live trading is
  an external integration test.
- **Release signing:** CI uses the debug signing key unless a release keystore
  is supplied via `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`,
  `ANDROID_KEYSTORE_PASSWORD`, and `ANDROID_KEYSTORE_FILE`.

## Build

```bash
flutter pub get
dart run build_runner build -d
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --release
```

The Android release APK is written to
`build/app/outputs/flutter-apk/app-release.apk`.

## License and attribution

Satonero is distributed under the MIT License; see [LICENSE](LICENSE).
Upstream Mostro copyright and license notices are preserved. See
[NOTICE](NOTICE) for attribution. The `mostro:` scheme and Mostro protocol
names are retained for protocol compatibility.
