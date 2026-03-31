// lib/providers/transaction_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/sms_parser_service.dart';
import '../services/sample_sms_service.dart';


// Service providers


final smsParserServiceProvider = Provider<SmsParserService>((ref) {
  return SmsParserService();
});


// Transaction notifier


class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final SmsParserService _parser;

  TransactionNotifier(this._parser) : super([]) {
    _loadSampleMessages();
  }

  /// Parses all sample SMS messages and populates state.
  void _loadSampleMessages() {
    final parsed = SampleSmsService.messages
        .map((msg) => _parser.parse(msg))
        .whereType<TransactionModel>()
        .toList();

    // Sort newest first
    parsed.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = parsed;
  }

  /// Parses a single raw SMS and adds it to the list.
  void addFromSms(String rawMessage) {
    final tx = _parser.parse(rawMessage);
    if (tx == null) return;

    final updated = [tx, ...state];
    updated.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = updated;
  }

  /// Updates the category of a transaction by id.
  void updateCategory(String id, TransactionCategory newCategory) {
    state = state.map((tx) {
      if (tx.id == id) return tx.copyWith(category: newCategory);
      return tx;
    }).toList();
  }

  /// Reloads from sample messages (reset).
  void reload() => _loadSampleMessages();
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  final parser = ref.watch(smsParserServiceProvider);
  return TransactionNotifier(parser);
});


// Derived / computed providers


/// Total expenses across all transactions
final totalExpensesProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionProvider);
  return txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Total income across all transactions
final totalIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionProvider);
  return txs
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// A single transaction by id (used in detail screen)
final transactionByIdProvider =
    Provider.family<TransactionModel?, String>((ref, id) {
  return ref.watch(transactionProvider).firstWhere(
        (tx) => tx.id == id,
        orElse: () => throw StateError('Transaction $id not found'),
      );
});
