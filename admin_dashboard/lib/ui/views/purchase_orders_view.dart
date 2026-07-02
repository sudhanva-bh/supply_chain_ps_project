import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../components/async_data_grid.dart';
import '../components/base_modal.dart';
import '../components/purchase_order_form.dart';

class PurchaseOrdersView extends ConsumerWidget {
  const PurchaseOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseOrdersProvider);

    return AsyncDataGrid<PurchaseOrder>(
      asyncValue: state,
      onRefresh: () => ref.read(purchaseOrdersProvider.notifier).fetchData(),
      onAdd: () {
        showGlassModal(
          context,
          title: 'Create Purchase Order',
          content: const PurchaseOrderForm(),
        );
      },
      searchFilter: (item, query) {
        final lowerQuery = query.toLowerCase();
        return item.orderID.toString().contains(lowerQuery) ||
            item.orderDate.toLowerCase().contains(lowerQuery) ||
            item.deliveryStatus.toLowerCase().contains(lowerQuery);
      },
      columns: const [
        DataColumn(label: Text('Order ID')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Total Cost')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      buildRows: (data) => data.map((item) {
        return DataRow(cells: [
          DataCell(Text(item.orderID.toString())),
          DataCell(Text(item.orderDate)),
          DataCell(Text('\$${item.totalCost.toStringAsFixed(2)}')),
          DataCell(Text(item.deliveryStatus)),
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
