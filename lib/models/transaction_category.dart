class TransactionCategory {
  final int? id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String type; // 'income' or 'expense'

  TransactionCategory({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_value': colorValue,
      'type': type,
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int,
      colorValue: map['color_value'] as int,
      type: map['type'] as String,
    );
  }
}
