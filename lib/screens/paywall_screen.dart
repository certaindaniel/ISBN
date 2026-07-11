import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.paywall_title), centerTitle: true),
      body: Consumer<PurchaseService>(
        builder: (context, purchase, child) {
          if (purchase.isUnlocked) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 72),
                  const SizedBox(height: 16),
                  Text(loc.paywall_unlocked,
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }

          final price = purchase.product?.price;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.auto_stories, color: Colors.blue, size: 72),
                const SizedBox(height: 16),
                Text(
                  loc.paywall_subtitle(PurchaseService.freeBookLimit),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                _feature(Icons.all_inclusive, loc.paywall_feature_unlimited),
                _feature(Icons.trending_up, loc.paywall_feature_profit),
                _feature(Icons.lock_open, loc.paywall_feature_once),
                const Spacer(),
                if (purchase.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(purchase.lastError!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (purchase.product == null ||
                            purchase.purchasePending)
                        ? null
                        : () => purchase.buy(),
                    child: purchase.purchasePending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(price != null
                            ? loc.paywall_buy(price)
                            : loc.paywall_unavailable),
                  ),
                ),
                TextButton(
                  onPressed:
                      purchase.purchasePending ? null : () => purchase.restore(),
                  child: Text(loc.paywall_restore),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
