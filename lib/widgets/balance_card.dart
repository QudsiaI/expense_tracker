import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final String title;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: balance >= 0 ? Colors.blue.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  balance >= 0 
                      ? Icons.account_balance_wallet 
                      : Icons.warning_amber_rounded,
                  color: balance >= 0 ? Colors.blue : Colors.orange,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rs. ${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}