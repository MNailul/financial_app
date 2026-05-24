class SavingGoal {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String category;
  final int colorValue;
  final String status; // 'active' or 'completed'

  SavingGoal({
    this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.category,
    required this.colorValue,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
      'category': category,
      'color_value': colorValue,
      'status': status,
    };
  }

  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: map['id'] as int?,
      title: map['title'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      targetDate: DateTime.parse(map['target_date'] as String),
      category: map['category'] as String,
      colorValue: map['color_value'] as int,
      status: map['status'] as String? ?? 'active',
    );
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final pct = currentAmount / targetAmount;
    return pct > 1.0 ? 1.0 : pct;
  }

  bool get isCompleted => currentAmount >= targetAmount || status == 'completed';
}
