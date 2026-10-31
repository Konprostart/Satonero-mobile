import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';

class UnreadIndicator extends StatelessWidget {
  const UnreadIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.satoneroOrange,
        shape: BoxShape.circle,
      ),
    );
  }
}