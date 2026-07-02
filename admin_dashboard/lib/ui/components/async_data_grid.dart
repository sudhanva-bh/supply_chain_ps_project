import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';

class AsyncDataGrid<T> extends StatefulWidget {
  final AsyncValue<List<T>> asyncValue;
  final List<DataColumn> columns;
  final List<DataRow> Function(List<T> data) buildRows;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;
  final bool Function(T item, String query)? searchFilter;
  final Comparable Function(T item, int columnIndex)? sortValueMapper;

  const AsyncDataGrid({
    super.key,
    required this.asyncValue,
    required this.columns,
    required this.buildRows,
    required this.onRefresh,
    required this.onAdd,
    this.searchFilter,
    this.sortValueMapper,
  });

  @override
  State<AsyncDataGrid<T>> createState() => _AsyncDataGridState<T>();
}

class _AsyncDataGridState<T> extends State<AsyncDataGrid<T>> {
  String _activeSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.searchFilter != null)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
                            filled: true,
                            fillColor: AppTheme.surface.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: const TextStyle(color: AppTheme.primaryText),
                          onSubmitted: (value) {
                            setState(() {
                              _activeSearchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _activeSearchQuery = _searchController.text;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryText,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        child: const Text('Search', style: TextStyle(color: AppTheme.background)),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.onRefresh,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onAdd,
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
            child: widget.asyncValue.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(child: Text('No data found.', style: TextStyle(color: AppTheme.secondaryText)));
                }

                // Apply search filter
                List<T> filteredData = data;
                if (widget.searchFilter != null && _activeSearchQuery.isNotEmpty) {
                  filteredData = data.where((item) => widget.searchFilter!(item, _activeSearchQuery)).toList();
                }

                if (filteredData.isEmpty) {
                  return const Center(child: Text('No matching records found.', style: TextStyle(color: AppTheme.secondaryText)));
                }

                if (widget.sortValueMapper != null && _sortColumnIndex != null) {
                  filteredData.sort((a, b) {
                    final aValue = widget.sortValueMapper!(a, _sortColumnIndex!);
                    final bValue = widget.sortValueMapper!(b, _sortColumnIndex!);
                    return _sortAscending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
                  });
                }

                final source = _GridDataSource(widget.buildRows(filteredData));
                
                final sortableColumns = widget.columns.asMap().entries.map((entry) {
                  final index = entry.key;
                  final col = entry.value;
                  return DataColumn(
                    label: col.label,
                    tooltip: col.tooltip,
                    numeric: col.numeric,
                    onSort: widget.sortValueMapper != null
                        ? (columnIndex, ascending) {
                            setState(() {
                              if (_sortColumnIndex == columnIndex) {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortColumnIndex = columnIndex;
                                _sortAscending = true; // default to ascending on new column click
                              }
                            });
                          }
                        : null,
                  );
                }).toList();

                return ListView(
                  children: [
                    PaginatedDataTable(
                      showCheckboxColumn: false,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      columns: sortableColumns,
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
