// Satonero Firebase options.
//
// Satonero does not ship a Firebase project or google-services.json.
// Push notifications are opt-in: pass FIREBASE_* values and a
// Satonero-owned or self-hosted PUSH_SERVER_URL at build time, e.g.
//   flutter build apk --dart-define=FIREBASE_API_KEY=... \
//     --dart-define=FIREBASE_APP_ID=... \
//     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
//     --dart-define=FIREBASE_PROJECT_ID=... \
//     --dart-define=PUSH_SERVER_URL=https://...
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.konprostart.satonero',
  );

  /// True only when the minimum Firebase values were supplied at build time.
  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('Firebase is not supported on Linux.');
      default:
        throw UnsupportedError(
          'Firebase is not supported on this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );

  static FirebaseOptions get macos => ios;

  static FirebaseOptions get windows => web;
}
