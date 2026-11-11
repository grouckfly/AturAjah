import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/priority_quadrant.dart';

/// 2x2 Interactive Eisenhower Priority Matrix Selector.
class PriorityMatrixSelector extends StatelessWidget {
  final PriorityQuadrant selectedQuadrant;
  final ValueChanged<PriorityQuadrant> onQuadrantSelected;

  const PriorityMatrixSelector({
    super.key,
    required this.selectedQuadrant,
    required this.onQuadrantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Q1 (Do First) & Q2 (Schedule)
        Row(
          children: [
            Expanded(
              child: _buildQuadrantCard(
                context: context,
                quadrant: PriorityQuadrant.doFirst,
                titleKey: 'q1_title',
                subtitleKey: 'q1_subtitle',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuadrantCard(
                context: context,
                quadrant: PriorityQuadrant.schedule,
                titleKey: 'q2_title',
                subtitleKey: 'q2_subtitle',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Bottom Row: Q3 (Delegate) & Q4 (Later)
        Row(
          children: [
            Expanded(
              child: _buildQuadrantCard(
                context: context,
                quadrant: PriorityQuadrant.delegate,
                titleKey: 'q3_title',
                subtitleKey: 'q3_subtitle',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuadrantCard(
                context: context,
                quadrant: PriorityQuadrant.later,
                titleKey: 'q4_title',
                subtitleKey: 'q4_subtitle',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuadrantCard({
    required BuildContext context,
    required PriorityQuadrant quadrant,
    required String titleKey,
    required String subtitleKey,
  }) {
    final isSelected = selectedQuadrant == quadrant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onQuadrantSelected(quadrant),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: quadrant.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? quadrant.borderColor : quadrant.borderColor.withValues(alpha: 0.3),
              width: isSelected ? 2.2 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: quadrant.borderColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with radio dot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: quadrant.indicatorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: isSelected
                        ? quadrant.indicatorColor
                        : AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                context.tr(titleKey),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle (Urgency & Importance criteria)
              Text(
                context.tr(subtitleKey),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? quadrant.indicatorColor
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
