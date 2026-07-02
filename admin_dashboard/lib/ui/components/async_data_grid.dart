import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';

class AsyncDataGrid<T> extends StatelessWidget {
  final AsyncValue<List<T>> asyncValue;
  final List<DataColumn> columns;
  final List<DataRow> Function(List<T> data) buildRows;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const AsyncDataGrid({
    super.key,
    required this.asyncValue,
    required this.columns,
    required this.buildRows,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, color: AppTheme.background),
                label: const Text('Add New', style: TextStyle(color: AppTheme.background)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: asyncValue.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(child: Text('No data found.', style: TextStyle(color: AppTheme.secondaryText)));
                }
                final source = _GridDataSource(buildRows(data));
                return ListView(
                  children: [
                    PaginatedDataTable(
                      showCheckboxColumn: false,
                      columns: columns,
                      source: source,
                      rowsPerPage: 10,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryText)),
              error: (err, stack) => Center(
                child: Text('Error loading data:\n$err', style: const TextStyle(color: AppTheme.primaryText)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridDataSource extends DataTableSource {
  final List<DataRow> rows;

  _GridDataSource(this.rows);

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    return rows[index];
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}
