import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../components/async_data_grid.dart';

class PurchaseOrderItemsView extends ConsumerWidget {
  const PurchaseOrderItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseOrderItemsProvider);

    return AsyncDataGrid<PurchaseOrderItem>(
      asyncValue: state,
      onRefresh: () => ref.read(purchaseOrderItemsProvider.notifier).fetchData(),
      onAdd: () {
        // Show Add Modal
      },
      columns: const [
        DataColumn(label: Text('Item ID (PK)')),
        DataColumn(label: Text('Order ID')),
        DataColumn(label: Text('Inventory Item ID')),
        DataColumn(label: Text('Quantity')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Actions')),
      ],
      buildRows: (data) => data.map((item) {
        return DataRow(cells: [
          DataCell(Text(item.orderItemID.toString())),
          DataCell(Text(item.orderID.toString())),
          DataCell(Text(item.itemID.toString())),
          DataCell(Text(item.quantityOrdered.toString())),
          DataCell(Text('\$${item.negotiatedPrice.toStringAsFixed(2)}')),
          DataCell(Row(
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () {}),
            ],
          )),
        ]);
      }).toList(),
    );
  }
}
