import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stats_viewmodel.dart';
import '../viewmodels/habit_viewmodel.dart';

/// Analytics & Progress Dashboard featuring an interactive 4-week consistency heatmap,
/// animated cubic trendlines, 7-day bar charts, and category allocation.
class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  int _selectedChartTab = 0; // 0: 7-Day Bar Chart, 1: 30-Day Trend Curve

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsViewModel>().loadAnalytics();
    });
  }

  void _showHeatmapCellDetails(BuildContext context, HeatmapDayCell cell) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(cell.date);
    final pct = (cell.intensity * 100).toInt();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(DateFormat('MMM d, yyyy').format(cell.date), style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Habits Completed:'),
                Text('${cell.completionCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Completion Ratio:'),
                Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsVm = context.watch<StatsViewModel>();
    final habitVm = context.watch<HabitViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => statsVm.loadAnalytics(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => statsVm.loadAnalytics(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. High-Level Summary Metric Cards
            _buildSummaryRow(statsVm, isDark),
            const SizedBox(height: 20),

            // 2. Trend & Bar Chart with Tab Switcher
            _buildChartSwitcher(isDark),
            const SizedBox(height: 12),
            if (_selectedChartTab == 0)
              _build7DayBarChart(statsVm, isDark)
            else
              _build30DayTrendLineChart(statsVm, isDark),
            const SizedBox(height: 24),

            // 3. Interactive 4-Week Consistency Heatmap (GitHub-style)
            _buildSectionHeader('4-Week Consistency Heatmap', Icons.grid_view_rounded),
            const SizedBox(height: 10),
            _buildInteractiveHeatmap(statsVm, isDark),
            const SizedBox(height: 24),

            // 4. Category Breakdown Donut Chart
            if (statsVm.categoryBreakdown.isNotEmpty) ...[
              _buildSectionHeader('Category Allocation', Icons.pie_chart_rounded),
              const SizedBox(height: 10),
              _buildCategoryPieChart(statsVm, isDark),
              const SizedBox(height: 24),
            ],

            // 5. Habit Performance Breakdown List
            _buildSectionHeader('Habit Performance Summary', Icons.leaderboard_rounded),
            const SizedBox(height: 10),
            _buildHabitPerformanceList(habitVm, statsVm, isDark),
            const SizedBox(height: 96), // Clearance for floating bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(StatsViewModel statsVm, bool isDark) {
    return Row(
      children: [
        _buildMetricCard(
          'Best Streak',
          '${statsVm.bestStreak}d',
          Icons.local_fire_department_rounded,
          const Color(0xFFF97316),
          isDark,
        ),
        const SizedBox(width: 10),
        _buildMetricCard(
          'Total Logs',
          '${statsVm.totalCompletionsAllTime}',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
          isDark,
        ),
        const SizedBox(width: 10),
        _buildMetricCard(
          'Consistency',
          '${statsVm.overallConsistency.toInt()}%',
          Icons.trending_up_rounded,
          const Color(0xFF6366F1),
          isDark,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141C2E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSwitcher(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                _selectedChartTab == 0 ? Icons.bar_chart_rounded : Icons.show_chart_rounded,
                size: 20,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _selectedChartTab == 0 ? '7-Day Completion Rates' : '30-Day Trend Curve',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              _buildTabBtn(0, '7D Bar', isDark),
              _buildTabBtn(1, '30D Trend', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBtn(int index, String title, bool isDark) {
    final isSelected = _selectedChartTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _build7DayBarChart(StatsViewModel statsVm, bool isDark) {
    final metrics = statsVm.sevenDayMetrics;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: metrics.isEmpty
          ? const Center(child: Text('No log data available'))
          : BarChart(
              BarChartData(
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = metrics[groupIndex];
                      return BarTooltipItem(
                        '${m.dayLabel}\n${(m.percentage * 100).toInt()}% (${m.completed}/${m.scheduled})',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < metrics.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              metrics[idx].dayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? const Color(0xFF26334D) : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(metrics.length, (i) {
                  final pct = metrics[i].percentage * 100;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: pct,
                        color: pct >= 80
                            ? const Color(0xFF10B981)
                            : (pct >= 50
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFF59E0B)),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
    );
  }

  Widget _build30DayTrendLineChart(StatsViewModel statsVm, bool isDark) {
    final metrics = statsVm.thirtyDayMetrics;
    if (metrics.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: Text('No 30-day log history available')),
      );
    }

    final spots = List.generate(metrics.length, (i) {
      return FlSpot(i.toDouble(), metrics[i].percentage * 100);
    });

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx >= 0 && idx < metrics.length) {
                    final m = metrics[idx];
                    return LineTooltipItem(
                      '${DateFormat('MMM d').format(m.date)}\n${spot.y.toInt()}% (${m.completed}/${m.scheduled})',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (val) => FlLine(
              color: isDark ? const Color(0xFF26334D) : const Color(0xFFF1F5F9),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (val, meta) {
                  return Text(
                    '${val.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < metrics.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('M/d').format(metrics[idx].date),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF10B981),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF10B981),
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.2),
                    const Color(0xFF10B981).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveHeatmap(StatsViewModel statsVm, bool isDark) {
    final cells = statsVm.heatmapCells;
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Daily Activity Matrix (Last 28 Days)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tap cell for details',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Days of week header labels (Mon -> Sun)
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // 4 rows x 7 columns grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final cell = cells[index];
              Color cellColor;
              if (cell.intensity == 0.0) {
                cellColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
              } else if (cell.intensity < 0.35) {
                cellColor = const Color(0xFF10B981).withValues(alpha: 0.35);
              } else if (cell.intensity < 0.70) {
                cellColor = const Color(0xFF10B981).withValues(alpha: 0.65);
              } else {
                cellColor = const Color(0xFF10B981);
              }

              return Tooltip(
                message:
                    '${DateFormat('MMM d').format(cell.date)}: ${cell.completionCount} completed',
                child: InkWell(
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => _showHeatmapCellDetails(context, cell),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${cell.date.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cell.intensity > 0.5 ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Legend row with 5 intensity levels
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(width: 4),
              _buildLegendDot(isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              _buildLegendDot(const Color(0xFF10B981).withValues(alpha: 0.35)),
              _buildLegendDot(const Color(0xFF10B981).withValues(alpha: 0.65)),
              _buildLegendDot(const Color(0xFF10B981)),
              const SizedBox(width: 4),
              Text('More', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 11,
      height: 11,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }

  Widget _buildCategoryPieChart(StatsViewModel statsVm, bool isDark) {
    final breakdown = statsVm.categoryBreakdown;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Donut Chart
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: breakdown.map((b) {
                  return PieChartSectionData(
                    value: b.count.toDouble(),
                    color: b.color,
                    radius: 26,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Legend list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: breakdown.map((b) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: b.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.category,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${b.count}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitPerformanceList(
      HabitViewModel habitVm, StatsViewModel statsVm, bool isDark) {
    final habits = habitVm.habitsWithLogs.map((h) => h.habit).toList();

    if (habits.isEmpty) {
      return const Center(child: Text('No habits created yet.'));
    }

    return Column(
      children: habits.map((habit) {
        final stats = statsVm.habitStats[habit.id];
        final rate = stats != null ? (stats.completionRate30Days * 100).toInt() : 0;
        final color = Color(habit.colorValue);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Streak: ${stats?.currentStreak ?? 0}d  •  Best: ${stats?.longestStreak ?? 0}d  •  Total: ${stats?.totalCompletions ?? 0}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$rate%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
