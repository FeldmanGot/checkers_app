import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lesson.dart';
import '../models/progress.dart';
import 'lesson_screen.dart';
import 'statistics_screen.dart';

class ImprovedCourseListScreen extends StatefulWidget {
  const ImprovedCourseListScreen({super.key});

  @override
  State<ImprovedCourseListScreen> createState() =>
      _ImprovedCourseListScreenState();
}

class _ImprovedCourseListScreenState extends State<ImprovedCourseListScreen> {
  List<ExtendedCourse> courses = [];
  bool isLoading = true;
  String selectedDifficulty = 'all';
  String selectedCategory = 'all';
  final ProgressManager progressManager = ProgressManager();

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    try {
      final courseFiles = [
        'assets/courses/kombinaciya_1.json',
        'assets/courses/endgame_basics.json',
      ];

      List<ExtendedCourse> loadedCourses = [];

      for (final file in courseFiles) {
        try {
          final jsonStr = await rootBundle.loadString(file);
          final data = json.decode(jsonStr);
          final course = ExtendedCourse.fromJson(data);
          loadedCourses.add(course);
        } catch (e) {
          print('Ошибка загрузки курса $file: $e');
        }
      }

      setState(() {
        courses = loadedCourses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Ошибка загрузки курсов: $e');
    }
  }

  List<ExtendedCourse> get filteredCourses {
    return courses.where((course) {
      final difficultyMatch = selectedDifficulty == 'all' ||
          course.difficulty == selectedDifficulty;
      final categoryMatch =
          selectedCategory == 'all' || course.category == selectedCategory;
      return difficultyMatch && categoryMatch;
    }).toList();
  }

  Widget _buildDifficultyChip(String difficulty, String label, Color color) {
    final isSelected = selectedDifficulty == difficulty;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedDifficulty = selected ? difficulty : 'all';
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: color.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedCategory = selected ? category : 'all';
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: Colors.blue.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCourseCard(ExtendedCourse course) {
    final progress = progressManager.getCourseProgress(course.id);
    final progressPercent = progress?.overallProgress ?? 0.0;
    final averageAccuracy = progress?.averageAccuracy ?? 0.0;

    return Card(
      color: const Color(0xFF3A3A3A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonScreen(course: course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Автор: ${course.author}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(course.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyLabel(course.difficulty),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                course.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.estimatedTime} мин',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.book, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.lessons.length} уроков',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.orange[400]),
                      const SizedBox(width: 4),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
              if (progressPercent > 0) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Прогресс: ${(progressPercent * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (averageAccuracy > 0)
                          Text(
                            'Точность: ${(averageAccuracy * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercent < 0.3
                            ? Colors.red[400]!
                            : progressPercent < 0.7
                                ? Colors.orange[400]!
                                : Colors.green[400]!,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: course.tags
                    .take(3)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Новичок';
      case 'intermediate':
        return 'Средний';
      case 'advanced':
        return 'Продвинутый';
      default:
        return 'Общий';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text(
          "Шашечная академия",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
            tooltip: 'Статистика',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              children: [
                // Фильтры
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Уровень сложности:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildDifficultyChip('all', 'Все', Colors.grey),
                          _buildDifficultyChip(
                              'beginner', 'Новичок', Colors.green),
                          _buildDifficultyChip(
                              'intermediate', 'Средний', Colors.orange),
                          _buildDifficultyChip(
                              'advanced', 'Продвинутый', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Категория:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildCategoryChip('all', 'Все'),
                          _buildCategoryChip('tactics', 'Тактика'),
                          _buildCategoryChip('strategy', 'Стратегия'),
                          _buildCategoryChip('endgame', 'Эндшпиль'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Список курсов
                Expanded(
                  child: filteredCourses.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет курсов для выбранных фильтров',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            return _buildCourseCard(filteredCourses[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
