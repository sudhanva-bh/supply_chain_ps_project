import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/agent_response.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_container.dart';

class DynamicMessageWidget extends StatelessWidget {
  final AgentResponse response;
  
  const DynamicMessageWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (response.conversationalText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: MarkdownBody(
              data: response.conversationalText,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, color: AppTheme.primaryText),
                h1: const TextStyle(color: AppTheme.primaryText),
                h2: const TextStyle(color: AppTheme.primaryText),
                h3: const TextStyle(color: AppTheme.primaryText),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                listBullet: const TextStyle(color: AppTheme.primaryText),
              ),
            ),
          ),
        _buildGraphicalPayload(context),
      ],
    );
  }

  Widget _buildGraphicalPayload(BuildContext context) {
    if (response.payload == null) return const SizedBox.shrink();

    switch (response.responseType) {
      case 'table_view':
        final tablePayload = response.payload as TableViewPayload;
        final source = _TableDataSource(tablePayload.rows);
        return GlassContainer(
          child: SizedBox(
            width: double.infinity,
            child: Theme(
              data: Theme.of(context).copyWith(
                cardColor: Colors.transparent,
                dividerColor: Colors.white24,
                textTheme: const TextTheme(bodySmall: TextStyle(color: AppTheme.secondaryText)),
                iconTheme: const IconThemeData(color: AppTheme.primaryText),
              ),
              child: PaginatedDataTable(
                columns: tablePayload.columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryText)))).toList(),
                source: source,
                rowsPerPage: 10,
                columnSpacing: 20,
                horizontalMargin: 20,
                showCheckboxColumn: false,
              ),
            ),
          ),
        );

      case 'metric_kpi_view':
        final metrics = response.payload as List<MetricKPIViewPayload>;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics.map((metric) {
            final color = _parseColor(metric.color);
            return GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric.title, style: const TextStyle(fontSize: 14, color: AppTheme.secondaryText)),
                      const SizedBox(height: 8),
                      Text(metric.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryText)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            metric.trend == 'up' ? Icons.arrow_upward : (metric.trend == 'down' ? Icons.arrow_downward : Icons.horizontal_rule),
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(metric.trend, style: TextStyle(color: color, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case 'timeline_view':
        final timeline = response.payload as List<TimelineViewPayload>;
        return GlassContainer(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final item = timeline[index];
              return ListTile(
                leading: const Icon(Icons.event_note, color: AppTheme.primaryText),
                title: Text(item.title, style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold)),
                subtitle: Text('${item.timestamp}\n${item.subtitle}', style: const TextStyle(color: AppTheme.secondaryText)),
                isThreeLine: true,
              );
            },
          ),
        );

      case 'chart_view':
        final chart = response.payload as ChartViewPayload;
        return GlassContainer(
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(chart.values.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: chart.values[i],
                          color: AppTheme.primaryText,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < chart.labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(chart.labels[value.toInt()], style: const TextStyle(color: AppTheme.secondaryText, fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(value.toStringAsFixed(0), style: const TextStyle(color: AppTheme.secondaryText, fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Color _parseColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red': return Colors.redAccent;
      case 'green': return Colors.greenAccent;
      case 'gray':
      case 'grey': return Colors.grey;
      case 'yellow': return Colors.amber;
      case 'blue': return Colors.lightBlueAccent;
      default: return AppTheme.secondaryText;
    }
  }
}

class _TableDataSource extends DataTableSource {
  final List<List<dynamic>> rows;

  _TableDataSource(this.rows);

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final row = rows[index];
    return DataRow(
      cells: row.map((cell) => DataCell(Text(cell?.toString() ?? '', style: const TextStyle(color: AppTheme.secondaryText)))).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}
