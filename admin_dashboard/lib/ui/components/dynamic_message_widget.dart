import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent_response.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_container.dart';
import '../views/agent_chat_view.dart';

class DynamicMessageWidget extends ConsumerWidget {
  final AgentResponse response;

  const DynamicMessageWidget({super.key, required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                strong: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
                listBullet: const TextStyle(color: AppTheme.primaryText),
              ),
            ),
          ),
        _buildGraphicalPayload(context, ref),
      ],
    );
  }

  Widget _buildGraphicalPayload(BuildContext context, WidgetRef ref) {
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
                textTheme: const TextTheme(
                  bodySmall: TextStyle(color: AppTheme.secondaryText),
                ),
                iconTheme: const IconThemeData(color: AppTheme.primaryText),
              ),
              child: PaginatedDataTable(
                columns: tablePayload.columns
                    .map(
                      (c) => DataColumn(
                        label: Text(
                          c,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                source: source,
                rowsPerPage: tablePayload.rows.isEmpty ? 1 : (tablePayload.rows.length < 10 ? tablePayload.rows.length : 10),
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
                      Text(
                        metric.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        metric.value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            metric.trend == 'up'
                                ? Icons.arrow_upward
                                : (metric.trend == 'down'
                                      ? Icons.arrow_downward
                                      : Icons.horizontal_rule),
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            metric.trend,
                            style: TextStyle(color: color, fontSize: 12),
                          ),
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                shrinkWrap: true,
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final item = timeline[index];
                final isLast = index == timeline.length - 1;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: Colors.white24,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, right: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.timestamp,
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: AppTheme.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      case 'chart_view':
        final chart = response.payload as ChartViewPayload;
        Widget chartWidget;
        if (chart.chartType == 'pie') {
          chartWidget = PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(chart.values.length, (i) {
                return PieChartSectionData(
                  value: chart.values[i],
                  title: chart.labels[i],
                  color: Colors.primaries[i % Colors.primaries.length],
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          );
        } else if (chart.chartType == 'line') {
          chartWidget = LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    chart.values.length,
                    (i) => FlSpot(i.toDouble(), chart.values[i]),
                  ),
                  isCurved: true,
                  color: AppTheme.primaryText,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryText.withValues(alpha: 0.2),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < chart.labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            chart.labels[value.toInt()],
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 10,
                            ),
                          ),
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
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          );
        } else {
          chartWidget = BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: List.generate(chart.values.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: chart.values[i],
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < chart.labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            chart.labels[value.toInt()],
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 10,
                            ),
                          ),
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
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          );
        }

        return GlassContainer(
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: chartWidget,
            ),
          ),
        );

      case 'regional_view':
        final regional = response.payload as RegionalViewPayload;
        return GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                regional.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: regional.regions
                    .map(
                      (r) => Container(
                        width: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.region,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r.value.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: r.percentage / 100,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r.percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );

      case 'kanban_view':
        final kanban = response.payload as KanbanViewPayload;
        return GlassContainer(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: kanban.columns.map((colName) {
                final colCards = kanban.cards
                    .where((c) => c.column == colName)
                    .toList();
                return Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          colName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...colCards.map(
                        (c) => Card(
                          color: _parseColor(c.color).withValues(alpha: 0.2),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              c.title,
                              style: const TextStyle(
                                color: AppTheme.primaryText,
                              ),
                            ),
                            subtitle: Text(
                              c.subtitle,
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );

      case 'actionable_form_view':
        final formPayload = response.payload as ActionableFormViewPayload;
        return GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formPayload.formTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              ...formPayload.fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: f.defaultValue,
                    style: const TextStyle(color: AppTheme.primaryText),
                    decoration: InputDecoration(
                      labelText: f.label,
                      labelStyle: const TextStyle(
                        color: AppTheme.secondaryText,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {},
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    formPayload.actionIntent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'alert_anomaly_view':
        final alertsPayload = response.payload as AlertAnomalyViewPayload;
        return Column(
          children: alertsPayload.alerts.map((alert) {
            final color = alert.severity == 'critical'
                ? Colors.redAccent
                : (alert.severity == 'warning'
                      ? Colors.orangeAccent
                      : Colors.blueAccent);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(Icons.warning, color: color),
                title: Text(
                  alert.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${alert.description}\nSuggested Action: ${alert.suggestedAction}',
                  style: const TextStyle(color: AppTheme.secondaryText),
                ),
                isThreeLine: true,
              ),
            );
          }).toList(),
        );

      case 'confirmation_view':
        final confirmation = response.payload as ConfirmationViewPayload;
        return GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Action Required: ${confirmation.toolName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  confirmation.summary,
                  style: const TextStyle(color: AppTheme.primaryText),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    confirmation.argsJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ref.read(chatProvider.notifier).abortAction();
                      },
                      child: const Text(
                        'Abort',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        ref
                            .read(chatProvider.notifier)
                            .confirmAndExecuteTool(
                              confirmation.toolName,
                              confirmation.argsJson,
                            );
                      },
                      child: const Text(
                        'Proceed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Color _parseColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red':
        return Colors.redAccent;
      case 'green':
        return Colors.greenAccent;
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'yellow':
        return Colors.amber;
      case 'blue':
        return Colors.lightBlueAccent;
      default:
        return AppTheme.secondaryText;
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
      cells: row
          .map(
            (cell) => DataCell(
              Text(
                cell?.toString() ?? '',
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}
