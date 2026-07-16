import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/agent_response.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_container.dart';
import '../views/agent_chat_view.dart';

// ─── Pie Chart Hover State ────────────────────────────────────────────────────

class _PieChartWidget extends StatefulWidget {
  final ChartViewPayload chart;
  const _PieChartWidget({required this.chart});

  @override
  State<_PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<_PieChartWidget> {
  int _touchedIndex = -1;

  static const List<Color> _pieColors = [
    Color(0xFF6C8EFF),
    Color(0xFF9B6CFF),
    Color(0xFF6CFFCB),
    Color(0xFFFF6C8E),
    Color(0xFFFFD06C),
    Color(0xFF6CD4FF),
    Color(0xFFFF9B6C),
    Color(0xFFB4FF6C),
  ];

  @override
  Widget build(BuildContext context) {
    final chart = widget.chart;
    final total = chart.values.fold(0.0, (a, b) => a + b);
    final hasSelection = _touchedIndex >= 0 && _touchedIndex < chart.labels.length;

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Top row: pie (centred) + info panel (fixed-size, no layout shift) ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pie – always centred in the available space
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event,
                                  PieTouchResponse? response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = response
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sectionsSpace: 3,
                            centerSpaceRadius: 48,
                            sections: List.generate(chart.values.length, (i) {
                              final isTouched = i == _touchedIndex;
                              final color = _pieColors[i % _pieColors.length];
                              return PieChartSectionData(
                                value: chart.values[i],
                                title: isTouched
                                    ? '${((chart.values[i] / total) * 100).toStringAsFixed(1)}%'
                                    : '',
                                color: isTouched
                                    ? color
                                    : color.withValues(alpha: 0.75),
                                radius: isTouched ? 72 : 58,
                                titleStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                borderSide: isTouched
                                    ? BorderSide(color: color, width: 2)
                                    : BorderSide.none,
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Info panel – always occupies the same space (no layout shift)
                  SizedBox(
                    width: 170,
                    child: AnimatedOpacity(
                      opacity: hasSelection ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasSelection
                              ? _pieColors[_touchedIndex % _pieColors.length]
                                  .withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: hasSelection
                              ? Border.all(
                                  color: _pieColors[
                                          _touchedIndex % _pieColors.length]
                                      .withValues(alpha: 0.45),
                                )
                              : Border.all(color: Colors.transparent),
                        ),
                        child: hasSelection
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chart.labels[_touchedIndex],
                                    style: TextStyle(
                                      color: _pieColors[
                                          _touchedIndex % _pieColors.length],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Value: ${chart.values[_touchedIndex].toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Share: ${((chart.values[_touchedIndex] / total) * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: AppTheme.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // ── Legend – 2-column Wrap ──
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: List.generate(chart.labels.length, (i) {
                final color = _pieColors[i % _pieColors.length];
                final isActive = i == _touchedIndex;
                return SizedBox(
                  width: 160,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isActive ? 13 : 10,
                        height: isActive ? 13 : 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          chart.labels[i],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.primaryText
                                : AppTheme.secondaryText,
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

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
                p: const TextStyle(fontSize: 15, color: AppTheme.primaryText, height: 1.6),
                h1: const TextStyle(color: AppTheme.primaryText, fontSize: 20, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: AppTheme.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: AppTheme.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
                strong: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
                listBullet: const TextStyle(color: AppTheme.secondaryText, fontSize: 15),
                code: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFF6CFFCB),
                ),
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
                rowsPerPage: tablePayload.rows.isEmpty
                    ? 1
                    : (tablePayload.rows.length < 10
                          ? tablePayload.rows.length
                          : 10),
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
        const tlAccents = [
          Color(0xFF6C8EFF),
          Color(0xFF9B6CFF),
          Color(0xFF6CFFCB),
          Color(0xFFFF6C8E),
          Color(0xFFFFD06C),
        ];
        return GlassContainer(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: timeline.length,
                itemBuilder: (context, index) {
                  final item = timeline[index];
                  final isLast = index == timeline.length - 1;
                  final accent = tlAccents[index % tlAccents.length];
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 48,
                          child: Column(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [accent, accent.withValues(alpha: 0.35)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.55),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      width: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            accent.withValues(alpha: 0.6),
                                            tlAccents[(index + 1) % tlAccents.length].withValues(alpha: 0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8, bottom: isLast ? 0 : 24),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.timestamp,
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: AppTheme.primaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    item.subtitle,
                                    style: const TextStyle(
                                      color: AppTheme.secondaryText,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
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

        if (chart.chartType == 'pie') {
          return _PieChartWidget(chart: chart);
        }

        Widget chartWidget;

        if (chart.chartType == 'line') {
          chartWidget = LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    chart.values.length,
                    (i) => FlSpot(i.toDouble(), chart.values[i]),
                  ),
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C8EFF), Color(0xFF9B6CFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF9B6CFF),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C8EFF).withValues(alpha: 0.3),
                        const Color(0xFF9B6CFF).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  shadow: const Shadow(
                    color: Color(0xFF6C8EFF),
                    blurRadius: 12,
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.surfaceVariant.withValues(alpha: 0.95),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final label = spot.x.toInt() < chart.labels.length
                          ? chart.labels[spot.x.toInt()]
                          : '';
                      return LineTooltipItem(
                        '$label\n${spot.y.toStringAsFixed(1)}',
                        const TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 && value.toInt() < chart.labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            chart.labels[value.toInt()],
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 11,
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
                    reservedSize: 44,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.dividerColor.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
            ),
          );
        } else {
          chartWidget = BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.surfaceVariant.withValues(alpha: 0.95),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = groupIndex < chart.labels.length ? chart.labels[groupIndex] : '';
                    return BarTooltipItem(
                      '$label\n${rod.toY.toStringAsFixed(1)}',
                      const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              barGroups: List.generate(chart.values.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: chart.values[i],
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C8EFF), Color(0xFF9B6CFF)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 22,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: chart.values.reduce((a, b) => a > b ? a : b) * 1.1,
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 && value.toInt() < chart.labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            chart.labels[value.toInt()],
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 11,
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
                    reservedSize: 44,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.dividerColor.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
            ),
          );
        }

        return GlassContainer(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 20, bottom: 12),
              child: chartWidget,
            ),
          ),
        );

      case 'regional_view':
        final regional = response.payload as RegionalViewPayload;
        return RegionalMapWidget(regional: regional);

      case 'kanban_view':
        final kanban = response.payload as KanbanViewPayload;
        return KanbanBoardWidget(kanban: kanban);

      case 'actionable_form_view':
        final formPayload = response.payload as ActionableFormViewPayload;
        return GlassContainer(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C8EFF), Color(0xFF9B6CFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formPayload.formTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...formPayload.fields.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: TextFormField(
                      initialValue: f.defaultValue,
                      style: const TextStyle(color: AppTheme.primaryText, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: f.label,
                        labelStyle: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppTheme.dividerColor.withValues(alpha: 0.8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C8EFF),
                            width: 1.5,
                          ),
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF6C8EFF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C8EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: Text(
                      formPayload.actionIntent,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case 'alert_anomaly_view':
        final alertsPayload = response.payload as AlertAnomalyViewPayload;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: alertsPayload.alerts.map((alert) {
            final isCritical = alert.severity == 'critical';
            final isWarning = alert.severity == 'warning';
            final color = isCritical
                ? const Color(0xFFFF5A5A)
                : isWarning
                    ? const Color(0xFFFFAA2C)
                    : const Color(0xFF6C8EFF);
            final icon = isCritical
                ? Icons.error_rounded
                : isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.info_rounded;
            final severityLabel = isCritical ? 'CRITICAL' : isWarning ? 'WARNING' : 'INFO';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                border: Border(
                  left: BorderSide(color: color, width: 4),
                  top: BorderSide(color: color.withValues(alpha: 0.25)),
                  bottom: BorderSide(color: color.withValues(alpha: 0.25)),
                  right: BorderSide(color: color.withValues(alpha: 0.25)),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          severityLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.description,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.secondaryText, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alert.suggestedAction,
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 'confirmation_view':
        final confirmation = response.payload as ConfirmationViewPayload;
        return GlassContainer(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Action Required',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            confirmation.toolName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: AppTheme.dividerColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 14),
                Text(
                  confirmation.summary,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.data_object_rounded, color: AppTheme.secondaryText, size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          'Parameters',
                          style: TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.dividerColor.withValues(alpha: 0.7),
                        ),
                      ),
                      child: SelectableText(
                        confirmation.argsJson,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF6CFFCB),
                          fontSize: 12.5,
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryText,
                        side: BorderSide(
                          color: AppTheme.dividerColor.withValues(alpha: 0.8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ref.read(chatProvider.notifier).abortAction();
                      },
                      child: const Text('Abort'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        ref.read(chatProvider.notifier).confirmAndExecuteTool(
                          confirmation.toolName,
                          confirmation.argsJson,
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Proceed', style: TextStyle(fontWeight: FontWeight.bold)),
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
        return const Color(0xFFFF5A5A);
      case 'green':
        return const Color(0xFF6CFFCB);
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'yellow':
        return const Color(0xFFFFD06C);
      case 'blue':
        return const Color(0xFF6C8EFF);
      case 'purple':
        return const Color(0xFF9B6CFF);
      case 'orange':
        return const Color(0xFFFF9B6C);
      default:
        return AppTheme.secondaryText;
    }
  }
}

// ─── Regional Map Widget ──────────────────────────────────────────────────────

class RegionalMapWidget extends StatelessWidget {
  final RegionalViewPayload regional;

  const RegionalMapWidget({super.key, required this.regional});

  // Mapping common region name keywords → approximate (x%, y%) on a 1000×500 canvas
  static const Map<String, Offset> _regionCenters = {
    'north america': Offset(0.18, 0.32),
    'usa': Offset(0.18, 0.30),
    'us': Offset(0.18, 0.30),
    'canada': Offset(0.18, 0.20),
    'latin america': Offset(0.23, 0.62),
    'south america': Offset(0.25, 0.65),
    'brazil': Offset(0.27, 0.63),
    'europe': Offset(0.49, 0.27),
    'uk': Offset(0.45, 0.24),
    'germany': Offset(0.50, 0.25),
    'france': Offset(0.47, 0.28),
    'africa': Offset(0.50, 0.58),
    'middle east': Offset(0.57, 0.40),
    'asia-pacific': Offset(0.78, 0.45),
    'asia': Offset(0.72, 0.35),
    'china': Offset(0.73, 0.33),
    'india': Offset(0.67, 0.42),
    'japan': Offset(0.83, 0.30),
    'southeast asia': Offset(0.77, 0.48),
    'oceania': Offset(0.83, 0.68),
    'australia': Offset(0.82, 0.68),
  };

  static const List<Color> _regionColors = [
    Color(0xFF6C8EFF),
    Color(0xFF9B6CFF),
    Color(0xFF6CFFCB),
    Color(0xFFFF6C8E),
    Color(0xFFFFD06C),
    Color(0xFF6CD4FF),
    Color(0xFFFF9B6C),
  ];

  Offset _resolveOffset(String regionName) {
    final lower = regionName.toLowerCase();
    for (final entry in _regionCenters.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // Fallback: hash-based position
    final hash = regionName.hashCode.abs();
    return Offset(
      0.1 + (hash % 80) / 100.0,
      0.15 + ((hash ~/ 100) % 60) / 100.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dots = regional.regions.asMap().entries.map((e) {
      return _RegionDot(
        offset: _resolveOffset(e.value.region),
        color: _regionColors[e.key % _regionColors.length],
        region: e.value,
      );
    }).toList();

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.public_rounded,
                    color: Color(0xFF6C8EFF), size: 18),
                const SizedBox(width: 8),
                Text(
                  regional.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // World Map
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFF0A0E1A),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.6,
                            child: SvgPicture.asset(
                              'assets/world_map.svg',
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF2A4060),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        ...dots.map((dot) {
                          final cx = dot.offset.dx * constraints.maxWidth;
                          final cy = dot.offset.dy * constraints.maxHeight;
                          return Positioned(
                            left: cx - 14,
                            top: cy - 20,
                            child: SizedBox(
                              width: 28,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 6,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: dot.color.withValues(alpha: 0.12),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 11,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: dot.color.withValues(alpha: 0.22),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 15,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: dot.color,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 18,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    child: Text(
                                      '${dot.region.percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: dot.color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats grid
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: regional.regions.asMap().entries.map((e) {
                final r = e.value;
                final color = _regionColors[e.key % _regionColors.length];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 5,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.region,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${r.value.toStringAsFixed(0)}  |  ${r.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionDot {
  final Offset offset; // 0..1 fractions of canvas size
  final Color color;
  final RegionalData region;
  _RegionDot({required this.offset, required this.color, required this.region});
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


class KanbanBoardWidget extends StatefulWidget {
  final KanbanViewPayload kanban;

  const KanbanBoardWidget({super.key, required this.kanban});

  @override
  State<KanbanBoardWidget> createState() => _KanbanBoardWidgetState();
}

class _KanbanBoardWidgetState extends State<KanbanBoardWidget> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Color _columnAccent(int index) {
    const accents = [
      Color(0xFF6C8EFF),
      Color(0xFFFFD06C),
      Color(0xFF6CFFCB),
      Color(0xFFFF6C8E),
      Color(0xFF9B6CFF),
    ];
    return accents[index % accents.length];
  }

  Color _parseColor(String colorStr) {
    switch (colorStr.toLowerCase().trim()) {
      case 'red':
        return const Color(0xFFFF5A5A);
      case 'green':
        return const Color(0xFF6CFFCB);
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'yellow':
        return const Color(0xFFFFD06C);
      case 'blue':
        return const Color(0xFF6C8EFF);
      case 'purple':
        return const Color(0xFF9B6CFF);
      case 'orange':
        return const Color(0xFFFF9B6C);
      default:
        return AppTheme.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 480),
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.kanban.columns
                  .asMap()
                  .entries
                  .map((entry) {
                    final colIndex = entry.key;
                    final colName = entry.value;
                    final accent = _columnAccent(colIndex);
                    final colCards = widget.kanban.cards
                        .where((c) => c.column.toLowerCase().trim() == colName.toLowerCase().trim())
                        .toList();

                    return Container(
                      width: 270,
                      margin: EdgeInsets.only(
                        right: colIndex < widget.kanban.columns.length - 1 ? 14 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Column header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: accent.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  colName.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                    fontSize: 12,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${colCards.length}',
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Cards
                          Flexible(
                            child: colCards.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text(
                                        'No items',
                                        style: TextStyle(
                                          color: AppTheme.secondaryText
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.all(10),
                                    itemCount: colCards.length,
                                    itemBuilder: (context, cardIndex) {
                                      final c = colCards[cardIndex];
                                      final cardColor = _parseColor(c.color);
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppTheme.dividerColor
                                                .withValues(alpha: 0.6),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Container(
                                                width: 4,
                                                color: cardColor,
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 12, vertical: 10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        c.title,
                                                        style: const TextStyle(
                                                          color: AppTheme.primaryText,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      if (c.subtitle.isNotEmpty) ...[
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          c.subtitle,
                                                          style: const TextStyle(
                                                            color: AppTheme.secondaryText,
                                                            fontSize: 12,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.end,
                                                        children: [
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            decoration: BoxDecoration(
                                                              color: cardColor,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
