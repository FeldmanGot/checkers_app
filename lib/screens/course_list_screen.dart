import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../course_player_screen.dart'; // Используем файл из корня lib/
import '../models/course.dart';
import '../game_screen.dart';
import '../screens/course_editor_screen.dart';
import 'package:uuid/uuid.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  bool isLoading = true;
  final List<dynamic> userCourses = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text(
          "Шашечные курсы",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'О приложении',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Редактор курсов (PDN)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CourseEditorScreen(),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      userCourses.add(result);
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Course>>(
              future: _loadCourses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Загрузка курсов...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки курсов: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                final courses = [...userCourses, ...(snapshot.data ?? [])];

                if (courses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Курсы не найдены',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final isUserCourse = index < userCourses.length;
                    String title, description, author;
                    int stepsCount;
                    if (course is Map) {
                      title = course['title'] ?? '';
                      description = course['description'] ?? '';
                      author = course['author'] ?? '';
                      stepsCount = (course['steps'] as List?)?.length ?? 0;
                    } else {
                      title = course.title;
                      description = course.description;
                      author = course.author;
                      stepsCount = course.steps.length;
                    }
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  author,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.play_arrow,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '$stepsCount ходов',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: isUserCourse
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Редактировать',
                                    onPressed: () async {
                                      final edited =
                                          await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CourseEditorScreen(),
                                        ),
                                      );
                                      if (edited != null) {
                                        setState(() {
                                          userCourses[index] = edited;
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Удалить',
                                    onPressed: () {
                                      setState(() {
                                        userCourses.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          if (isUserCourse) {
                            // Пользовательские курсы открываем в CoursePlayerScreen с автоходом
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoursePlayerScreen(
                                  course: _userCourseToCourse(course),
                                ),
                              ),
                            );
                          } else {
                            // Встроенные курсы открываем в GameScreen для обучения
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GameScreen(course: course),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Курсы не найдены',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте курсы в папку assets/courses',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index) {
    final steps = course['steps'] as List? ?? [];
    final author = course['author'] ?? 'Неизвестный автор';
    final description = course['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3A3A3A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openCourse(course),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ?? 'Без названия',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Автор: $author',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Text(
                        '${steps.length} ходов',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatisticItem(
                        Icons.timer,
                        'Сложность',
                        _getDifficultyText(steps.length),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatisticItem(
                        Icons.category,
                        'Тип',
                        _getCourseType(course),
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Начать обучение',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticItem(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyText(int stepsCount) {
    if (stepsCount <= 5) return 'Легкая';
    if (stepsCount <= 10) return 'Средняя';
    if (stepsCount <= 15) return 'Сложная';
    return 'Эксперт';
  }

  String _getCourseType(Map<String, dynamic> course) {
    final title = (course['title'] ?? '').toLowerCase();
    if (title.contains('комбинация')) return 'Комбинация';
    if (title.contains('эндшпиль')) return 'Эндшпиль';
    if (title.contains('дебют')) return 'Дебют';
    return 'Тактика';
  }

  void _openCourse(Map<String, dynamic> course) {
    // Конвертируем Map в Course
    final courseObj = _userCourseToCourse(course);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoursePlayerScreen(
          course: courseObj,
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A3A3A),
          title: const Text(
            'О приложении',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Шашечный тренажёр - интерактивное приложение для изучения шашечных комбинаций и тактики.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'Возможности:',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Интерактивные курсы\n'
                '• Подсказки и подсказки\n'
                '• Отслеживание прогресса\n'
                '• Статистика обучения\n'
                '• Красивый интерфейс',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Course>> _loadCourses() async {
    try {
      // Загружаем курс из файла
      final jsonStr =
          await rootBundle.loadString('assets/courses/kombinaciya_1.json');
      final data = json.decode(jsonStr);

      // Конвертируем в объект Course
      List<MoveStep> steps = [];
      for (var step in data['steps']) {
        steps.add(MoveStep(
          from: step['from'],
          to: step['to'],
          capture: step['capture'] ?? false,
          side: step['side'],
          comment: step['comment'],
        ));
      }

      Course course = Course(
        id: data['id'],
        title: data['title'],
        author: data['author'],
        description: data['description'],
        steps: steps,
      );

      return [course];
    } catch (e) {
      print('Ошибка загрузки курса: $e');
      return [];
    }
  }

  Course _userCourseToCourse(Map data) {
    final uuid = Uuid();
    return Course(
      id: data['id'] ?? uuid.v4(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      author: data['author'] ?? '',
      steps: (data['steps'] as List?)?.map((e) {
            if (e is MoveStep) return e;
            if (e is Map) return MoveStep.fromJson(e as Map<String, dynamic>);
            throw Exception('Invalid step format');
          }).toList() ??
          [],
    );
  }
}
