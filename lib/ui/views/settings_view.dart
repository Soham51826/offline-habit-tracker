import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/background_worker.dart';
import '../../services/notification_service.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../viewmodels/stats_viewmodel.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _backgroundWorkerEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Background WorkManager & Notification Section
          _buildSectionHeader('Background Worker & Notifications', Icons.notifications_active_rounded),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.alarm_on_rounded, color: Color(0xFF10B981)),
                  title: const Text(
                    'WorkManager Background Reminders',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Periodically inspects local SQLite database to protect active streaks and nudge pending habits.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _backgroundWorkerEnabled,
                  onChanged: (val) async {
                    setState(() => _backgroundWorkerEnabled = val);
                    if (val) {
                      await BackgroundWorkerService.instance.schedulePeriodicHabitCheck();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('WorkManager periodic habit task scheduled.')),
                        );
                      }
                    } else {
                      await BackgroundWorkerService.instance.cancelAllTasks();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('WorkManager background tasks cancelled.')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.send_rounded, color: Color(0xFF6366F1)),
                  title: const Text('Test Local Notification', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Dispatch an immediate sample behavioral nudge', style: TextStyle(fontSize: 12)),
                  trailing: TextButton(
                    onPressed: () async {
                      await NotificationService.instance.requestPermissions();
                      await NotificationService.instance.showNotification(
                        id: 999,
                        title: '🔥 Streak Defense Alert: Morning Meditation',
                        body: 'You have an active 18-day streak! Check in now to preserve your neurological momentum.',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sample notification dispatched!')),
                        );
                      }
                    },
                    child: const Text('Send Test'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Demo Data & Seeder
          _buildSectionHeader('Demo Data & Seeder', Icons.dataset_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instant 21-Day Realistic Dataset',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Loads 3 weeks of historical habit logs containing an Anchor habit (95% consistency), a Struggling habit (35%), a Weekend Slump habit, and a Circadian Friction habit. Instantly activates all behavioral heuristics, charts, and heatmap!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final habitVm = context.read<HabitViewModel>();
                        final insightsVm = context.read<InsightsViewModel>();
                        final statsVm = context.read<StatsViewModel>();

                        await habitVm.seedDemoData();
                        await insightsVm.runBehavioralAnalysis();
                        await statsVm.loadAnalytics();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF10B981),
                              content: Text('21 days of demo data seeded! Check Insights and Analytics.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text(
                        'Seed 21-Day Realistic Data',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Database Management & Reset
          _buildSectionHeader('Database Management', Icons.storage_rounded),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: const Text(
                'Clear All SQLite Data',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
              ),
              subtitle: const Text(
                'Delete all habits, logs, and behavioral insights from local storage.',
                style: TextStyle(fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: () => _confirmClearData(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
                child: const Text('Reset'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Behavioral Architecture Info
          _buildSectionHeader('Behavioral Psychology Frameworks', Icons.psychology_alt_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-Device Behavioral Rules & Heuristics:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 8),
                _PrincipleBullet(
                  title: 'James Clear: Habit Stacking & "Never Miss Twice"',
                  desc: 'Pairs weak/new habits after 80%+ anchor habits to leverage procedural memory.',
                ),
                SizedBox(height: 6),
                _PrincipleBullet(
                  title: 'BJ Fogg Tiny Habits: Ability Scaling',
                  desc: 'Detects weekend drop-offs and scales requirements to preserve consistency.',
                ),
                SizedBox(height: 6),
                _PrincipleBullet(
                  title: 'Roy Baumeister: Ego Depletion & Circadian Alignment',
                  desc: 'Correlates hourly logs to identify peak focus hours vs evening fatigue.',
                ),
                SizedBox(height: 6),
                _PrincipleBullet(
                  title: 'Daniel Kahneman: Loss Aversion & Momentum Defense',
                  desc: 'High-urgency interventions to protect streaks before the 24-hour cutoff.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Local Data?'),
        content: const Text(
          'This will wipe all SQLite tables. All tracked habits and past history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final habitVm = context.read<HabitViewModel>();
              final insightsVm = context.read<InsightsViewModel>();
              final statsVm = context.read<StatsViewModel>();

              await habitVm.clearAllData();
              await insightsVm.runBehavioralAnalysis();
              await statsVm.loadAnalytics();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database reset successfully.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Wipe'),
          ),
        ],
      ),
    );
  }
}

class _PrincipleBullet extends StatelessWidget {
  final String title;
  final String desc;

  const _PrincipleBullet({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: desc, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
