// test/sms_parser_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_finance_app/models/transaction_model.dart';
import 'package:sms_finance_app/services/sms_parser_service.dart';

void main() {
  late SmsParserService parser;

  setUp(() {
    parser = SmsParserService();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AMOUNT PARSING
  // ──────────────────────────────────────────────────────────────────────────
  group('Amount parsing', () {
    test('parses plain amount without comma', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at SOMEWHERE 10500302\n28/03/2026 14:19:13',
      );
      expect(tx, isNotNull);
      expect(tx!.amount, equals(150.00));
    });

    test('parses amount with comma separator', () {
      final tx = parser.parse(
        'LKR 1,692.00 debited from AC **1114 via POS at KEELLS SUPER 10402483\n25/03/2026 17:46:49',
      );
      expect(tx!.amount, equals(1692.00));
    });

    test('parses large amount with multiple commas', () {
      final tx = parser.parse(
        'LKR 85,000.00 credited to AC **2201 Salary Transfer from XYZ\n31/03/2026 09:00:00',
      );
      expect(tx!.amount, equals(85000.00));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // TRANSACTION TYPE
  // ──────────────────────────────────────────────────────────────────────────
  group('Transaction type', () {
    test('debited → expense', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at SHOP\n28/03/2026 14:19:13',
      );
      expect(tx!.type, equals(TransactionType.expense));
    });

    test('credited → income', () {
      final tx = parser.parse(
        'LKR 85,000.00 credited to AC **2201 Salary\n31/03/2026 09:00:00',
      );
      expect(tx!.type, equals(TransactionType.income));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ACCOUNT REFERENCE
  // ──────────────────────────────────────────────────────────────────────────
  group('Account reference', () {
    test('extracts last digits after **', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at SHOP\n28/03/2026 14:19:13',
      );
      expect(tx!.accountRef, equals('**1111'));
    });

    test('extracts 4-digit account ref', () {
      final tx = parser.parse(
        'LKR 5,970.00 debited from AC **1114 via POS at FUEL\n25/03/2026 18:58:40',
      );
      expect(tx!.accountRef, equals('**1114'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DATE & TIME
  // ──────────────────────────────────────────────────────────────────────────
  group('Date and time parsing', () {
    test('parses dd/MM/yyyy HH:mm:ss correctly', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at SHOP 999\n28/03/2026 14:19:13',
      );
      expect(tx!.dateTime.day, equals(28));
      expect(tx.dateTime.month, equals(3));
      expect(tx.dateTime.year, equals(2026));
      expect(tx.dateTime.hour, equals(14));
      expect(tx.dateTime.minute, equals(19));
      expect(tx.dateTime.second, equals(13));
    });

    test('parses different date', () {
      final tx = parser.parse(
        'LKR 1,692.00 debited from AC **1114 via POS at SUPER 999\n25/03/2026 17:46:49',
      );
      expect(tx!.dateTime.day, equals(25));
      expect(tx.dateTime.hour, equals(17));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // MERCHANT PARSING
  // ──────────────────────────────────────────────────────────────────────────
  group('Merchant parsing', () {
    test('strips trailing numeric reference from merchant', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at KOTTAWA INTERCHANGE 10500302\n28/03/2026 14:19:13',
      );
      expect(tx!.merchant, isNot(contains('10500302')));
      expect(tx.merchant.toLowerCase(), contains('kottawa interchange'));
    });

    test('title-cases merchant name', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at KEELLS SUPER 999\n28/03/2026 14:19:13',
      );
      // Should be title-cased, not all-caps
      expect(tx!.merchant, equals('Keells Super'));
    });

    test('does not include reference number in merchant', () {
      final tx = parser.parse(
        'LKR 5,970.00 debited from AC **1114 via POS at P AND B FUEL MART 10000759\n25/03/2026 18:58:40',
      );
      expect(tx!.merchant, isNot(contains('10000759')));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AUTO-CATEGORIZATION
  // ──────────────────────────────────────────────────────────────────────────
  group('Auto-categorization', () {
    test('INTERCHANGE → Transport', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at KOTTAWA INTERCHANGE 999\n28/03/2026 14:19:13',
      );
      expect(tx!.category, equals(TransactionCategory.transport));
    });

    test('KEELLS SUPER → Groceries', () {
      final tx = parser.parse(
        'LKR 1,692.00 debited from AC **1114 via POS at KEELLS SUPER 999\n25/03/2026 17:46:49',
      );
      expect(tx!.category, equals(TransactionCategory.groceries));
    });

    test('FUEL MART → Fuel', () {
      final tx = parser.parse(
        'LKR 5,970.00 debited from AC **1114 via POS at P AND B FUEL MART 999\n25/03/2026 18:58:40',
      );
      expect(tx!.category, equals(TransactionCategory.fuel));
    });

    test('credited transaction → Income category', () {
      final tx = parser.parse(
        'LKR 85,000.00 credited to AC **2201 Salary\n31/03/2026 09:00:00',
      );
      expect(tx!.category, equals(TransactionCategory.income));
    });

    test('PHARMACY → Health', () {
      final tx = parser.parse(
        'LKR 3,450.00 debited from AC **1114 via POS at OASYS PHARMACY 999\n27/03/2026 16:30:00',
      );
      expect(tx!.category, equals(TransactionCategory.health));
    });

    test('CINEMA → Entertainment', () {
      final tx = parser.parse(
        'LKR 1,100.00 debited from AC **1114 via POS at SAVOY CINEMA 999\n24/03/2026 20:00:00',
      );
      expect(tx!.category, equals(TransactionCategory.entertainment));
    });

    test('DIALOG → Utilities', () {
      final tx = parser.parse(
        'LKR 2,999.00 debited from AC **1111 via POS at DIALOG AXIATA 999\n29/03/2026 10:15:00',
      );
      expect(tx!.category, equals(TransactionCategory.utilities));
    });

    test('CAFE → Food & Dining', () {
      final tx = parser.parse(
        'LKR 2,350.00 debited from AC **1111 via POS at CAFE COURT 999\n30/03/2026 12:45:22',
      );
      expect(tx!.category, equals(TransactionCategory.food));
    });

    test('unknown merchant → Other', () {
      final tx = parser.parse(
        'LKR 500.00 debited from AC **1111 via POS at RANDOM XYZ PLACE 999\n28/03/2026 10:00:00',
      );
      expect(tx!.category, equals(TransactionCategory.other));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // INVALID / EDGE CASES
  // ──────────────────────────────────────────────────────────────────────────
  group('Edge cases and invalid input', () {
    test('returns null for empty string', () {
      expect(parser.parse(''), isNull);
    });

    test('returns null for OTP-only message', () {
      expect(
        parser.parse('Your OTP is 123456. Do not share with anyone.'),
        isNull,
      );
    });

    test('returns null for plain text', () {
      expect(parser.parse('Hello from your bank!'), isNull);
    });

    test('handles multiline message with extra info', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at KOTTAWA INTERCHANGE 10500302\n'
        '28/03/2026 14:19:13\n'
        'To Inq Call 0112303050\n'
        'Get protected - Do not Share OTP',
      );
      expect(tx, isNotNull);
      expect(tx!.amount, equals(150.00));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // MODEL: copyWith
  // ──────────────────────────────────────────────────────────────────────────
  group('TransactionModel.copyWith', () {
    test('category update via copyWith preserves other fields', () {
      final tx = parser.parse(
        'LKR 150.00 debited from AC **1111 via POS at KOTTAWA INTERCHANGE 999\n28/03/2026 14:19:13',
      )!;
      final updated = tx.copyWith(category: TransactionCategory.shopping);
      expect(updated.category, equals(TransactionCategory.shopping));
      expect(updated.amount, equals(tx.amount));
      expect(updated.merchant, equals(tx.merchant));
      expect(updated.id, equals(tx.id));
    });
  });
}
