import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:satonero_mobile/features/telegram/telegram_link_service.dart';

/// The single [TelegramLinkService] instance used by the settings toggle.
///
/// Kept as a plain provider because the service owns transient request state,
/// not widget state; the settings screen drives it directly and surfaces
/// errors itself.
final telegramLinkServiceProvider = Provider<TelegramLinkService>((ref) {
  return TelegramLinkService(ref);
});
