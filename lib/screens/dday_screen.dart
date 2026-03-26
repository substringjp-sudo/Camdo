import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/add_todo_sheet.dart';

class DDayScreen extends StatelessWidget {
  const DDayScreen({super.key});

  void _openAdd(BuildContext context, {TodoModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTodoSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D-Day'),
      ),
      body: Consumer<TodoProvider>(
        builder: (ctx, provider, _) {
          final dDayItems = provider.dDayTodos;

          if (dDayItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'D-Day 항목이 없어요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '마감일을 설정하고 D-Day를 추적해보세요\n마감 전까지 매일 표시됩니다',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAdd(context),
                    icon: const Icon(Icons.add),
                    label: const Text('D-Day 추가'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            itemCount: dDayItems.length,
            itemBuilder: (_, i) => _DDayCard(
              todo: dDayItems[i],
              onEdit: () => _openAdd(context, existing: dDayItems[i]),
              onToggle: () => provider.toggleTodo(dDayItems[i]),
              onDelete: () => provider.deleteTodo(dDayItems[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('D-Day 추가'),
        backgroundColor: AppTheme.secondary,
      ),
    );
  }
}

class _DDayCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _DDayCard({
    required this.todo,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  Color get _cardColor {
    final days = todo.daysRemaining;
    if (days == null) return AppTheme.primary;
    if (days <= 0) return AppTheme.error;
    if (days <= 3) return AppTheme.warning;
    if (days <= 7) return AppTheme.secondary;
    return AppTheme.primary;
  }

  String get _dDayLabel {
    final days = todo.daysRemaining;
    if (days == null) return 'D-?';
    if (days == 0) return 'D-Day!';
    if (days > 0) return 'D-$days';
    return 'D+${-days}';
  }

  String get _subtitle {
    final days = todo.daysRemaining;
    if (days == null) return '날짜 미설정';
    if (days < 0) return '${-days}일 초과';
    if (days == 0) return '오늘이 마감일이에요!';
    if (days == 1) return '내일이 마감일이에요!';
    return '$days일 남았어요';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _cardColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_cardColor, _cardColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Decorative circle
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // D-Day counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _dDayLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          if (todo.dueDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy.M.d').format(todo.dueDate!),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (todo.category != null &&
                              todo.category!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                todo.category!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions
                    Column(
                      children: [
                        IconButton(
                          onPressed: onToggle,
                          icon: Icon(
                            todo.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
