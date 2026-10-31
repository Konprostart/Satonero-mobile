import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:satonero_mobile/features/settings/settings_provider.dart';
import 'package:satonero_mobile/services/nostr_service.dart';

final nostrServiceProvider = Provider<NostrService>((ref) {
  final nostrService = NostrService();

  ref.listen<Settings>(settingsProvider, (previous, next) {
    nostrService.updateSettings(next);
  });

  return nostrService;
});
