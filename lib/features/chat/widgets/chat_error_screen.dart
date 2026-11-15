import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/generated/l10n.dart';

class ChatErrorScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ChatErrorScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  factory ChatErrorScreen.sessionNotFound(BuildContext context) {
    final l10n = S.of(context)!;
    return ChatErrorScreen(
      icon: Icons.error_outline,
      title: l10n.sessionNotFound,
      subtitle: l10n.unableToLoadChatSession,
    );
  }

  factory ChatErrorScreen.peerUnavailable(BuildContext context) {
    final l10n = S.of(context)!;
    return ChatErrorScreen(
      icon: Icons.person_off_outlined,
      title: l10n.peerInformationUnavailable,
      subtitle: l10n.chatPartnerCouldNotBeLoaded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors(context).scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.colors(context).scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.colors(context).textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          S.of(context)!.back,
          style: TextStyle(color: AppTheme.colors(context).textPrimary),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.colors(context).textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.colors(context).textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
