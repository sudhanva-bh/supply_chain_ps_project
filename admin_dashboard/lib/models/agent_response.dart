class TableViewPayload {
  final List<String> columns;
  final List<List<dynamic>> rows;

  TableViewPayload({required this.columns, required this.rows});

  factory TableViewPayload.fromJson(Map<String, dynamic> json) {
    return TableViewPayload(
      columns: List<String>.from(json['columns'] ?? []),
      rows: (json['rows'] as List).map((row) => List<dynamic>.from(row)).toList(),
    );
  }
}

class MetricKPIViewPayload {
  final String title;
  final String value;
  final String trend;
  final String color;

  MetricKPIViewPayload({
    required this.title,
    required this.value,
    required this.trend,
    required this.color,
  });

  factory MetricKPIViewPayload.fromJson(Map<String, dynamic> json) {
    return MetricKPIViewPayload(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      trend: json['trend'] ?? '',
      color: json['color'] ?? '',
    );
  }
}

class TimelineViewPayload {
  final String timestamp;
  final String title;
  final String subtitle;
  final String icon;

  TimelineViewPayload({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  factory TimelineViewPayload.fromJson(Map<String, dynamic> json) {
    return TimelineViewPayload(
      timestamp: json['timestamp'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class ChartViewPayload {
  final String chartType;
  final List<String> labels;
  final List<double> values;

  ChartViewPayload({
    required this.chartType,
    required this.labels,
    required this.values,
  });

  factory ChartViewPayload.fromJson(Map<String, dynamic> json) {
    return ChartViewPayload(
      chartType: json['chart_type'] ?? 'bar',
      labels: List<String>.from(json['labels'] ?? []),
      values: (json['values'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class AgentResponse {
  final String responseType;
  final String conversationalText;
  final dynamic payload;

  AgentResponse({
    required this.responseType,
    required this.conversationalText,
    this.payload,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    final type = json['response_type'] ?? 'text_only';
    final payloadJson = json['payload'];
    
    dynamic parsedPayload;
    if (payloadJson != null) {
      if (type == 'table_view') {
        parsedPayload = TableViewPayload.fromJson(payloadJson);
      } else if (type == 'metric_kpi_view') {
        parsedPayload = (payloadJson as List).map((e) => MetricKPIViewPayload.fromJson(e)).toList();
      } else if (type == 'timeline_view') {
        parsedPayload = (payloadJson as List).map((e) => TimelineViewPayload.fromJson(e)).toList();
      } else if (type == 'chart_view') {
        parsedPayload = ChartViewPayload.fromJson(payloadJson);
      }
    }

    return AgentResponse(
      responseType: type,
      conversationalText: json['conversational_text'] ?? '',
      payload: parsedPayload,
    );
  }
}
