import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';

/// Warning icon widget for dispute list items
class DisputeIcon extends StatelessWidget {
  const DisputeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Icon(
        Icons.warning_amber,
        color: AppTheme.colors(context).warning,
        size: 32,
      ),
    );
  }
}
