class MonthlyEvaluation {
  final int? id;
  final String monthYear; // Format: 'YYYY-MM'
  final String note;

  MonthlyEvaluation({this.id, required this.monthYear, required this.note});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month_year': monthYear,
      'note': note,
    };
  }

  factory MonthlyEvaluation.fromMap(Map<String, dynamic> map) {
    return MonthlyEvaluation(
      id: map['id'],
      monthYear: map['month_year'],
      note: map['note'],
    );
  }
}
