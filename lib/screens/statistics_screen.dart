import 'package:flutter/material.dart';
import '../models/progress.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ProgressManager progressManager = ProgressManager();

  @override
  Widget build(BuildContext context) {
    final allProgress = progressManager.courseProgresses.values.toList();
    
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text(
          'Статистика обучения',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: allProgress.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallStats(allProgress),
                  const SizedBox(height: 24),
                  _buildStudyStreak(allProgress),
                  const SizedBox(height: 24),
                  _buildAccuracyChart(allProgress),
                  const SizedBox(height: 24),
                  _buildRecentActivity(allProgress),
                  const SizedBox(height: 24),
                  _buildAchievements(allProgress),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Пока нет данных для анализа',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Начните изучать курсы, чтобы увидеть статистику',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(List<CourseProgress> progressList) {
    final totalLessons = progressList.fold<int>(
      0, 
      (sum, progress) => sum + progress.lessonProgresses.length,
    );
    final completedLessons = progressList.fold<int>(
      0,
      (sum, progress) => sum + progress.lessonProgresses.where((l) => l.completed).length,
    );
    final averageAccuracy = progressList.isEmpty 
        ? 0.0 
        : progressList.map((p) => p.averageAccuracy).reduce((a, b) => a + b) / progressList.length;
    final totalHintsUsed = progressList.fold<int>(
      0,
      (sum, progress) => sum + progress.lessonProgresses.fold<int>(
        0, 
        (lessonSum, lesson) => lessonSum + lesson.hintsUsed,
      ),
    );

    return Card(
      color: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Завершено уроков',
                    '$completedLessons / $totalLessons',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Средняя точность',
                    '${(averageAccuracy * 100).toInt()}%',
                    Icons.target,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Курсов изучается',
                    '${progressList.length}',
                    Icons.school,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Подсказок использовано',
                    '$totalHintsUsed',
                    Icons.lightbulb,
                    Colors.yellow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudyStreak(List<CourseProgress> progressList) {
    final maxStreak = progressList.isEmpty 
        ? 0 
        : progressList.map((p) => p.streak).reduce((a, b) => a > b ? a : b);
    final daysStudied = progressList.where((p) => p.lastStudied != null).length;

    return Card(
      color: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Активность обучения',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$maxStreak',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text(
                      'Макс. серия',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[600],
                ),
                Column(
                  children: [
                    Text(
                      '$daysStudied',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Дней изучения',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyChart(List<CourseProgress> progressList) {
    return Card(
      color: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Точность по курсам',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...progressList.take(5).map((progress) => _buildAccuracyBar(progress)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyBar(CourseProgress progress) {
    final accuracy = progress.averageAccuracy;
    final completionPercent = progress.overallProgress;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.courseId,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(accuracy * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: accuracy > 0.8 
                      ? Colors.green 
                      : accuracy > 0.6 
                          ? Colors.orange 
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: accuracy,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(
              accuracy > 0.8 
                  ? Colors.green 
                  : accuracy > 0.6 
                      ? Colors.orange 
                      : Colors.red,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Прогресс: ${(completionPercent * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<CourseProgress> progressList) {
    final recentLessons = progressList
        .expand((course) => course.lessonProgresses
            .where((lesson) => lesson.lastStudied != null)
            .map((lesson) => MapEntry(course.courseId, lesson)))
        .toList()
      ..sort((a, b) => b.value.lastStudied!.compareTo(a.value.lastStudied!));

    return Card(
      color: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Последняя активность',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...recentLessons.take(5).map((entry) => _buildActivityItem(
              entry.key,
              entry.value,
            )),
            if (recentLessons.isEmpty)
              const Text(
                'Пока нет активности',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String courseId, LessonProgress lesson) {
    final timeAgo = _getTimeAgo(lesson.lastStudied!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: lesson.completed ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.lessonId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  courseId,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(List<CourseProgress> progressList) {
    final achievements = _calculateAchievements(progressList);
    
    return Card(
      color: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Достижения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: achievements.map(_buildAchievementBadge).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: achievement.unlocked ? achievement.color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: achievement.unlocked ? achievement.color : Colors.grey,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achievement.icon,
            size: 16,
            color: achievement.unlocked ? achievement.color : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 12,
              color: achievement.unlocked ? achievement.color : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }

  List<Achievement> _calculateAchievements(List<CourseProgress> progressList) {
    final totalCompleted = progressList.fold<int>(
      0,
      (sum, progress) => sum + progress.lessonProgresses.where((l) => l.completed).length,
    );
    final perfectAccuracy = progressList.any((p) => p.averageAccuracy >= 1.0);
    final completedCourse = progressList.any((p) => p.isCompleted);
    final maxStreak = progressList.isEmpty 
        ? 0 
        : progressList.map((p) => p.streak).reduce((a, b) => a > b ? a : b);

    return [
      Achievement(
        title: 'Первые шаги',
        icon: Icons.star,
        color: Colors.yellow,
        unlocked: totalCompleted >= 1,
      ),
      Achievement(
        title: 'Отличник',
        icon: Icons.grade,
        color: Colors.green,
        unlocked: perfectAccuracy,
      ),
      Achievement(
        title: 'Завершитель',
        icon: Icons.check_circle,
        color: Colors.blue,
        unlocked: completedCourse,
      ),
      Achievement(
        title: 'Марафонец',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        unlocked: maxStreak >= 7,
      ),
      Achievement(
        title: 'Эксперт',
        icon: Icons.emoji_events,
        color: Colors.purple,
        unlocked: totalCompleted >= 10,
      ),
    ];
  }
}

class Achievement {
  final String title;
  final IconData icon;
  final Color color;
  final bool unlocked;

  Achievement({
    required this.title,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}