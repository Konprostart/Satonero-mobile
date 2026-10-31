import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/services/push_notification_service.dart';
import 'package:satonero_mobile/shared/providers/fcm_service_provider.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final fcmService = ref.watch(fcmServiceProvider);
  return PushNotificationService(fcmService: fcmService);
});
