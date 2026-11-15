import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/relays/widgets/relay_selector.dart';

class RelaysScreen extends ConsumerWidget {
  const RelaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(HeroIcons.arrowLeft, color: AppTheme.colors(context).textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            color: AppTheme.colors(context).textPrimary,
          ),
        ),
      ),
      backgroundColor: AppTheme.colors(context).cardBackground,
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: RelaySelector(),
      ),
    );
  }
}
