import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../services/google_calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  List<gcal.Event> _googleEvents = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;
  bool _isSyncEnabled = false;
  String? _error;

  List<gcal.Event> get googleEvents => _googleEvents;
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;
  bool get isSyncEnabled => _isSyncEnabled;
  bool get isCalendarSignedIn => _calendarService.isSignedIn;
  String? get error => _error;

  List<gcal.Event> eventsForDay(DateTime day) {
    return _googleEvents.where((event) {
      final start = event.start?.dateTime ?? event.start?.date;
      if (start == null) return false;
      final eventDay = DateTime(start.year, start.month, start.day);
      final checkDay = DateTime(day.year, day.month, day.day);
      return eventDay == checkDay;
    }).toList();
  }

  void selectDay(DateTime day, DateTime focusDay) {
    _selectedDay = day;
    _focusedDay = focusDay;
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  Future<bool> connectGoogleCalendar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _calendarService.signIn();
      if (success) {
        _isSyncEnabled = true;
        await fetchEvents();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnectGoogleCalendar() async {
    await _calendarService.signOut();
    _isSyncEnabled = false;
    _googleEvents = [];
    notifyListeners();
  }

  Future<void> fetchEvents({DateTime? month}) async {
    if (!_calendarService.isSignedIn) return;

    _isLoading = true;
    notifyListeners();

    try {
      final base = month ?? _focusedDay;
      final start = DateTime(base.year, base.month, 1);
      final end = DateTime(base.year, base.month + 1, 0, 23, 59, 59);

      _googleEvents = await _calendarService.fetchEvents(
        timeMin: start.subtract(const Duration(days: 7)),
        timeMax: end.add(const Duration(days: 7)),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initSilently() async {
    final success = await _calendarService.signInSilently();
    if (success) {
      _isSyncEnabled = true;
      await fetchEvents();
    }
  }
}
