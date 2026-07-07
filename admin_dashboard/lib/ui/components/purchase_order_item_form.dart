import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'base_modal.dart';
import 'foreign_key_autocomplete.dart';

class PurchaseOrderItemForm extends ConsumerStatefulWidget {
  const PurchaseOrderItemForm({super.key});

  @override
  ConsumerState<PurchaseOrderItemForm> createState() =>
      _PurchaseOrderItemFormState();
}

class _PurchaseOrderItemFormState extends ConsumerState<PurchaseOrderItemForm> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController(
    text: (DateTime.now().millisecondsSinceEpoch % 100000).toString(),
  );
  final _orderIdCtrl = TextEditingController();
  final _itemIdCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final item = PurchaseOrderItem(
        orderItemID: int.parse(_idCtrl.text),
        orderID: int.parse(_orderIdCtrl.text),
        itemID: int.parse(_itemIdCtrl.text),
        quantityOrdered: int.parse(_qtyCtrl.text),
        negotiatedPrice: double.parse(_priceCtrl.text),
      );

      final success = await ref
          .read(purchaseOrderItemsProvider.notifier)
          .create(item);

      if (mounted) {
        if (success) {
          showMonochromaticToast(context, 'Order Item created successfully!');
          Navigator.of(context).pop();
        } else {
          showMonochromaticToast(
            context,
            'Failed to create Order Item.',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(purchaseOrdersProvider).value ?? [];
    final items = ref.watch(inventoryItemsProvider).value ?? [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _idCtrl,
            decoration: const InputDecoration(
              labelText: 'Order Item ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ForeignKeyAutocomplete<PurchaseOrder>(
            items: orders,
            displayStringForOption: (o) => '${o.orderID} - ${o.orderDate}',
            idForOption: (o) => o.orderID.toString(),
            controller: _orderIdCtrl,
            labelText: 'Order',
          ),
          const SizedBox(height: 16),
          ForeignKeyAutocomplete<InventoryItem>(
            items: items,
            displayStringForOption: (i) => '${i.itemID} - ${i.name}',
            idForOption: (i) => i.itemID.toString(),
            controller: _itemIdCtrl,
            labelText: 'Inventory Item',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(
              labelText: 'Quantity Ordered',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceCtrl,
            decoration: const InputDecoration(
              labelText: 'Negotiated Price',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryText,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Save Order Item',
              style: TextStyle(color: AppTheme.background, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
