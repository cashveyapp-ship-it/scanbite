class DailyTip {
  final String id;
  final String tip;
  final String category;
  final DateTime date;

  DailyTip({
    required this.id,
    required this.tip,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tip': tip,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory DailyTip.fromMap(Map<String, dynamic> map) {
    return DailyTip(
      id: map['id'] ?? '',
      tip: map['tip'] ?? '',
      category: map['category'] ?? 'general',
      date: DateTime.parse(map['date']),
    );
  }
}