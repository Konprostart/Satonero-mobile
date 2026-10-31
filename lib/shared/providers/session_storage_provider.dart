import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/data/repositories/session_storage.dart';
import 'package:satonero_mobile/features/key_manager/key_manager_provider.dart';
import 'package:satonero_mobile/shared/providers/mostro_database_provider.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  final keyManager = ref.read(keyManagerProvider);
  final database = ref.read(mostroDatabaseProvider);
  return SessionStorage(keyManager, db: database);
});
