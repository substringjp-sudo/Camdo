import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_todo_sheet.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  void _openAddRoutine(BuildContext context, {TodoModel? existing}) {
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
        title: const Text('루틴 관리'),
      ),
      body: Consumer<TodoProvider>(
        builder: (ctx, provider, _) {
          final routines = provider.routineTodos;

          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat_rounded,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '루틴이 없어요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '매일 반복되는 할 일을 루틴으로 등록하세요',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAddRoutine(context),
                    icon: const Icon(Icons.add),
                    label: const Text('루틴 추가'),
                  ),
                ],
              ),
            );
          }

          // Group by completion
          final pending =
              routines.where((t) => !t.isCompleted).toList();
          final completed =
              routines.where((t) => t.isCompleted).toList();

          return Column(
            children: [
              // Stats banner
              _RoutineStatsBanner(
                total: routines.length,
                done: completed.length,
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _RoutineSectionHeader(
                          title: '오늘의 루틴',
                          count: pending.length),
                      ...pending.map((t) => TodoItemWidget(
                            todo: t,
                            onToggle: () => provider.toggleTodo(t),
                            onEdit: () =>
                                _openAddRoutine(context, existing: t),
                            onDelete: () => _confirmDelete(context, t, provider),
                          )),
                    ],
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _RoutineSectionHeader(
                          title: '완료됨',
                          count: completed.length,
                          isDone: true),
                      ...completed.map((t) => TodoItemWidget(
                            todo: t,
                            onToggle: () => provider.toggleTodo(t),
                            onEdit: () =>
                                _openAddRoutine(context, existing: t),
                            onDelete: () => _confirmDelete(context, t, provider),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddRoutine(context),
        icon: const Icon(Icons.add),
        label: const Text('루틴 추가'),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, TodoModel todo, TodoProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('루틴 삭제'),
        content: Text('"${todo.title}"을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child:
                const Text('삭제', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) await provider.deleteTodo(todo);
  }
}

class _RoutineStatsBanner extends StatelessWidget {
  final int total;
  final int done;

  const _RoutineStatsBanner({required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? done / total : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accent, Color(0xFF2BB5A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                '오늘의 루틴 현황',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$done / $total',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0
                ? '오늘 모든 루틴을 완료했어요! 🎉'
                : '${(progress * 100).toInt()}% 완료',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isDone;

  const _RoutineSectionHeader({
    required this.title,
    required this.count,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppTheme.success : AppTheme.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
