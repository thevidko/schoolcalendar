class Task {
  final String id;
  final String subjectId;
  final String title;
  final DateTime dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
  });
}
