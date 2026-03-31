// lib/widgets/add_sms_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';

class AddSmsSheet extends ConsumerStatefulWidget {
  const AddSmsSheet({super.key});

  @override
  ConsumerState<AddSmsSheet> createState() => _AddSmsSheetState();
}

class _AddSmsSheetState extends ConsumerState<AddSmsSheet> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Please paste an SMS message');
      return;
    }

    // Try parsing
    final parser = ref.read(smsParserServiceProvider);
    final result = parser.parse(text);
    if (result == null) {
      setState(() => _errorText = 'Could not parse this message. Check format.');
      return;
    }

    ref.read(transactionProvider.notifier).addFromSms(text);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction added: ${result.merchant}'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Paste Bank SMS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  'e.g. LKR 150.00 debited from AC **1111 via POS at ...',
              border: const OutlineInputBorder(),
              errorText: _errorText,
              alignLabelWithHint: true,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Parse & Add Transaction'),
            ),
          ),
        ],
      ),
    );
  }
}
