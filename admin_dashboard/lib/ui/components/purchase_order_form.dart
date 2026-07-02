import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'base_modal.dart';

class PurchaseOrderForm extends ConsumerStatefulWidget {
  const PurchaseOrderForm({super.key});

  @override
  ConsumerState<PurchaseOrderForm> createState() => _PurchaseOrderFormState();
}

class _PurchaseOrderFormState extends ConsumerState<PurchaseOrderForm> {
  final _formKey = GlobalKey<FormState>();

  final _orderIdCtrl = TextEditingController();
  final _orderDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
  final _totalCostCtrl = TextEditingController();
  final _statusCtrl = TextEditingController(text: 'PENDING');

  List<PurchaseOrderItem> _items = [];

  void _addItem() {
    setState(() {
      _items.add(PurchaseOrderItem(
        orderItemID: DateTime.now().millisecondsSinceEpoch % 100000,
        orderID: int.tryParse(_orderIdCtrl.text) ?? 0,
        itemID: 0,
        quantityOrdered: 1,
        negotiatedPrice: 0.0,
      ));
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final newOrder = PurchaseOrder(
        orderID: int.parse(_orderIdCtrl.text),
        orderDate: _orderDateCtrl.text,
        totalCost: double.parse(_totalCostCtrl.text),
        deliveryStatus: _statusCtrl.text,
        purchaseOrderItems: _items.isNotEmpty ? _items : null,
      );

      final success = await ref.read(purchaseOrdersProvider.notifier).create(newOrder);

      if (mounted) {
        if (success) {
          showMonochromaticToast(context, 'Purchase Order created successfully!');
          Navigator.of(context).pop();
        } else {
          showMonochromaticToast(context, 'Failed to create Purchase Order.', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _orderIdCtrl,
                  decoration: const InputDecoration(labelText: 'Order ID', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _orderDateCtrl,
                  decoration: const InputDecoration(labelText: 'Order Date', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _totalCostCtrl,
                  decoration: const InputDecoration(labelText: 'Total Cost', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _statusCtrl,
                  decoration: const InputDecoration(labelText: 'Delivery Status', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, color: AppTheme.background),
                label: const Text('Add Item', style: TextStyle(color: AppTheme.background)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryText),
              ),
            ],
          ),
          const Divider(),
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(child: Text('Item ID: ${item.orderItemID}')),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.itemID.toString(),
                      decoration: const InputDecoration(labelText: 'Inventory Item ID'),
                      onChanged: (val) {
                        _items[index] = PurchaseOrderItem(
                          orderItemID: item.orderItemID,
                          orderID: item.orderID,
                          itemID: int.tryParse(val) ?? 0,
                          quantityOrdered: item.quantityOrdered,
                          negotiatedPrice: item.negotiatedPrice,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.quantityOrdered.toString(),
                      decoration: const InputDecoration(labelText: 'Qty'),
                      onChanged: (val) {
                        _items[index] = PurchaseOrderItem(
                          orderItemID: item.orderItemID,
                          orderID: item.orderID,
                          itemID: item.itemID,
                          quantityOrdered: int.tryParse(val) ?? 0,
                          negotiatedPrice: item.negotiatedPrice,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.negotiatedPrice.toString(),
                      decoration: const InputDecoration(labelText: 'Price'),
                      onChanged: (val) {
                        _items[index] = PurchaseOrderItem(
                          orderItemID: item.orderItemID,
                          orderID: item.orderID,
                          itemID: item.itemID,
                          quantityOrdered: item.quantityOrdered,
                          negotiatedPrice: double.tryParse(val) ?? 0.0,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.secondaryText),
                    onPressed: () {
                      setState(() {
                        _items.removeAt(index);
                      });
                    },
                  )
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryText,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Purchase Order', style: TextStyle(color: AppTheme.background, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
