// lib/screens/transaction_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactively watch so changes (e.g. category update) reflect immediately
    final transactions = ref.watch(transactionProvider);
    final tx = transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw StateError('Transaction not found'),
    );

    final isExpense = tx.type == TransactionType.expense;
    final amountColor =
        isExpense ? Colors.red.shade700 : Colors.green.shade700;
    final amountPrefix = isExpense ? '-' : '+';
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero amount card ─────────────────────────────────────────
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: isExpense
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isExpense
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      tx.category.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$amountPrefix LKR ${fmt.format(tx.amount)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExpense
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isExpense ? 'EXPENSE' : 'INCOME',
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Details list ─────────────────────────────────────────────
            const _SectionHeader(title: 'Details'),
            _DetailRow(
              icon: Icons.store_outlined,
              label: 'Merchant',
              value: tx.merchant,
            ),
            _DetailRow(
              icon: Icons.credit_card_outlined,
              label: 'Account',
              value: tx.accountRef,
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date & Time',
              value: DateFormat('dd MMM yyyy, HH:mm:ss').format(tx.dateTime),
            ),
            _DetailRow(
              icon: Icons.swap_vert_outlined,
              label: 'Type',
              value: isExpense ? 'Debit (Expense)' : 'Credit (Income)',
            ),
            const SizedBox(height: 24),

            // ── Category update ──────────────────────────────────────────
            const _SectionHeader(title: 'Category'),
            const SizedBox(height: 8),
            _CategorySelector(
              currentCategory: tx.category,
              onChanged: (newCat) {
                ref
                    .read(transactionProvider.notifier)
                    .updateCategory(tx.id, newCat);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Category updated to ${newCat.label}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.indigo.shade600,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Raw SMS ──────────────────────────────────────────────────
            const _SectionHeader(title: 'Raw SMS Message'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                tx.rawMessage,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Category selector ──────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final TransactionCategory currentCategory;
  final ValueChanged<TransactionCategory> onChanged;

  const _CategorySelector({
    required this.currentCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransactionCategory.values.map((cat) {
        final isSelected = cat == currentCategory;
        return ChoiceChip(
          label: Text('${cat.emoji} ${cat.label}'),
          selected: isSelected,
          selectedColor: Colors.indigo.shade100,
          onSelected: (_) {
            if (!isSelected) onChanged(cat);
          },
          labelStyle: TextStyle(
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.indigo.shade800
                : Colors.black87,
          ),
        );
      }).toList(),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.black54,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.indigo.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
