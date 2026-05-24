class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final int categoryId;
  final String categoryName;
  final int categoryIconCode;
  final int categoryColorValue;
  final DateTime date;
  final String? notes;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconCode,
    required this.categoryColorValue,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon_code': categoryIconCode,
      'category_color_value': categoryColorValue,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      categoryIconCode: map['category_icon_code'] as int,
      categoryColorValue: map['category_color_value'] as int,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
