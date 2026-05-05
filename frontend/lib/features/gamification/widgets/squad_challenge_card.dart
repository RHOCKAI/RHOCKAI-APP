import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/constants/exercises.dart';

class SquadChallengeCard extends StatefulWidget {
  const SquadChallengeCard({super.key});

  @override
  State<SquadChallengeCard> createState() => _SquadChallengeCardState();
}

class _SquadChallengeCardState extends State<SquadChallengeCard> {
  void _openChallengeCreator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ChallengeCreatorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openChallengeCreator(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF3366).withOpacity(0.8),
              const Color(0xFF9C27FF).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3366).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people_alt, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('SQUADS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'INVITE FRIENDS TO\nA CHALLENGE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'Rajdhani',
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a 7-day or 30-day challenge and see who dominates the leaderboard.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCreatorSheet extends StatefulWidget {
  const _ChallengeCreatorSheet();

  @override
  State<_ChallengeCreatorSheet> createState() => _ChallengeCreatorSheetState();
}

class _ChallengeCreatorSheetState extends State<_ChallengeCreatorSheet> {
  String _selectedExerciseId = 'pushup';
  String _selectedDuration = '7 Days';
  
  void _shareChallenge() {
    final exercise = Exercises.allExercises.firstWhere((e) => e.id == _selectedExerciseId, orElse: () => Exercises.allExercises.first);
    
    final inviteMessage = '''
🔥 I'm challenging you to a $_selectedDuration ${exercise.name} Challenge on Rhockai! 🔥

Can your posture and endurance beat mine? 
Download Rhockai and join my squad to start competing:
https://rhockai.com/invite?challenge=${exercise.id}&duration=${_selectedDuration.split(' ')[0]}

Let's go! 🚀
''';

    Share.share(inviteMessage);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.all(Radius.circular(2)))),
            ),
            const SizedBox(height: 24),
            const Text(
              'CREATE SQUAD CHALLENGE',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', letterSpacing: 1.5),
            ),
            const SizedBox(height: 24),
            
            const Text('SELECT EXERCISE', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141B38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedExerciseId,
                  dropdownColor: const Color(0xFF141B38),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                  items: Exercises.allExercises.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.emoji}  ${e.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedExerciseId = val);
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text('DURATION', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDurationOption('3 Days')),
                const SizedBox(width: 12),
                Expanded(child: _buildDurationOption('7 Days')),
                const SizedBox(width: 12),
                Expanded(child: _buildDurationOption('30 Days')),
              ],
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _shareChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonBlue,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('GENERATE INVITE LINK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(String duration) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = duration),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonBlue.withOpacity(0.2) : const Color(0xFF141B38),
          border: Border.all(color: isSelected ? AppTheme.neonBlue : Colors.white10),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          duration,
          style: TextStyle(
            color: isSelected ? AppTheme.neonBlue : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
