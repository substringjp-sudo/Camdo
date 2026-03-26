import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../providers/calendar_provider.dart';
import '../utils/app_theme.dart';

class AddTodoSheet extends StatefulWidget {
  final TodoModel? existing;

  const AddTodoSheet({super.key, this.existing});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TodoPriority _priority = TodoPriority.medium;
  RepeatType _repeatType = RepeatType.none;
  bool _isDDay = false;
  bool _isRoutine = false;
  bool _syncToCalendar = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? '';
      _categoryCtrl.text = t.category ?? '';
      _dueDate = t.dueDate;
      _dueTime = t.dueTime != null
          ? TimeOfDay(hour: t.dueTime!.hour, minute: t.dueTime!.minute)
          : null;
      _priority = t.priority;
      _repeatType = t.repeatType;
      _isDDay = t.isDDay;
      _isRoutine = t.isRoutine;
      _syncToCalendar = t.googleCalendarEventId != null;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _dueTime = time);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TodoProvider>();
    final calProvider = context.read<CalendarProvider>();

    DateTime? dueDateTime;
    if (_dueDate != null && _dueTime != null) {
      dueDateTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
    }

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        dueDate: _dueDate,
        dueTime: dueDateTime,
        priority: _priority,
        repeatType: _repeatType,
        isDDay: _isDDay,
        isRoutine: _isRoutine,
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      await provider.updateTodo(updated,
          syncToCalendar: _syncToCalendar && calProvider.isSyncEnabled);
    } else {
      await provider.addTodo(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        dueDate: _dueDate,
        dueTime: dueDateTime,
        priority: _priority,
        repeatType: _repeatType,
        isDDay: _isDDay,
        isRoutine: _isRoutine,
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        syncToCalendar: _syncToCalendar && calProvider.isSyncEnabled,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final calProvider = context.watch<CalendarProvider>();
    final isEditing = widget.existing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      isEditing ? '할 일 편집' : '새 할 일 추가',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _submit,
                      child: const Text(
                        '저장',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleCtrl,
                          autofocus: !isEditing,
                          decoration: const InputDecoration(
                            labelText: '할 일 제목 *',
                            hintText: '무엇을 해야 하나요?',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? '제목을 입력하세요' : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: '메모 (선택)',
                            hintText: '자세한 내용을 입력하세요',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                          maxLines: 2,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Category
                        TextFormField(
                          controller: _categoryCtrl,
                          decoration: const InputDecoration(
                            labelText: '카테고리 (선택)',
                            hintText: '예: 학교, 업무, 개인...',
                            prefixIcon: Icon(Icons.label_rounded),
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),

                        // Priority
                        const Text(
                          '우선순위',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: TodoPriority.values.map((p) {
                            final colors = {
                              TodoPriority.high: AppTheme.highPriority,
                              TodoPriority.medium: AppTheme.mediumPriority,
                              TodoPriority.low: AppTheme.lowPriority,
                            };
                            final labels = {
                              TodoPriority.high: '높음',
                              TodoPriority.medium: '보통',
                              TodoPriority.low: '낮음',
                            };
                            final color = colors[p]!;
                            final isSelected = _priority == p;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _priority = p),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: color,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    labels[p]!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Due date & time
                        Row(
                          children: [
                            Expanded(
                              child: _DateTimeTile(
                                icon: Icons.calendar_today_rounded,
                                label: _dueDate != null
                                    ? DateFormat('yyyy.M.d').format(_dueDate!)
                                    : '날짜 선택',
                                isSet: _dueDate != null,
                                onTap: _pickDate,
                                onClear: _dueDate != null
                                    ? () => setState(() => _dueDate = null)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateTimeTile(
                                icon: Icons.access_time_rounded,
                                label: _dueTime != null
                                    ? _dueTime!.format(context)
                                    : '시간 선택',
                                isSet: _dueTime != null,
                                onTap: _pickTime,
                                onClear: _dueTime != null
                                    ? () => setState(() => _dueTime = null)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Repeat
                        const Text(
                          '반복',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: RepeatType.values.map((r) {
                            final labels = {
                              RepeatType.none: '없음',
                              RepeatType.daily: '매일',
                              RepeatType.weekly: '매주',
                              RepeatType.monthly: '매월',
                              RepeatType.custom: '직접 설정',
                            };
                            return ChoiceChip(
                              label: Text(labels[r]!),
                              selected: _repeatType == r,
                              onSelected: (_) =>
                                  setState(() => _repeatType = r),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: _repeatType == r
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Toggles
                        _SwitchTile(
                          icon: Icons.timer_outlined,
                          title: 'D-Day 설정',
                          subtitle: '매일 남은 날짜를 표시합니다',
                          value: _isDDay,
                          onChanged: (v) => setState(() => _isDDay = v),
                          activeColor: AppTheme.secondary,
                        ),
                        const SizedBox(height: 8),
                        _SwitchTile(
                          icon: Icons.repeat_on_rounded,
                          title: '루틴으로 설정',
                          subtitle: '매일 체크리스트에 표시됩니다',
                          value: _isRoutine,
                          onChanged: (v) => setState(() => _isRoutine = v),
                          activeColor: AppTheme.accent,
                        ),
                        if (calProvider.isSyncEnabled) ...[
                          const SizedBox(height: 8),
                          _SwitchTile(
                            icon: Icons.event_rounded,
                            title: 'Google 캘린더 동기화',
                            subtitle: '구글 캘린더에 일정을 추가합니다',
                            value: _syncToCalendar,
                            onChanged: (v) =>
                                setState(() => _syncToCalendar = v),
                            activeColor: const Color(0xFF4285F4),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.isSet,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSet
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSet ? AppTheme.primary.withOpacity(0.4) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSet ? AppTheme.primary : Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSet ? AppTheme.primary : Colors.grey.shade500,
                  fontWeight:
                      isSet ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    size: 16,
                    color: AppTheme.primary.withOpacity(0.7)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? activeColor : Colors.grey.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: value ? activeColor : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}
