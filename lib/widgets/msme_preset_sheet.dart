import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/msme_preset.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/database_helper.dart';

/// Interactive modal sheet allowing MSME owners to choose a tailored task preset
/// based on the proposal's field interview archetypes (Padang, Mixed Rice, Gorengan, Coffee Bike, Juice Shop).
class MsmePresetSheet extends StatefulWidget {
  const MsmePresetSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MsmePresetSheet(),
    );
  }

  @override
  State<MsmePresetSheet> createState() => _MsmePresetSheetState();
}

class _MsmePresetSheetState extends State<MsmePresetSheet> {
  bool _makeRecurring = true;
  bool _isApplying = false;

  Future<void> _applyPreset(MsmePreset preset) async {
    setState(() {
      _isApplying = true;
    });

    final provider = Provider.of<TaskProvider>(context, listen: false);
    final today = DatabaseHelper.todayDateString();

    for (final pt in preset.tasks) {
      await provider.addTask(
        TaskModel(
          title: pt.title,
          targetTime: pt.targetTime,
          durationMinutes: pt.durationMinutes,
          priorityQuadrant: pt.priorityQuadrant,
          assignee: pt.assignee,
          createdAt: today,
        ),
        makeRecurring: _makeRecurring,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Template "${preset.title}" (${preset.tasks.length} tugas) berhasil diterapkan!',
        ),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = MsmePreset.presets;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('preset_sheet_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        context.tr('preset_sheet_subtitle'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Recurring toggle option
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('preset_save_as_recurring'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _makeRecurring,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _makeRecurring = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Presets List
            Flexible(
              child: _isApplying
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: presets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final preset = presets[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider, width: 1.2),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: Text(
                                preset.iconEmoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              title: Text(
                                preset.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                preset.subtitle,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Divider(color: AppColors.divider, height: 1),
                                      const SizedBox(height: 10),
                                      ...preset.tasks.map(
                                        (t) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: t.priorityQuadrant.indicatorColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  t.title,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${t.targetTime} • ${t.durationMinutes}m',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _applyPreset(preset),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: Text(
                                          '${context.tr('apply_preset_cta')} (${preset.tasks.length} ${context.tr('tab_schedule').toLowerCase()})',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size.fromHeight(44),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
