import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/todo_model.dart';

class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      gcal.CalendarApi.calendarScope,
      gcal.CalendarApi.calendarEventsScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  gcal.CalendarApi? _calendarApi;

  bool get isSignedIn => _currentUser != null;
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initCalendarApi();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initCalendarApi();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _calendarApi = null;
  }

  Future<void> _initCalendarApi() async {
    if (_currentUser == null) return;
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient != null) {
      _calendarApi = gcal.CalendarApi(authClient);
    }
  }

  // Fetch events for a date range
  Future<List<gcal.Event>> fetchEvents({
    DateTime? timeMin,
    DateTime? timeMax,
  }) async {
    if (_calendarApi == null) return [];
    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: (timeMin ?? DateTime.now().subtract(const Duration(days: 7)))
            .toUtc(),
        timeMax: (timeMax ?? DateTime.now().add(const Duration(days: 30)))
            .toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      return [];
    }
  }

  // Create a Google Calendar event from a TodoModel
  Future<String?> createEvent(TodoModel todo) async {
    if (_calendarApi == null || todo.dueDate == null) return null;
    try {
      final startDate = todo.dueTime != null
          ? DateTime(
              todo.dueDate!.year,
              todo.dueDate!.month,
              todo.dueDate!.day,
              todo.dueTime!.hour,
              todo.dueTime!.minute,
            )
          : todo.dueDate!;

      final endDate = todo.dueTime != null
          ? startDate.add(const Duration(hours: 1))
          : todo.dueDate!.add(const Duration(days: 1));

      final event = gcal.Event(
        summary: todo.title,
        description: todo.description,
        start: gcal.EventDateTime(
          dateTime: todo.dueTime != null ? startDate.toUtc() : null,
          date: todo.dueTime == null ? DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day) : null,
        ),
        end: gcal.EventDateTime(
          dateTime: todo.dueTime != null ? endDate.toUtc() : null,
          date: todo.dueTime == null ? DateTime(endDate.year, endDate.month, endDate.day) : null,
        ),
        reminders: gcal.EventReminders(
          useDefault: false,
          overrides: [
            gcal.EventReminder(method: 'popup', minutes: 30),
            gcal.EventReminder(method: 'email', minutes: 1440),
          ],
        ),
      );

      final created = await _calendarApi!.events.insert(event, 'primary');
      return created.id;
    } catch (e) {
      return null;
    }
  }

  // Update existing event
  Future<void> updateEvent(TodoModel todo) async {
    if (_calendarApi == null ||
        todo.googleCalendarEventId == null ||
        todo.dueDate == null) return;
    try {
      final existing = await _calendarApi!.events
          .get('primary', todo.googleCalendarEventId!);
      existing.summary = todo.title;
      existing.description = todo.description;
      await _calendarApi!.events
          .update(existing, 'primary', todo.googleCalendarEventId!);
    } catch (e) {
      // Ignore update failures
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    if (_calendarApi == null) return;
    try {
      await _calendarApi!.events.delete('primary', eventId);
    } catch (e) {
      // Ignore
    }
  }
}
