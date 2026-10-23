import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';

class ChecklistCard extends StatelessWidget {
  final Map<String, bool> checklist;
  final bool editable;
  final ValueChanged<Map<String, bool>>? onChanged;
  final EdgeInsetsGeometry? padding;

  const ChecklistCard({
    super.key,
    this.checklist = const {},
    this.editable = false,
    this.onChanged,
    this.padding,
  });

  void _toggle(ChecklistItem item, bool selected) {
    if (!editable || onChanged == null) return;
    final next = Map<String, bool>.from(checklist);
    next[item.name] = selected;
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rtl_outlined, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Check-list', style: theme.textTheme.titleMedium),
                ),
                if (editable)
                  Tooltip(
                    message:
                        '${checklist.values.where((v) => v == true).length}/${ChecklistItem.values.length} confirmados',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withAlphaSafe(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${checklist.values.where((v) => v == true).length}/${ChecklistItem.values.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ChecklistItem.values.map((item) {
                final ok = checklist[item.name] == true;
                if (editable) {
                  return FilterChip(
                    label: Text(item.label),
                    selected: ok,
                    showCheckmark: true,
                    avatar: Icon(
                      ok ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: ok ? AppColors.success : theme.hintColor,
                    ),
                    selectedColor: AppColors.success.withAlphaSafe(alpha: 0.12),
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: ok
                            ? AppColors.success
                            : theme.dividerColor.withAlphaSafe(alpha: 0.8),
                        width: ok ? 1.5 : 1,
                      ),
                    ),
                    onSelected: (selected) => _toggle(item, selected),
                  );
                }
                return FilterChip(
                  label: Text(item.label),
                  selected: ok,
                  showCheckmark: false,
                  avatar: Icon(
                    ok ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: ok ? AppColors.success : theme.hintColor,
                  ),
                  selectedColor: AppColors.success.withAlphaSafe(alpha: 0.12),
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(
                      color: ok
                          ? AppColors.success
                          : theme.dividerColor.withAlphaSafe(alpha: 0.6),
                    ),
                  ),
                  onSelected: null,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (editable)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final next = <String, bool>{
                        for (final e in ChecklistItem.values) e.name: true,
                      };
                      onChanged?.call(next);
                    },
                    icon: const Icon(Icons.done_all_outlined, size: 18),
                    label: const Text('Marcar todos'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      final next = <String, bool>{
                        for (final e in ChecklistItem.values) e.name: false,
                      };
                      onChanged?.call(next);
                    },
                    icon: const Icon(Icons.restore_outlined, size: 18),
                    label: const Text('Limpar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
