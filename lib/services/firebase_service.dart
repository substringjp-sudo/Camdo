import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo_model.dart';
import 'notification_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notifications = NotificationService();

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference get _todosRef =>
      _db.collection('users').doc(_uid).collection('todos');

  // ─── Todos CRUD ───────────────────────────────────────────────

  Stream<List<TodoModel>> watchAllTodos() {
    return _todosRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TodoModel.fromFirestore).toList());
  }

  Stream<List<TodoModel>> watchTodayTodos() {
    return _todosRef
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(TodoModel.fromFirestore)
          .where((todo) => todo.shouldShowToday)
          .toList();
    });
  }

  Stream<List<TodoModel>> watchTodosForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);

    return _todosRef.snapshots().map((snap) {
      return snap.docs.map(TodoModel.fromFirestore).where((todo) {
        if (todo.dueDate == null) return false;
        final due = DateTime(
            todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
        return due == start;
      }).toList();
    });
  }

  Future<TodoModel> addTodo(TodoModel todo) async {
    final docRef = await _todosRef.add(todo.toFirestore());
    final created = todo.copyWith(id: docRef.id);
    if (created.dueDate != null) {
      await _notifications.scheduleTodoNotification(created);
    }
    return created;
  }

  Future<void> updateTodo(TodoModel todo) async {
    await _todosRef.doc(todo.id).update(todo.toFirestore());
    await _notifications.cancelTodoNotification(todo.id);
    if (!todo.isCompleted && todo.dueDate != null) {
      await _notifications.scheduleTodoNotification(todo);
    }
  }

  Future<void> deleteTodo(String id) async {
    await _todosRef.doc(id).delete();
    await _notifications.cancelTodoNotification(id);
  }

  Future<void> toggleTodo(TodoModel todo) async {
    final now = DateTime.now();
    final updated = todo.copyWith(
      isCompleted: !todo.isCompleted,
      updatedAt: now,
      completedAt: !todo.isCompleted ? now : null,
    );
    await _todosRef.doc(todo.id).update({
      'isCompleted': updated.isCompleted,
      'updatedAt': Timestamp.fromDate(now),
      'completedAt': updated.completedAt != null
          ? Timestamp.fromDate(updated.completedAt!)
          : null,
    });

    if (updated.isCompleted) {
      await _notifications.cancelTodoNotification(todo.id);
    } else if (todo.dueDate != null) {
      await _notifications.scheduleTodoNotification(updated);
    }

    // Handle repeat: create next occurrence
    if (updated.isCompleted && todo.repeatType != RepeatType.none) {
      await _createNextRepeatOccurrence(todo, now);
    }
  }

  Future<void> _createNextRepeatOccurrence(
      TodoModel todo, DateTime completedAt) async {
    DateTime? nextDue;
    switch (todo.repeatType) {
      case RepeatType.daily:
        nextDue = (todo.dueDate ?? completedAt).add(const Duration(days: 1));
        break;
      case RepeatType.weekly:
        nextDue = (todo.dueDate ?? completedAt).add(const Duration(days: 7));
        break;
      case RepeatType.monthly:
        final base = todo.dueDate ?? completedAt;
        nextDue = DateTime(base.year, base.month + 1, base.day);
        break;
      default:
        return;
    }

    final next = TodoModel(
      id: '',
      title: todo.title,
      description: todo.description,
      isCompleted: false,
      dueDate: nextDue,
      dueTime: todo.dueTime,
      priority: todo.priority,
      repeatType: todo.repeatType,
      repeatDays: todo.repeatDays,
      isDDay: todo.isDDay,
      dDayTargetDays: todo.dDayTargetDays,
      category: todo.category,
      isRoutine: todo.isRoutine,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: _uid,
    );
    await addTodo(next);
  }

  // ─── Routines ─────────────────────────────────────────────────

  Stream<List<TodoModel>> watchRoutines() {
    return _todosRef
        .where('isRoutine', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(TodoModel.fromFirestore).toList());
  }

  // ─── D-Day items ──────────────────────────────────────────────

  Stream<List<TodoModel>> watchDDayItems() {
    return _todosRef
        .where('isDDay', isEqualTo: true)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs.map(TodoModel.fromFirestore).toList());
  }

  // ─── Auth ─────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
