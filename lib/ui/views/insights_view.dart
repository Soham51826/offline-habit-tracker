import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/behavioral_insight.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/habit_viewmodel.dart';

class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  Color _getSeverityColor(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.urgent:
        return const Color(0xFFEF4444); // Red
      case InsightSeverity.warning:
        return const Color(0xFFF59E0B); // Amber
      case InsightSeverity.suggestion:
        return const Color(0xFF6366F1); // Indigo
      case InsightSeverity.celebration:
        return const Color(0xFF10B981); // Emerald
    }
  }

  IconData _getTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.habitStacking:
        return Icons.link_rounded;
      case InsightType.weekendSlump:
        return Icons.weekend_rounded;
      case InsightType.optimalTiming:
        return Icons.schedule_rounded;
      case InsightType.streakRisk:
        return Icons.local_fire_department_rounded;
      case InsightType.overloadWarning:
        return Icons.warning_amber_rounded;
      case InsightType.momentumMilestone:
        return Icons.celebration_rounded;
      case InsightType.recoveryOpportunity:
        return Icons.shield_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final insightsVm = context.watch<InsightsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Insights'),
        actions: [
          IconButton(
            tooltip: 'Re-run Behavioral Analysis',
            icon: insightsVm.isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: insightsVm.isAnalyzing
                ? null
                : () => insightsVm.runBehavioralAnalysis(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => insightsVm.runBehavioralAnalysis(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Momentum & Behavioral Health Score Card
            _buildMomentumHeroCard(context, insightsVm, isDark),
            const SizedBox(height: 20),

            // 2. Filter Tabs
            _buildFilterRow(insightsVm, isDark),
            const SizedBox(height: 16),

            // 3. Insight Feed
            if (insightsVm.isAnalyzing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Evaluating behavioral heuristics & neural patterns...'),
                    ],
                  ),
                ),
              )
            else if (insightsVm.filteredInsights.isEmpty)
              _buildEmptyState(context)
            else
              ...insightsVm.filteredInsights.map((insight) {
                return _buildInsightCard(context, insightsVm, insight, isDark);
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentumHeroCard(
      BuildContext context, InsightsViewModel vm, bool isDark) {
    final score = vm.momentumIndex.toInt();
    String stateLabel = 'Calibrating';
    Color stateColor = const Color(0xFF6366F1);

    if (score >= 80) {
      stateLabel = 'High Automaticity & Momentum';
      stateColor = const Color(0xFF10B981);
    } else if (score >= 50) {
      stateLabel = 'Consolidating Habits';
      stateColor = const Color(0xFFF59E0B);
    } else if (score > 0) {
      stateLabel = 'Early Building Phase';
      stateColor = const Color(0xFF06B6D4);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded, color: Color(0xFF10B981), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Habit Health Index',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score / 100',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: stateColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              color: stateColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stateLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: stateColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Synthesized offline using procedural memory metrics, 30-day consistency curves, and circadian execution data.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(InsightsViewModel vm, bool isDark) {
    final filters = ['All', 'Stacking', 'Timing', 'Weekend', 'Momentum'];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = vm.filterType == f;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) => vm.setFilterType(f),
              selectedColor: const Color(0xFF10B981),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, InsightsViewModel vm,
      BehavioralInsight insight, bool isDark) {
    final color = _getSeverityColor(insight.severity);
    final icon = _getTypeIcon(insight.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Type Icon, Title, Dismiss Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Psychology Principle Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          insight.psychologyPrinciple,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => vm.dismissInsight(insight.id),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main analytical message
            Text(
              insight.message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 14),

            // Actionable Micro-Step Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIONABLE EXPERIMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          insight.actionableStep,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 54, color: Color(0xFF10B981)),
            const SizedBox(height: 14),
            const Text(
              'No Active Behavioral Alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your habits are in healthy alignment! Continue logging daily to unlock habit stacking, weekend slump detection, and circadian timing recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<HabitViewModel>().seedDemoData();
              },
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Load 21-Day Demo Data to Preview Engine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
