import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';

class UnreadIndicator extends StatelessWidget {
  const UnreadIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.colors(context).accent,
        shape: BoxShape.circle,
      ),
    );
  }
}