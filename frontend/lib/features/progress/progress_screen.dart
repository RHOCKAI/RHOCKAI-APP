import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'data/providers/progress_provider.dart';
import 'data/models/progress_models.dart';
import 'package:rhockai/l10n/app_localizations.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsProvider(_selectedDays));
    final chartAsync = ref.watch(progressChartProvider(_selectedDays));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progress),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            onSelected: (value) => setState(() => _selectedDays = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 Days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 Days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 Days')),
            ],
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(stats, l10n, theme),
              const SizedBox(height: 24),
              Text(
                'Activity Trend',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildChartContainer(chartAsync, theme),
              const SizedBox(height: 24),
              _buildAccuracyTrend(chartAsync, theme),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatsGrid(
      SessionStats stats, AppLocalizations l10n, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Sessions', stats.totalSessions.toString(),
            Icons.fitness_center, theme),
        _buildStatCard(
            'Total Reps', stats.totalReps.toString(), Icons.repeat, theme),
        _buildStatCard('Calories', stats.totalCalories.toString(),
            Icons.local_fire_department, theme),
        _buildStatCard('Accuracy', '${stats.averageAccuracy}%',
            Icons.check_circle_outline, theme),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(title,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
      AsyncValue<List<ProgressData>> chartData, ThemeData theme) {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: chartData.when(
        data: (data) => data.isEmpty
            ? const Center(child: Text('No data for this period'))
            : LineChart(_buildMainChart(data, theme)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error loading chart')),
      ),
    );
  }

  LineChartData _buildMainChart(List<ProgressData> data, ThemeData theme) {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= data.length || value < 0) {
                return const SizedBox();
              }
              final date = DateTime.parse(data[value.toInt()].date);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 10)),
              );
            },
            interval: (data.length / 5).clamp(1, data.length).toDouble(),
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.reps.toDouble()))
              .toList(),
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyTrend(
      AsyncValue<List<ProgressData>> chartData, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accuracy Performance',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: chartData.when(
            data: (data) => BarChart(
              BarChartData(
                barGroups: data
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.accuracy,
                              color: theme.colorScheme.secondary,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ))
                    .toList(),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
            loading: () => const SizedBox(),
            error: (err, stack) => const SizedBox(),
          ),
        ),
      ],
    );
  }
}
