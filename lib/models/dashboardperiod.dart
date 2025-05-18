enum DashboardPeriod { daily, weekly, monthly, yearly }

class Dashboard {
  final String? id;
  final String metricType;
  final num value;
  final DashboardPeriod period;
  final DateTime timeRecorded;

  Dashboard({
    this.id,
    required this.metricType,
    required this.value,
    required this.period,
    required this.timeRecorded,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    id: json['_id'] as String?,
    metricType: json['metric_type'] as String,
    value: json['value'] as num,
    period: DashboardPeriod.values.firstWhere(
            (e) => e.name == (json['period'] as String)),
    timeRecorded: DateTime.parse(json['time_recorded'] as String),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'metric_type': metricType,
    'value': value,
    'period': period.name,
    'time_recorded': timeRecorded.toIso8601String(),
  };
}