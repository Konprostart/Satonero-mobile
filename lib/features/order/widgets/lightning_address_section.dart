import 'package:flutter/material.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/order/widgets/form_section.dart';
import 'package:satonero_mobile/generated/l10n.dart';

class LightningAddressSection extends StatelessWidget {
  final TextEditingController controller;

  const LightningAddressSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: S.of(context)!.lightningAddressOptional,
      icon: Icon(Icons.bolt,
          color: AppTheme.colors(context).lightningBlue, size: 18),
      iconBackgroundColor:
          AppTheme.colors(context).lightningBlue.withValues(alpha: 0.3),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppTheme.colors(context).textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: S.of(context)!.enterLightningAddress,
          hintStyle: TextStyle(color: AppTheme.colors(context).textInactive),
        ),
      ),
    );
  }
}
