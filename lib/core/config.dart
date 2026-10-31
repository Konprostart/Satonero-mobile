import 'package:flutter/foundation.dart';
import 'package:satonero_mobile/core/test_environment.dart';
import 'package:satonero_mobile/core/config/communities.dart';

class Config {
  // Nostr configuration
  static const List<String> nostrRelays = [
    //'ws://127.0.0.1:7000',
    //'ws://192.168.1.103:7000',
    //'ws://10.0.2.2:7000', // mobile emulator
  ];

  // Public bootstrap relays used only to discover a Mostro daemon's kind
  // 10002 relay list at cold start or when no discovered relay is reachable.
  // These are public relays, not operated by Satonero. Satonero does not run
  // its own relay or Mostro daemon.
  static const List<String> bootstrapRelays = [
    'wss://nos.lol',
    'wss://relay.damus.io',
  ];

  /// Relays used for discovery when nothing else is configured. In the
  /// Mortsom test environment this is the seeded local relay list, never
  /// the public bootstrap relays: a disconnected local relay must produce a
  /// test failure, not public-network traffic (automation contract §3).
  static List<String> get discoveryRelays =>
      TestEnvironment.disableBootstrapFallback
          ? TestEnvironment.seedRelays
          : bootstrapRelays;

  // Derived from trustedCommunities. These are third-party Mostro
  // communities/daemons, not Satonero-operated services.
  static final List<Map<String, String>> trustedMostroNodes =
      trustedCommunities
          .map((c) => {
                'pubkey': c.pubkey,
                'name': c.region,
              })
          .toList();

  // Default Mostro daemon pubkey (third-party, not Satonero-operated;
  // overridable via env variable). Users can select another Mostro daemon.
  static const String mostroPubKey = String.fromEnvironment(
    'MOSTRO_PUB_KEY',
    defaultValue: defaultMostroPubkey,
  );

  static const String dBName = 'mostro.db';
  static const String dBPassword = 'mostro';

  // Timeout for relay connections (WebSocket handshake per relay)
  static const Duration relayConnectionTimeout = Duration(seconds: 5);

  // Timeout for relay operations (EOSE responses, publish OK)
  static const Duration nostrOperationTimeout = Duration(seconds: 20);

  // Grace period for discovered relays to connect before engaging bootstrap.
  static const Duration relayDiscoveryTimeout = Duration(seconds: 6);

  static bool fullPrivacyMode = false;

  // Debug mode
  static bool get isDebug => !kReleaseMode;

  /// Console logging and full log verbosity. Deliberately [kDebugMode] and not
  /// [isDebug]: profile builds are for performance measurement and must not
  /// pay for per-call stack-trace capture and console formatting.
  static bool get verboseLogging => kDebugMode;

  /// Whether the add-relay validation accepts plain `ws://` towards local
  /// hosts (`localhost`, IPv4). True in the Mortsom test environment and in
  /// any non-release build (debug and profile); never in release builds.
  static bool get allowInsecureRelays =>
      TestEnvironment.allowInsecureRelays || isDebug;

  // Key derivation configuration
  static const String keyDerivationPath = "m/44'/1237'/38383'/0";

  static const int expirationSeconds = 900;
  static const int expirationHours = 24;
  static const int cleanupIntervalMinutes = 30;
  static const int sessionExpirationHours = 720;

  /// Upper bound for a pending range-order child session (persisted without an
  /// orderId while waiting for mostrod's child new-order message). The handoff
  /// resolves in seconds, so a record still unlinked after this window never
  /// will be. Bounded independently of [sessionExpirationHours] so orphan
  /// records cannot accumulate when session expiration is disabled (0).
  static const int pendingChildSessionExpirationHours = 48;

  // Notification configuration
  static String notificationChannelId = 'satonero_mobile';
  static int notificationId = 38383;

  // Push notification server configuration
  // Empty by default: Satonero does not operate a push server. Provide a
  // Satonero-owned or self-hosted server with --dart-define=PUSH_SERVER_URL=...
  static const String pushServerUrl = String.fromEnvironment(
    'PUSH_SERVER_URL',
    defaultValue: '',
  );

  static bool get pushConfigured => pushServerUrl.isNotEmpty;
  // Logger configuration
  static const int logMaxEntries = 1000;
  static const int logBatchDeleteSize = 100;
}
