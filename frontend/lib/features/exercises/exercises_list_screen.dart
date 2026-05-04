import 'package:flutter/material.dart';
import '../../core/constants/exercises.dart';
import '../../features/workout/pre_workout_screen.dart';

class ExercisesListScreen extends StatefulWidget {
  const ExercisesListScreen({super.key});

  @override
  State<ExercisesListScreen> createState() => _ExercisesListScreenState();
}

class _ExercisesListScreenState extends State<ExercisesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Upper Body', 'Lower Body', 'Core', 'Full Body'];

  static const _difficultyColors = {
    'beginner': Color(0xFF00FF88),
    'intermediate': Color(0xFFFFAA00),
    'advanced': Color(0xFFFF3366),
  };

  static const _categoryFilters = {
    'All': null,
    'Upper Body': 'upper_body',
    'Lower Body': 'lower_body',
    'Core': 'core',
    'Full Body': 'full_body',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ExerciseData> _filtered(List<ExerciseData> source) {
    final catFilter = _categoryFilters[_selectedCategory];
    return source.where((e) {
      final matchQuery = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.muscleGroups.any((m) =>
              m.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchCat = catFilter == null || e.category == catFilter;
      return matchQuery && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            snap: true,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E27),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 60, bottom: 56),
              title: const Text(
                'EXERCISES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontFamily: 'Rajdhani',
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E2749), Color(0xFF0A0E27)],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00D9FF),
                indicatorWeight: 3,
                labelColor: const Color(0xFF00D9FF),
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 1.5,
                  fontSize: 13,
                ),
                tabs: [
                  _buildTab('🌱', 'BEGINNER', Exercises.beginnerExercises.length),
                  _buildTab('⚡', 'INTERMEDIATE', Exercises.intermediateExercises.length),
                  _buildTab('🔥', 'ADVANCED', Exercises.advancedExercises.length),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Search + Category row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search exercises or muscles...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white38, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00D9FF)
                                      .withOpacity(0.15)
                                  : Colors.white.withOpacity(0.04),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00D9FF)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF00D9FF)
                                    : Colors.white54,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Tabbed exercise lists
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExerciseGrid(
                      _filtered(Exercises.beginnerExercises),
                      '🌱 Beginner'),
                  _buildExerciseGrid(
                      _filtered(Exercises.intermediateExercises),
                      '⚡ Intermediate'),
                  _buildExerciseGrid(
                      _filtered(Exercises.advancedExercises),
                      '🔥 Advanced'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Tab _buildTab(String emoji, String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 9, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGrid(List<ExerciseData> exercises, String level) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'No exercises found',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
              }),
              child: const Text(
                'Clear filters',
                style: TextStyle(
                    color: Color(0xFF00D9FF),
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) =>
          _buildExerciseCard(context, exercises[index]),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseData exercise) {
    final diffColor = _difficultyColors[exercise.difficulty] ??
        const Color(0xFF00D9FF);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreWorkoutScreen(
            exerciseType: exercise.id,
            title: exercise.name,
            description: exercise.description,
            imageUrl: exercise.imageUrl,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141B38),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: diffColor.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: diffColor.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      exercise.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E2749),
                        child: Center(
                          child: Text(exercise.emoji,
                              style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: const Color(0xFF1E2749),
                          child: Center(
                            child: Text(exercise.emoji,
                                style: const TextStyle(fontSize: 40)),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                    // Difficulty badge top-right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          exercise.difficulty.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    // AI badge top-left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF00D9FF)
                                  .withOpacity(0.4)),
                        ),
                        child: const Text(
                          '🤖 AI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Rajdhani',
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          exercise.muscleGroups
                              .take(2)
                              .join(' · ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            color: diffColor.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    // Stats row
                    Row(
                      children: [
                        _statChip(
                          '${exercise.defaultReps == 1 ? "${exercise.defaultSets}x hold" : "${exercise.defaultSets}×${exercise.defaultReps}"}',
                          Icons.repeat_rounded,
                        ),
                        const SizedBox(width: 6),
                        _statChip(
                          '${exercise.caloriesPerRep.toStringAsFixed(1)} kcal',
                          Icons.local_fire_department_rounded,
                        ),
                      ],
                    ),
                    // Angle tracked
                    Row(
                      children: [
                        Icon(Icons.track_changes_rounded,
                            size: 10, color: Colors.white30),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            exercise.angleTracked,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white30,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white38),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
