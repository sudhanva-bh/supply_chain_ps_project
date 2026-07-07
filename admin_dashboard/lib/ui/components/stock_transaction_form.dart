import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'base_modal.dart';
import 'foreign_key_autocomplete.dart';

class StockTransactionForm extends ConsumerStatefulWidget {
  const StockTransactionForm({super.key});

  @override
  ConsumerState<StockTransactionForm> createState() => _StockTransactionFormState();
}

class _StockTransactionFormState extends ConsumerState<StockTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController(text: (DateTime.now().millisecondsSinceEpoch % 100000).toString());
  final _itemIdCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _typeCtrl = TextEditingController(text: 'Inbound');

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final item = StockTransaction(
        transactionID: int.parse(_idCtrl.text),
        itemID: int.parse(_itemIdCtrl.text),
        quantityChanged: int.parse(_qtyCtrl.text),
        transactionType: _typeCtrl.text,
        timestamp: DateTime.now().toIso8601String(),
      );

      final success = await ref.read(stockTransactionsProvider.notifier).create(item);

      if (mounted) {
        if (success) {
          showMonochromaticToast(context, 'Transaction created successfully!');
          Navigator.of(context).pop();
        } else {
          showMonochromaticToast(context, 'Failed to create Transaction.', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryItemsProvider).value ?? [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _idCtrl,
            decoration: const InputDecoration(labelText: 'Transaction ID', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ForeignKeyAutocomplete<InventoryItem>(
            items: items,
            displayStringForOption: (i) => '${i.itemID} - ${i.name}',
            idForOption: (i) => i.itemID.toString(),
            controller: _itemIdCtrl,
            labelText: 'Item',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(labelText: 'Quantity Changed', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _typeCtrl.text,
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            items: ['Inbound', 'Outbound', 'Adjustment']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                _typeCtrl.text = v;
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryText,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Transaction', style: TextStyle(color: AppTheme.background, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
