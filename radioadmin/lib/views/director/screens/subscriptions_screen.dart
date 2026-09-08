import 'package:flutter/material.dart';
import '../../../core/models/director/subscription_model.dart';

class SubscriptionsScreen extends StatelessWidget {
  final List<Subscription> subscriptions;
  final Future<void> Function(Subscription) onCreate;
  final Future<void> Function(String, Map<String, dynamic>) onUpdate;

  const SubscriptionsScreen({
    Key? key,
    required this.subscriptions,
    required this.onCreate,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Subscriptions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final sub = subscriptions[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: sub.statusColor, child: Icon(Icons.card_membership, color: Colors.white)),
                    title: Text(sub.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${sub.tierLabel} • ${sub.statusLabel}'),
                    trailing: Text('\$${sub.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
