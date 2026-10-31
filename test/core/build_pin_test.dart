import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/core/config.dart';
import 'package:satonero_mobile/core/legacy_daemon_migration.dart';

const _custom =
    '5555555555555555555555555555555555555555555555555555555555555555';

void main() {
  group('MOSTRO_PUB_KEY build-time pin', () {
    test('the legacy upstream pubkey is rejected and resolves to unconfigured',
        () {
      expect(resolveBuildMostroPubKey(legacyUpstreamDaemonPubkey), isEmpty);
    });

    test('the legacy pubkey is rejected in any letter case or padding', () {
      expect(
        resolveBuildMostroPubKey('  ${legacyUpstreamDaemonPubkey.toUpperCase()} '),
        isEmpty,
      );
      expect(isLegacyBuildPin(legacyUpstreamDaemonPubkey.toUpperCase()), isTrue);
    });

    test('a custom build-time daemon is preserved unchanged', () {
      expect(resolveBuildMostroPubKey(_custom), _custom);
      expect(isLegacyBuildPin(_custom), isFalse);
    });

    test('an empty pin stays unconfigured', () {
      expect(resolveBuildMostroPubKey(''), isEmpty);
      expect(isLegacyBuildPin(''), isFalse);
    });

    test('a test build without a pin has no daemon and no rejected pin', () {
      expect(Config.mostroPubKey, isEmpty);
      expect(Config.legacyBuildPinRejected, isFalse);
    });
  });
}
