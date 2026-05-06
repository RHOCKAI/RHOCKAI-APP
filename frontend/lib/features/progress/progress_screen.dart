import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'data/providers/progress_provider.dart';
import 'data/models/progress_models.dart';
import '../../core/config/app_theme.dart';
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          l10n.progress.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedDays,
                dropdownColor: const Color(0xFF141B38),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.neonBlue),
                style: const TextStyle(
                  color: AppTheme.neonBlue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 1,
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedDays = value);
                },
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 DAYS')),
                  DropdownMenuItem(value: 30, child: Text('30 DAYS')),
                  DropdownMenuItem(value: 90, child: Text('90 DAYS')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(stats, l10n),
              const SizedBox(height: 32),
              const Text(
                'ACTIVITY TREND',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              _buildChartContainer(chartAsync),
              const SizedBox(height: 32),
              const Text(
                'ACCURACY PERFORMANCE',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              _buildAccuracyTrend(chartAsync),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.neonBlue)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.neonOrange))),
      ),
    );
  }

  Widget _buildStatsGrid(SessionStats stats, AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('SESSIONS', stats.totalSessions.toString(), Icons.fitness_center, AppTheme.neonBlue),
        _buildStatCard('TOTAL REPS', stats.totalReps.toString(), Icons.repeat, AppTheme.neonGreen),
        _buildStatCard('CALORIES', stats.totalCalories.toString(), Icons.local_fire_department, AppTheme.neonOrange),
        _buildStatCard('ACCURACY', '${stats.averageAccuracy}%', Icons.check_circle_outline, AppTheme.neonPurple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani',
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontFamily: 'Rajdhani',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(AsyncValue<List<ProgressData>> chartData) {
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: chartData.when(
        data: (data) => data.isEmpty
            ? const Center(child: Text('NO DATA FOR THIS PERIOD', style: TextStyle(color: Colors.white54, fontFamily: 'Rajdhani', letterSpacing: 2)))
            : LineChart(_buildMainChart(data)),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.neonBlue)),
        error: (err, stack) => const Center(child: Text('Error loading chart', style: TextStyle(color: AppTheme.neonOrange))),
      ),
    );
  }

  LineChartData _buildMainChart(List<ProgressData> data) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withValues(alpha: 0.05),
          strokeWidth: 1,
        ),
      ),
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
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            },
            interval: (data.length / 5).clamp(1, data.length).toDouble(),
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          color: AppTheme.neonBlue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.neonBlue.withValues(alpha: 0.3),
                AppTheme.neonBlue.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyTrend(AsyncValue<List<ProgressData>> chartData) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: chartData.when(
        data: (data) => data.isEmpty
            ? const Center(child: Text('NO DATA FOR THIS PERIOD', style: TextStyle(color: Colors.white54, fontFamily: 'Rajdhani', letterSpacing: 2)))
            : BarChart(
                BarChartData(
                  barGroups: data
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.accuracy,
                                color: AppTheme.neonGreen,
                                width: 12,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 100,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen)),
        error: (err, stack) => const Center(child: Text('Error loading chart', style: TextStyle(color: AppTheme.neonOrange))),
      ),
    );
  }
}
