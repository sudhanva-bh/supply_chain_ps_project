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

class RegionalData {
  final String region;
  final double value;
  final double percentage;

  RegionalData({required this.region, required this.value, required this.percentage});

  factory RegionalData.fromJson(Map<String, dynamic> json) {
    return RegionalData(
      region: json['region'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RegionalViewPayload {
  final String title;
  final List<RegionalData> regions;

  RegionalViewPayload({required this.title, required this.regions});

  factory RegionalViewPayload.fromJson(Map<String, dynamic> json) {
    return RegionalViewPayload(
      title: json['title'] ?? '',
      regions: (json['regions'] as List?)?.map((e) => RegionalData.fromJson(e)).toList() ?? [],
    );
  }
}

class KanbanCard {
  final String id;
  final String title;
  final String subtitle;
  final String column;
  final String color;

  KanbanCard({required this.id, required this.title, required this.subtitle, required this.column, required this.color});

  factory KanbanCard.fromJson(Map<String, dynamic> json) {
    return KanbanCard(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      column: json['column'] ?? '',
      color: json['color'] ?? '',
    );
  }
}

class KanbanViewPayload {
  final List<String> columns;
  final List<KanbanCard> cards;

  KanbanViewPayload({required this.columns, required this.cards});

  factory KanbanViewPayload.fromJson(Map<String, dynamic> json) {
    return KanbanViewPayload(
      columns: List<String>.from(json['columns'] ?? []),
      cards: (json['cards'] as List?)?.map((e) => KanbanCard.fromJson(e)).toList() ?? [],
    );
  }
}

class FormFieldSchema {
  final String name;
  final String label;
  final String fieldType;
  final String defaultValue;
  final List<String>? options;

  FormFieldSchema({required this.name, required this.label, required this.fieldType, required this.defaultValue, this.options});

  factory FormFieldSchema.fromJson(Map<String, dynamic> json) {
    return FormFieldSchema(
      name: json['name'] ?? '',
      label: json['label'] ?? '',
      fieldType: json['field_type'] ?? 'text',
      defaultValue: json['default_value'] ?? '',
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }
}

class ActionableFormViewPayload {
  final String formTitle;
  final String actionIntent;
  final List<FormFieldSchema> fields;

  ActionableFormViewPayload({required this.formTitle, required this.actionIntent, required this.fields});

  factory ActionableFormViewPayload.fromJson(Map<String, dynamic> json) {
    return ActionableFormViewPayload(
      formTitle: json['form_title'] ?? '',
      actionIntent: json['action_intent'] ?? '',
      fields: (json['fields'] as List?)?.map((e) => FormFieldSchema.fromJson(e)).toList() ?? [],
    );
  }
}

class AlertAnomaly {
  final String severity;
  final String title;
  final String description;
  final String suggestedAction;

  AlertAnomaly({required this.severity, required this.title, required this.description, required this.suggestedAction});

  factory AlertAnomaly.fromJson(Map<String, dynamic> json) {
    return AlertAnomaly(
      severity: json['severity'] ?? 'info',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      suggestedAction: json['suggested_action'] ?? '',
    );
  }
}

class AlertAnomalyViewPayload {
  final List<AlertAnomaly> alerts;

  AlertAnomalyViewPayload({required this.alerts});

  factory AlertAnomalyViewPayload.fromJson(Map<String, dynamic> json) {
    return AlertAnomalyViewPayload(
      alerts: (json['alerts'] as List?)?.map((e) => AlertAnomaly.fromJson(e)).toList() ?? [],
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
      } else if (type == 'regional_view') {
        parsedPayload = RegionalViewPayload.fromJson(payloadJson);
      } else if (type == 'kanban_view') {
        parsedPayload = KanbanViewPayload.fromJson(payloadJson);
      } else if (type == 'actionable_form_view') {
        parsedPayload = ActionableFormViewPayload.fromJson(payloadJson);
      } else if (type == 'alert_anomaly_view') {
        parsedPayload = AlertAnomalyViewPayload.fromJson(payloadJson);
      }
    }

    return AgentResponse(
      responseType: type,
      conversationalText: json['conversational_text'] ?? '',
      payload: parsedPayload,
    );
  }
}
