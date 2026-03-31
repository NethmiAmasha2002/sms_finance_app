// lib/screens/transaction_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/add_sms_sheet.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final totalExpenses = ref.watch(totalExpensesProvider);
    final totalIncome = ref.watch(totalIncomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Reload sample messages',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(transactionProvider.notifier).reload();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sample messages reloaded'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Text(
                'No transactions yet.\nTap + to add an SMS.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SummaryCard(
                    totalExpenses: totalExpenses,
                    totalIncome: totalIncome,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Transactions (${transactions.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = transactions[index];
                      return TransactionTile(
                        transaction: tx,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransactionDetailScreen(transactionId: tx.id),
                            ),
                          );
                        },
                      );
                    },
                    childCount: transactions.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const AddSmsSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add SMS'),
      ),
    );
  }
}
