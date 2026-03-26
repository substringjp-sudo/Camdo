import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../providers/calendar_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_todo_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().fetchEvents();
    });
  }

  void _openAddSheet({TodoModel? existing, DateTime? date}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTodoSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CalendarProvider, TodoProvider>(
      builder: (ctx, calProvider, todoProvider, _) {
        final selectedTodos =
            todoProvider.todosForDate(calProvider.selectedDay);
        final googleEvents =
            calProvider.eventsForDay(calProvider.selectedDay);

        return Scaffold(
          appBar: AppBar(
            title: const Text('캘린더'),
            actions: [
              if (!calProvider.isSyncEnabled)
                TextButton.icon(
                  onPressed: () => calProvider.connectGoogleCalendar(),
                  icon: const Icon(Icons.sync, color: Colors.white, size: 18),
                  label: const Text(
                    'Google 연동',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.sync_rounded, color: Colors.white),
                  onPressed: () => calProvider.fetchEvents(),
                  tooltip: '새로고침',
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Calendar
              Container(
                color: Colors.white,
                child: TableCalendar<dynamic>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100),
                  focusedDay: calProvider.focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(calProvider.selectedDay, day),
                  onDaySelected: calProvider.selectDay,
                  onPageChanged: (focusedDay) {
                    calProvider.setFocusedDay(focusedDay);
                    calProvider.fetchEvents(month: focusedDay);
                  },
                  eventLoader: (day) {
                    final todos = todoProvider.todosForDate(day);
                    final gcal = calProvider.eventsForDay(day);
                    return [...todos, ...gcal];
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    leftChevronIcon:
                        Icon(Icons.chevron_left, color: AppTheme.primary),
                    rightChevronIcon:
                        Icon(Icons.chevron_right, color: AppTheme.primary),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle:
                        const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                    markerDecoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    markerSize: 5,
                    markersMaxCount: 3,
                    weekendTextStyle:
                        const TextStyle(color: AppTheme.error),
                    outsideDaysVisible: false,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Selected day info
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      DateFormat('M월 d일 EEEE', 'ko')
                          .format(calProvider.selectedDay),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (selectedTodos.isNotEmpty)
                      Text(
                        '${selectedTodos.length}개',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),

              // Events list
              Expanded(
                child: (selectedTodos.isEmpty && googleEvents.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              '이 날은 일정이 없어요',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _openAddSheet(
                                  date: calProvider.selectedDay),
                              icon: const Icon(Icons.add),
                              label: const Text('할 일 추가'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 80),
                        children: [
                          // Google Calendar events
                          if (googleEvents.isNotEmpty) ...[
                            _EventSectionHeader(
                              title: 'Google 캘린더',
                              icon: Icons.event_rounded,
                              color: const Color(0xFF4285F4),
                            ),
                            ...googleEvents.map((e) => _GoogleEventTile(
                                event: e)),
                            const SizedBox(height: 8),
                          ],

                          // App todos
                          if (selectedTodos.isNotEmpty) ...[
                            _EventSectionHeader(
                              title: '할 일',
                              icon: Icons.check_circle_outline_rounded,
                              color: AppTheme.primary,
                            ),
                            ...selectedTodos.map((t) => TodoItemWidget(
                                  todo: t,
                                  onToggle: () =>
                                      context.read<TodoProvider>().toggleTodo(t),
                                  onEdit: () => _openAddSheet(existing: t),
                                  onDelete: () => context
                                      .read<TodoProvider>()
                                      .deleteTodo(t),
                                )),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _openAddSheet(date: calProvider.selectedDay),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _EventSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _EventSectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleEventTile extends StatelessWidget {
  final dynamic event;

  const _GoogleEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final title = event.summary ?? '(제목 없음)';
    final start = event.start?.dateTime ?? event.start?.date;
    String timeStr = '';
    if (start != null) {
      try {
        final dt = start is String ? DateTime.parse(start) : start as DateTime;
        timeStr = DateFormat('HH:mm').format(dt);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4).withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF4285F4).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded,
                color: Color(0xFF4285F4), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
