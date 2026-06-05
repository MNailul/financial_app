class Reminder {
  final int? id;
  final String title;
  final bool isDone;

  Reminder({this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_done': isDone ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      isDone: map['is_done'] == 1,
    );
  }
}
