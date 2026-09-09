import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/user_activity.dart';
import '../../domain/emission_factors.dart';
import '../../domain/impact_calculator.dart';
import '../providers/dashboard_controller.dart';
import 'recent_activities_list.dart';

class ImpactDashboard extends ConsumerWidget {
  const ImpactDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    if (state.isLoading && state.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImpactScoreCard(context, state),
            const SizedBox(height: 24),
            _buildQuickStats(context, state),
            const SizedBox(height: 24),
            Text(
              'Your Impact Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(),
            const SizedBox(height: 16),
            _buildCategoryBreakdown(context, state),
            const SizedBox(height: 24),
            Text(
              'Suggested Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideX(),
            const SizedBox(height: 16),
            _buildSuggestedActions(context, state),
            const SizedBox(height: 24),
            const RecentActivitiesList(maxItems: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactScoreCard(BuildContext context, DashboardState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoreLabel = CarbonCalculator.getScoreLabel(state.ecoScore);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Eco Score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 70,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: Colors.white,
                          value: state.ecoScore,
                          title: '',
                          radius: 20,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: Colors.white.withOpacity(0.2),
                          value: 1000 - state.ecoScore,
                          title: '',
                          radius: 20,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.ecoScore.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        scoreLabel,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(delay: 1000.ms),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getMotivationalMessage(state.ecoScore),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildQuickStats(BuildContext context, DashboardState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Today',
            '${state.todayImpact.toStringAsFixed(1)} kg CO₂',
            Icons.today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'This Week',
            '${state.weekImpact.toStringAsFixed(1)} kg CO₂',
            Icons.calendar_view_week,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'This Month',
            '${state.monthImpact.toStringAsFixed(1)} kg CO₂',
            Icons.calendar_month,
            Colors.orange,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms);
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, DashboardState state) {
    if (state.breakdown.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No activity data yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Pie chart
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _getPieChartSections(state.breakdown),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: state.breakdown.entries.map((entry) {
            return _buildLegendItem(
              context,
              _getTypeLabel(entry.key),
              '${entry.value.toStringAsFixed(1)} kg',
              _getTypeColor(entry.key),
              _getTypeIcon(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getPieChartSections(
    Map<ActivityType, double> breakdown,
  ) {
    final total = breakdown.values.fold<double>(0, (sum, value) => sum + value.abs());
    if (total == 0) return [];

    return breakdown.entries.map((entry) {
      final percentage = (entry.value.abs() / total) * 100;
      return PieChartSectionData(
        color: _getTypeColor(entry.key),
        value: entry.value.abs(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestedActions(BuildContext context, DashboardState state) {
    final calculator = ImpactCalculator();
    final breakdown = state.breakdown.map(
      (key, value) => MapEntry(key.name, value),
    );
    final recommendations = calculator.getRecommendations(breakdown);

    if (recommendations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Keep logging activities to get personalized recommendations!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      children: recommendations.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildActionTile(
            context,
            entry.value,
            entry.key * 100,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String recommendation,
    int delay,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Implement action detail
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.eco,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideX(
          begin: 0.2,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .fadeIn();
  }

  String _getMotivationalMessage(double score) {
    if (score >= 900) {
      return '🌟 Outstanding! You\'re a sustainability champion!';
    } else if (score >= 750) {
      return '🎉 Excellent work! Keep up the great habits!';
    } else if (score >= 600) {
      return '👍 Good job! You\'re making a positive impact!';
    } else if (score >= 450) {
      return '💪 Fair progress! Small changes add up!';
    } else {
      return '🌱 Every journey starts somewhere. Keep going!';
    }
  }

  String _getTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.transport:
        return 'Transport';
      case ActivityType.diet:
        return 'Diet';
      case ActivityType.energy:
        return 'Energy';
      case ActivityType.waste:
        return 'Waste';
      case ActivityType.shopping:
        return 'Shopping';
    }
  }

  Color _getTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.transport:
        return Colors.orange;
      case ActivityType.diet:
        return Colors.green;
      case ActivityType.energy:
        return Colors.yellow[700]!;
      case ActivityType.waste:
        return Colors.brown;
      case ActivityType.shopping:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.transport:
        return Icons.directions_car;
      case ActivityType.diet:
        return Icons.restaurant;
      case ActivityType.energy:
        return Icons.bolt;
      case ActivityType.waste:
        return Icons.delete;
      case ActivityType.shopping:
        return Icons.shopping_bag;
    }
  }
}
