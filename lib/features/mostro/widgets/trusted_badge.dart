import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/generated/l10n.dart';

/// A small badge displaying "Trusted" for trusted Mostro nodes.
class TrustedBadge extends StatelessWidget {
  const TrustedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        S.of(context)!.trusted,
        style: TextStyle(
          color: AppTheme.colors(context).accent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
