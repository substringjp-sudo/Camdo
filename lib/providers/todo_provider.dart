import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_model.dart';
import '../services/firebase_service.dart';
import '../services/google_calendar_service.dart';
import '../services/auth_service.dart';

class TodoProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final GoogleCalendarService _calendar = GoogleCalendarService();
  final AuthService _auth = AuthService();

  List<TodoModel> _todos = [];
  List<TodoModel> _todayTodos = [];
  String _selectedCategory = 'all';
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<TodoModel>>? _todosSubscription;
  StreamSubscription<List<TodoModel>>? _todaySubscription;

  List<TodoModel> get todos => _todos;
  List<TodoModel> get todayTodos => _todayTodos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = _todos
        .where((t) => t.category != null && t.category!.isNotEmpty)
        .map((t) => t.category!)
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<TodoModel> get filteredTodos {
    if (_selectedCategory == 'all') return _todos;
    if (_selectedCategory == 'routine') {
      return _todos.where((t) => t.isRoutine).toList();
    }
    if (_selectedCategory == 'dday') {
      return _todos.where((t) => t.isDDay).toList();
    }
    return _todos.where((t) => t.category == _selectedCategory).toList();
  }

  List<TodoModel> get pendingTodos =>
      _todos.where((t) => !t.isCompleted).toList();

  List<TodoModel> get completedTodos =>
      _todos.where((t) => t.isCompleted).toList();

  List<TodoModel> get overdueTodos =>
      _todos.where((t) => t.isOverdue).toList();

  List<TodoModel> get dDayTodos =>
      _todos.where((t) => t.isDDay && !t.isCompleted).toList()
        ..sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });

  List<TodoModel> get routineTodos =>
      _todos.where((t) => t.isRoutine).toList();

  List<TodoModel> todosForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _todos.where((todo) {
      if (todo.dueDate == null) return false;
      final due = DateTime(
          todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return due == d;
    }).toList();
  }

  void startListening() {
    _todosSubscription?.cancel();
    _todaySubscription?.cancel();

    _todosSubscription = _firebase.watchAllTodos().listen(
      (todos) {
        _todos = todos;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    _todaySubscription = _firebase.watchTodayTodos().listen(
      (todos) {
        _todayTodos = todos;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _todosSubscription?.cancel();
    _todaySubscription?.cancel();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<TodoModel?> addTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    DateTime? dueTime,
    TodoPriority priority = TodoPriority.medium,
    RepeatType repeatType = RepeatType.none,
    List<int>? repeatDays,
    bool isDDay = false,
    String? category,
    bool isRoutine = false,
    bool syncToCalendar = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid ?? 'anonymous';
      final now = DateTime.now();
      final todo = TodoModel(
        id: const Uuid().v4(),
        title: title,
        description: description,
        dueDate: dueDate,
        dueTime: dueTime,
        priority: priority,
        repeatType: repeatType,
        repeatDays: repeatDays,
        isDDay: isDDay,
        category: category,
        isRoutine: isRoutine,
        createdAt: now,
        updatedAt: now,
        userId: uid,
      );

      final created = await _firebase.addTodo(todo);

      // Sync to Google Calendar if requested
      if (syncToCalendar && _calendar.isSignedIn && dueDate != null) {
        final eventId = await _calendar.createEvent(created);
        if (eventId != null) {
          await _firebase.updateTodo(
              created.copyWith(googleCalendarEventId: eventId));
        }
      }

      _error = null;
      return created;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTodo(TodoModel todo, {bool syncToCalendar = false}) async {
    try {
      await _firebase.updateTodo(todo);

      if (syncToCalendar && _calendar.isSignedIn) {
        if (todo.googleCalendarEventId != null) {
          await _calendar.updateEvent(todo);
        } else if (todo.dueDate != null) {
          final eventId = await _calendar.createEvent(todo);
          if (eventId != null) {
            await _firebase.updateTodo(
                todo.copyWith(googleCalendarEventId: eventId));
          }
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTodo(TodoModel todo) async {
    try {
      if (todo.googleCalendarEventId != null && _calendar.isSignedIn) {
        await _calendar.deleteEvent(todo.googleCalendarEventId!);
      }
      await _firebase.deleteTodo(todo.id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTodo(TodoModel todo) async {
    try {
      await _firebase.toggleTodo(todo);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
