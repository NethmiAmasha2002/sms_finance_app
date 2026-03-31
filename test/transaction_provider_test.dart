// test/transaction_provider_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_finance_app/models/transaction_model.dart';
import 'package:sms_finance_app/providers/transaction_provider.dart';

void main() {
  // Helper: create a fresh ProviderContainer for each test
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIAL STATE
  // ──────────────────────────────────────────────────────────────────────────
  group('Initial state', () {
    test('loads sample messages on creation', () {
      final container = makeContainer();
      final txs = container.read(transactionProvider);
      // 10 sample messages in SampleSmsService (some may fail parsing → ≥ 3)
      expect(txs.length, greaterThanOrEqualTo(3));
    });

    test('transactions are sorted newest first', () {
      final container = makeContainer();
      final txs = container.read(transactionProvider);
      for (int i = 0; i < txs.length - 1; i++) {
        expect(
          txs[i].dateTime.isAfter(txs[i + 1].dateTime) ||
              txs[i].dateTime.isAtSameMomentAs(txs[i + 1].dateTime),
          isTrue,
        );
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ADD FROM SMS
  // ──────────────────────────────────────────────────────────────────────────
  group('addFromSms', () {
    test('adds a valid SMS to the list', () {
      final container = makeContainer();
      final before = container.read(transactionProvider).length;

      container.read(transactionProvider.notifier).addFromSms(
        'LKR 500.00 debited from AC **9999 via POS at NEW SHOP 123456\n01/04/2026 10:00:00',
      );

      final after = container.read(transactionProvider).length;
      expect(after, equals(before + 1));
    });

    test('ignores invalid SMS', () {
      final container = makeContainer();
      final before = container.read(transactionProvider).length;

      container
          .read(transactionProvider.notifier)
          .addFromSms('This is not a bank message');

      expect(container.read(transactionProvider).length, equals(before));
    });

    test('new transaction appears at the front when newest', () {
      final container = makeContainer();

      container.read(transactionProvider.notifier).addFromSms(
        'LKR 999.00 debited from AC **0001 via POS at FUTURE SHOP 000001\n31/12/2099 23:59:59',
      );

      final txs = container.read(transactionProvider);
      expect(txs.first.accountRef, equals('**0001'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE CATEGORY
  // ──────────────────────────────────────────────────────────────────────────
  group('updateCategory', () {
    test('updates category for correct id', () {
      final container = makeContainer();
      final txs = container.read(transactionProvider);
      final target = txs.first;
      final newCat = target.category == TransactionCategory.transport
          ? TransactionCategory.other
          : TransactionCategory.transport;

      container
          .read(transactionProvider.notifier)
          .updateCategory(target.id, newCat);

      final updated = container
          .read(transactionProvider)
          .firstWhere((t) => t.id == target.id);
      expect(updated.category, equals(newCat));
    });

    test('does not affect other transactions', () {
      final container = makeContainer();
      final txs = container.read(transactionProvider);
      if (txs.length < 2) return; // skip if not enough data

      final target = txs[0];
      final other = txs[1];

      container
          .read(transactionProvider.notifier)
          .updateCategory(target.id, TransactionCategory.other);

      final otherAfter = container
          .read(transactionProvider)
          .firstWhere((t) => t.id == other.id);
      expect(otherAfter.category, equals(other.category));
    });

    test('list length stays the same after category update', () {
      final container = makeContainer();
      final before = container.read(transactionProvider).length;
      final id = container.read(transactionProvider).first.id;

      container
          .read(transactionProvider.notifier)
          .updateCategory(id, TransactionCategory.shopping);

      expect(container.read(transactionProvider).length, equals(before));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DERIVED PROVIDERS
  // ──────────────────────────────────────────────────────────────────────────
  group('Derived providers', () {
    test('totalExpensesProvider sums only expenses', () {
      final container = makeContainer();
      final txs = container.read(transactionProvider);
      final expected = txs
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      expect(container.read(totalExpensesProvider), closeTo(expected, 0.01));
    });

    test('totalIncomeProvider sums only income', () {
      final container = makeContainer();
      final txs = container.read(transactionProvider);
      final expected = txs
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      expect(container.read(totalIncomeProvider), closeTo(expected, 0.01));
    });

    test('derived totals update after adding a new debit', () {
      final container = makeContainer();
      final before = container.read(totalExpensesProvider);

      container.read(transactionProvider.notifier).addFromSms(
        'LKR 1,000.00 debited from AC **1234 via POS at TEST STORE 999\n01/01/2026 12:00:00',
      );

      final after = container.read(totalExpensesProvider);
      expect(after, closeTo(before + 1000.00, 0.01));
    });

    test('derived totals update after adding a new credit', () {
      final container = makeContainer();
      final before = container.read(totalIncomeProvider);

      container.read(transactionProvider.notifier).addFromSms(
        'LKR 50,000.00 credited to AC **5678 Bonus payment\n01/01/2026 09:00:00',
      );

      final after = container.read(totalIncomeProvider);
      expect(after, closeTo(before + 50000.00, 0.01));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // RELOAD
  // ──────────────────────────────────────────────────────────────────────────
  group('reload', () {
    test('resets to original sample count after adding', () {
      final container = makeContainer();
      final original = container.read(transactionProvider).length;

      container.read(transactionProvider.notifier).addFromSms(
        'LKR 200.00 debited from AC **3333 via POS at EXTRA SHOP 111\n01/04/2026 08:00:00',
      );
      expect(container.read(transactionProvider).length, equals(original + 1));

      container.read(transactionProvider.notifier).reload();
      expect(container.read(transactionProvider).length, equals(original));
    });
  });
}
