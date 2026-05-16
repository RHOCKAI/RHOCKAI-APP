import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/core/config/app_theme.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  final List<Map<String, dynamic>> _flaggedClients = [
    {
      'name': 'David',
      'reason': 'Form Degradation (Lower Back)',
      'severity': 'High',
      'last_active': 'Today',
    },
    {
      'name': 'Sarah',
      'reason': 'Low Readiness Score',
      'severity': 'Medium',
      'last_active': 'Yesterday',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('PT Command Center', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _flaggedClients.isEmpty
          ? Center(
              child: Text(
                'All clients are performing optimally.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _flaggedClients.length,
              itemBuilder: (context, index) {
                final client = _flaggedClients[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: client['severity'] == 'High' 
                          ? AppTheme.neonOrange.withValues(alpha: 0.2) 
                          : AppTheme.neonBlue.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: client['severity'] == 'High' ? AppTheme.neonOrange : AppTheme.neonBlue,
                      ),
                    ),
                    title: Text(
                      client['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Issue: ${client['reason']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last Active: ${client['last_active']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonBlue,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Message'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
