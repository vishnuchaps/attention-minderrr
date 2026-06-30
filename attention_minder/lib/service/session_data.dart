class SessionData {
  final DateTime startTime;
  final Duration totalDuration;
  final int attentionScore;
  final int distractionCount;
  final List<DistractionEvent> distractions;
  final double focusPercentage;

  SessionData({
    required this.startTime,
    required this.totalDuration,
    required this.attentionScore,
    required this.distractionCount,
    required this.distractions,
    required this.focusPercentage,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'totalDuration': totalDuration.inSeconds,
    'attentionScore': attentionScore,
    'distractionCount': distractionCount,
    'distractions': distractions.map((d) => d.toJson()).toList(),
    'focusPercentage': focusPercentage,
  };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
    startTime: DateTime.parse(json['startTime']),
    totalDuration: Duration(seconds: json['totalDuration']),
    attentionScore: json['attentionScore'],
    distractionCount: json['distractionCount'],
    distractions: (json['distractions'] as List)
        .map((d) => DistractionEvent.fromJson(d))
        .toList(),
    focusPercentage: json['focusPercentage'].toDouble(),
  );
}

class DistractionEvent {
  final DateTime timestamp;
  final Duration duration;
  final String alertLevel;

  DistractionEvent({
    required this.timestamp,
    required this.duration,
    required this.alertLevel,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inSeconds,
    'alertLevel': alertLevel,
  };

  factory DistractionEvent.fromJson(Map<String, dynamic> json) =>
      DistractionEvent(
        timestamp: DateTime.parse(json['timestamp']),
        duration: Duration(seconds: json['duration']),
        alertLevel: json['alertLevel'],
      );
}