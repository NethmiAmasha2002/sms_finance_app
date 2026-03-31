// lib/services/sms_parser_service.dart

import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';

class SmsParserService {
  static const _uuid = Uuid();

  /// Parses a raw SMS/OTP bank message into a [TransactionModel].
  /// Returns null if the message does not match a known bank transaction format.
  TransactionModel? parse(String rawMessage) {
    final normalized = rawMessage.trim();

    // Try LKR debit/credit format (e.g. ComBank, HNB, Sampath)
    return _parseLkrFormat(normalized);
  }

  TransactionModel? _parseLkrFormat(String message) {
    // Regex: captures amount, debit/credit keyword, account, merchant, datetime
    final amountRegex = RegExp(
      r'LKR\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    final typeRegex = RegExp(
      r'\b(debited|credited)\b',
      caseSensitive: false,
    );

    final accountRegex = RegExp(
      r'AC\s*\*+(\d+)',
      caseSensitive: false,
    );

    final merchantRegex = RegExp(
      r'(?:via\s+\w+\s+at|at)\s+(.+?)(?:\s+\d{8,}|\s+\d{2}/\d{2}/\d{4}|$)',
      caseSensitive: false,
    );

    // Date formats: dd/MM/yyyy HH:mm:ss or dd-MM-yyyy HH:mm
    final dateRegex = RegExp(
      r'(\d{2})[/\-](\d{2})[/\-](\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?',
    );

    final amountMatch = amountRegex.firstMatch(message);
    final typeMatch = typeRegex.firstMatch(message);
    final accountMatch = accountRegex.firstMatch(message);
    final merchantMatch = merchantRegex.firstMatch(message);
    final dateMatch = dateRegex.firstMatch(message);

    if (amountMatch == null || typeMatch == null) return null;

    // Parse amount
    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return null;

    // Parse type
    final typeWord = typeMatch.group(1)!.toLowerCase();
    final type = typeWord == 'credited'
        ? TransactionType.income
        : TransactionType.expense;

    // Parse account ref
    final accountRef = accountMatch != null
        ? '**${accountMatch.group(1)}'
        : 'Unknown';

    // Parse merchant
    final rawMerchant = merchantMatch?.group(1)?.trim() ?? 'Unknown Merchant';
    final merchant = _cleanMerchant(rawMerchant);

    // Parse date/time
    DateTime dateTime = DateTime.now();
    if (dateMatch != null) {
      final day = int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      final year = int.parse(dateMatch.group(3)!);
      final hour = int.parse(dateMatch.group(4)!);
      final minute = int.parse(dateMatch.group(5)!);
      final second = dateMatch.group(6) != null
          ? int.parse(dateMatch.group(6)!)
          : 0;
      dateTime = DateTime(year, month, day, hour, minute, second);
    }

    // Auto-categorize
    final category = _categorize(merchant, type);

    return TransactionModel(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      merchant: merchant,
      dateTime: dateTime,
      category: category,
      accountRef: accountRef,
      rawMessage: message,
    );
  }

  /// Removes trailing reference numbers and normalizes merchant name
  String _cleanMerchant(String raw) {
    // Remove trailing long numeric codes (e.g. 10500302)
    var cleaned = raw.replaceAll(RegExp(r'\s+\d{6,}$'), '').trim();
    // Title case
    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Categorizes a transaction based on merchant name keywords
  TransactionCategory _categorize(String merchant, TransactionType type) {
    if (type == TransactionType.income) return TransactionCategory.income;

    final m = merchant.toLowerCase();

    if (_matchesKeywords(m, [
      'interchange', 'highway', 'toll', 'bus', 'taxi', 'uber', 'pickme',
      'train', 'railway', 'transit', 'parking',
    ])) {
      return TransactionCategory.transport;
    }

    if (_matchesKeywords(m, [
      'fuel', 'petrol', 'filling', 'fuel mart', 'lanka ioc', 'ceypetco',
      'petroleum', 'gas station',
    ])) {
      return TransactionCategory.fuel;
    }

    if (_matchesKeywords(m, [
      'super', 'supermarket', 'keells', 'cargills', 'arpico', 'laugfs',
      'grocery', 'groceries', 'market', 'food city',
    ])) {
      return TransactionCategory.groceries;
    }

    if (_matchesKeywords(m, [
      'restaurant', 'cafe', 'kfc', 'mcdonalds', 'pizza', 'burger',
      'dining', 'dine', 'bakery', 'hotel', 'bistro',
    ])) {
      return TransactionCategory.food;
    }

    if (_matchesKeywords(m, [
      'electric', 'water', 'utility', 'ceb', 'nwsdb', 'dialog', 'mobitel',
      'airtel', 'hutch', 'slt', 'broadband',
    ])) {
      return TransactionCategory.utilities;
    }

    if (_matchesKeywords(m, [
      'cinema', 'movie', 'theatre', 'netflix', 'spotify', 'youtube',
      'gaming', 'game', 'entertainment',
    ])) {
      return TransactionCategory.entertainment;
    }

    if (_matchesKeywords(m, [
      'pharmacy', 'hospital', 'clinic', 'medical', 'health', 'doctor',
      'lab', 'nawaloka', 'asiri', 'lanka hospital',
    ])) {
      return TransactionCategory.health;
    }

    if (_matchesKeywords(m, [
      'shop', 'store', 'fashion', 'clothing', 'accessories', 'mall',
      'showroom', 'boutique',
    ])) {
      return TransactionCategory.shopping;
    }

    return TransactionCategory.other;
  }

  bool _matchesKeywords(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }
}
