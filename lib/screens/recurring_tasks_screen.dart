import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/task_provider.dart';

/// Manages the daily recurring task templates (proposal: repetitive MSME
/// preparation work should not be retyped every morning).
class RecurringTasksScreen extends StatelessWidget {
  const RecurringTasksScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    TaskProvider provider,
    int templateId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete_task')),
        content: Text(context.tr('delete_template_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.tr('confirm'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteTemplate(templateId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('recurring_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: provider.templates.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('recurring_empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final template = provider.templates[index];
                  final isActive = template.isActive;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? AppColors.secondaryBorder
                            : AppColors.divider,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.secondaryLight
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.repeat,
                            size: 20,
                            color: isActive
                                ? AppColors.secondaryDark
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  template.targetTime,
                                  '${template.durationMinutes} ${context.tr('minutes_short')}',
                                  if (template.assignee != null &&
                                      template.assignee!.isNotEmpty)
                                    template.assignee!,
                                ].join(' • '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (_) => provider.toggleTemplateActive(template),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          tooltip: context.tr('delete_task'),
                          onPressed: template.id == null
                              ? null
                              : () => _confirmDelete(
                                  context, provider, template.id!),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
