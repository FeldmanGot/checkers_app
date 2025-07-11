import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lesson.dart';
import '../models/progress.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import 'lesson_screen.dart';
import 'statistics_screen.dart';
import 'course_editor_screen.dart';
import '../game_screen.dart';

class ImprovedCourseListScreen extends StatefulWidget {
  const ImprovedCourseListScreen({super.key});

  @override
  State<ImprovedCourseListScreen> createState() =>
      _ImprovedCourseListScreenState();
}

class _ImprovedCourseListScreenState extends State<ImprovedCourseListScreen> {
  List<Course> courses = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  final ProgressManager progressManager = ProgressManager();

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    try {
      final loadedCourses = await CourseService.loadAllCourses();
      
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

  List<Course> get filteredCourses {
    return courses.where((course) {
      final categoryMatch = selectedCategory == 'all' || 
          course.title.toLowerCase().contains(selectedCategory.toLowerCase());
      return categoryMatch;
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Поиск курсов...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Colors.grey[800],
          filled: true,
        ),
        onChanged: (value) {
          setState(() {
            selectedCategory = value.isEmpty ? 'all' : value;
          });
        },
      ),
    );
  }



  Widget _buildCourseCard(Course course) {
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
              builder: (context) => GameScreen(course: course),
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
                      color: course.id.startsWith('user_') 
                          ? Colors.purple 
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      course.id.startsWith('user_') 
                          ? 'Пользовательский' 
                          : 'Встроенный',
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
                  Icon(Icons.casino, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.steps.length} ходов',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const Spacer(),
                  if (course.id.startsWith('user_'))
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirmed = await _showDeleteConfirmation(course);
                          if (confirmed) {
                            await CourseService.deleteUserCourse(course.id);
                            loadCourses(); // Перезагружаем список
                          }
                        } else if (value == 'export') {
                          final path = await CourseService.exportCourseToFile(course);
                          if (path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Курс экспортирован в: $path')),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download),
                              SizedBox(width: 8),
                              Text('Экспортировать'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Удалить', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(Course course) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить курс'),
        content: Text('Вы уверены, что хотите удалить курс "${course.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ) ?? false;
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push<Course>(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseEditorScreen(),
                ),
              );
              if (result != null) {
                loadCourses(); // Перезагружаем список после создания курса
              }
            },
            tooltip: 'Создать курс',
          ),
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
                // Поиск
                _buildSearchBar(),
                // Список курсов
                Expanded(
                  child: filteredCourses.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет курсов',
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
