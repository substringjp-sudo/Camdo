import 'package:cloud_firestore/cloud_firestore.dart';

enum TodoPriority { low, medium, high }

enum RepeatType { none, daily, weekly, monthly, custom }

class TodoModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final TodoPriority priority;
  final RepeatType repeatType;
  final List<int>? repeatDays; // 0=Mon..6=Sun for weekly
  final bool isDDay; // show daily until completed
  final int? dDayTargetDays; // countdown days
  final String? category;
  final String? googleCalendarEventId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final bool isRoutine;
  final DateTime? completedAt;

  const TodoModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.dueTime,
    this.priority = TodoPriority.medium,
    this.repeatType = RepeatType.none,
    this.repeatDays,
    this.isDDay = false,
    this.dDayTargetDays,
    this.category,
    this.googleCalendarEventId,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.isRoutine = false,
    this.completedAt,
  });

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? dueTime,
    TodoPriority? priority,
    RepeatType? repeatType,
    List<int>? repeatDays,
    bool? isDDay,
    int? dDayTargetDays,
    String? category,
    String? googleCalendarEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isRoutine,
    DateTime? completedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      isDDay: isDDay ?? this.isDDay,
      dDayTargetDays: dDayTargetDays ?? this.dDayTargetDays,
      category: category ?? this.category,
      googleCalendarEventId:
          googleCalendarEventId ?? this.googleCalendarEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isRoutine: isRoutine ?? this.isRoutine,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'dueTime': dueTime != null ? Timestamp.fromDate(dueTime!) : null,
      'priority': priority.name,
      'repeatType': repeatType.name,
      'repeatDays': repeatDays,
      'isDDay': isDDay,
      'dDayTargetDays': dDayTargetDays,
      'category': category,
      'googleCalendarEventId': googleCalendarEventId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'isRoutine': isRoutine,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory TodoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      dueTime: (data['dueTime'] as Timestamp?)?.toDate(),
      priority: TodoPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TodoPriority.medium,
      ),
      repeatType: RepeatType.values.firstWhere(
        (e) => e.name == data['repeatType'],
        orElse: () => RepeatType.none,
      ),
      repeatDays: (data['repeatDays'] as List?)?.cast<int>(),
      isDDay: data['isDDay'] ?? false,
      dDayTargetDays: data['dDayTargetDays'],
      category: data['category'],
      googleCalendarEventId: data['googleCalendarEventId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      isRoutine: data['isRoutine'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Days remaining for D-Day
  int? get daysRemaining {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  // Should show in today's list (deadline not passed or is D-Day)
  bool get shouldShowToday {
    if (isCompleted) return false;
    if (isDDay || isRoutine) return true;
    if (dueDate == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return !due.isBefore(today);
  }

  // Is overdue
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }
}
