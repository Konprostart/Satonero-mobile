import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/features/order/models/order_state.dart';
import 'package:satonero_mobile/features/order/providers/order_notifier_provider.dart';
import 'package:satonero_mobile/shared/widgets/bottom_nav_bar.dart';
import 'package:satonero_mobile/data/models/enums/action.dart' as action;

class PaymentConfirmationScreen extends ConsumerWidget {
  final String orderId;

  const PaymentConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the notifier’s state
    final state = ref.watch(orderNotifierProvider(orderId));

    return Scaffold(
      backgroundColor: AppTheme.colors(context).cardBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PAYMENT',
          style: TextStyle(color: AppTheme.colors(context).textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.colors(context).textPrimary),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _buildBody(context, ref, state),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, OrderState state) {
    switch (state.action) {
      case action.Action.purchaseCompleted:
        final satoshis = state.order?.amount ?? 0;

        return Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.colors(context).inputBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.colors(context).accent,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 50,
                    color: AppTheme.colors(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$satoshis',
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'received',
                  style: TextStyle(
                    color: AppTheme.colors(context).textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors(context).accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    // Call the notifier’s method
                    //ref.read(paymentConfirmationProvider.notifier).continueAfterConfirmation();
                    // You can navigate or do further logic
                    // e.g. context.go('/next_screen');
                  },
                  child: const Text('CONTINUE'),
                ),
              ],
            ),
          ),
        );

      case action.Action.cantDo:
        final error = state.cantDo;
        return Center(
          child: Text(
            'Error: ${error?.cantDoReason}',
            style: TextStyle(color: AppTheme.colors(context).textPrimary),
          ),
        );
      default:
        return Center(
          child: Text(
            'Unkown Action: ${state.action}',
            style: TextStyle(color: AppTheme.colors(context).textPrimary),
          ),
        );
    }
  }
}
