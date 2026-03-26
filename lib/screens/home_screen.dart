import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_todo_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddSheet({TodoModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTodoSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, TodoModel todo) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('할 일 삭제'),
        content: Text('"${todo.title}"를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child:
                const Text('삭제', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ctx.read<TodoProvider>().deleteTodo(todo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('M월 d일 EEEE', 'ko').format(now);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildAppBarBackground(dateStr),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: '오늘 할 일'),
                  Tab(text: '전체'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TodayTab(
                  onAdd: _openAddSheet,
                  onEdit: (t) => _openAddSheet(existing: t),
                  onDelete: (t) => _confirmDelete(context, t),
                ),
                _AllTab(
                  onAdd: _openAddSheet,
                  onEdit: (t) => _openAddSheet(existing: t),
                  onDelete: (t) => _confirmDelete(context, t),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('추가'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildAppBarBackground(String dateStr) {
    return Consumer2<TodoProvider, AuthProvider>(
      builder: (ctx, todoProvider, authProvider, _) {
        final total = todoProvider.todayTodos.length;
        final done = todoProvider.todayTodos.where((t) => t.isCompleted).length;
        final progress = total > 0 ? done / total : 0.0;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '안녕하세요, ${authProvider.displayName}님 👋',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (authProvider.photoUrl != null)
                        CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              NetworkImage(authProvider.photoUrl!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '$done / $total 완료',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodayTab extends StatelessWidget {
  final VoidCallback onAdd;
  final ValueChanged<TodoModel> onEdit;
  final ValueChanged<TodoModel> onDelete;

  const _TodayTab({
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (ctx, provider, _) {
        final todos = provider.todayTodos;
        final overdue = provider.overdueTodos;

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (todos.isEmpty && overdue.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: '오늘 할 일이 없어요!',
            subtitle: '+ 버튼으로 새 할 일을 추가해보세요',
            onAdd: onAdd,
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          children: [
            if (overdue.isNotEmpty) ...[
              _SectionHeader(
                title: '기한 초과 ⚠️',
                count: overdue.length,
                color: AppTheme.error,
              ),
              ...overdue.map((t) => TodoItemWidget(
                    todo: t,
                    onToggle: () => provider.toggleTodo(t),
                    onEdit: () => onEdit(t),
                    onDelete: () => onDelete(t),
                  )),
              const SizedBox(height: 8),
            ],

            // Pending todos
            ...() {
              final pending = todos.where((t) => !t.isCompleted).toList();
              if (pending.isEmpty) return <Widget>[];
              return <Widget>[
                _SectionHeader(
                  title: '할 일',
                  count: pending.length,
                  color: AppTheme.primary,
                ),
                ...pending.map((t) => TodoItemWidget(
                      todo: t,
                      onToggle: () => provider.toggleTodo(t),
                      onEdit: () => onEdit(t),
                      onDelete: () => onDelete(t),
                    )),
              ];
            }(),

            // Completed todos
            ...() {
              final completed = todos.where((t) => t.isCompleted).toList();
              if (completed.isEmpty) return <Widget>[];
              return <Widget>[
                const SizedBox(height: 8),
                _SectionHeader(
                  title: '완료됨',
                  count: completed.length,
                  color: AppTheme.success,
                ),
                ...completed.map((t) => TodoItemWidget(
                      todo: t,
                      onToggle: () => provider.toggleTodo(t),
                      onEdit: () => onEdit(t),
                      onDelete: () => onDelete(t),
                    )),
              ];
            }(),
          ],
        );
      },
    );
  }
}

class _AllTab extends StatelessWidget {
  final VoidCallback onAdd;
  final ValueChanged<TodoModel> onEdit;
  final ValueChanged<TodoModel> onDelete;

  const _AllTab({
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (ctx, provider, _) {
        final todos = provider.filteredTodos;

        return Column(
          children: [
            // Category filter
            _CategoryFilter(
              categories: ['all', 'routine', 'dday', ...provider.categories],
              selected: provider.selectedCategory,
              onSelect: provider.setCategory,
            ),

            Expanded(
              child: todos.isEmpty
                  ? _EmptyState(
                      icon: Icons.inbox_outlined,
                      title: '할 일이 없어요',
                      subtitle: '새 할 일을 추가해보세요',
                      onAdd: onAdd,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: todos.length,
                      itemBuilder: (_, i) => TodoItemWidget(
                        todo: todos[i],
                        onToggle: () => provider.toggleTodo(todos[i]),
                        onEdit: () => onEdit(todos[i]),
                        onDelete: () => onDelete(todos[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  String _label(String cat) {
    switch (cat) {
      case 'all':
        return '전체';
      case 'routine':
        return '루틴';
      case 'dday':
        return 'D-Day';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(76),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                _label(cat),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
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
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('할 일 추가'),
          ),
        ],
      ),
    );
  }
}
