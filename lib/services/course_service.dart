import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class CourseService {
  static const String _userCoursesKey = 'user_courses';
  
  // Список встроенных курсов
  static const List<String> _builtInCourses = [
    'kombinaciya_1.json',
    'endgame_basics.json',
    'endgame_white_advantage.json',
    'endgame_white_advantage_old.json',
  ];

  /// Загружает все курсы (встроенные + пользовательские)
  static Future<List<Course>> loadAllCourses() async {
    final List<Course> courses = [];
    
    // Загружаем встроенные курсы
    for (final filename in _builtInCourses) {
      try {
        final courseJson = await rootBundle.loadString('assets/courses/$filename');
        final courseData = json.decode(courseJson);
        final course = Course.fromJson(courseData);
        courses.add(course);
      } catch (e) {
        print('Ошибка загрузки встроенного курса $filename: $e');
      }
    }
    
    // Загружаем пользовательские курсы
    final userCourses = await loadUserCourses();
    courses.addAll(userCourses);
    
    return courses;
  }

  /// Загружает только пользовательские курсы
  static Future<List<Course>> loadUserCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userCoursesJson = prefs.getStringList(_userCoursesKey) ?? [];
      
      return userCoursesJson.map((courseJson) {
        final courseData = json.decode(courseJson);
        return Course.fromJson(courseData);
      }).toList();
    } catch (e) {
      print('Ошибка загрузки пользовательских курсов: $e');
      return [];
    }
  }

  /// Сохраняет пользовательский курс
  static Future<bool> saveUserCourse(Course course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userCoursesJson = prefs.getStringList(_userCoursesKey) ?? [];
      
      // Проверяем, не существует ли уже курс с таким id
      final existingIndex = userCoursesJson.indexWhere((courseJson) {
        final courseData = json.decode(courseJson);
        return courseData['id'] == course.id;
      });
      
      final courseJson = json.encode(course.toJson());
      
      if (existingIndex >= 0) {
        // Обновляем существующий курс
        userCoursesJson[existingIndex] = courseJson;
      } else {
        // Добавляем новый курс
        userCoursesJson.add(courseJson);
      }
      
      await prefs.setStringList(_userCoursesKey, userCoursesJson);
      return true;
    } catch (e) {
      print('Ошибка сохранения курса: $e');
      return false;
    }
  }

  /// Удаляет пользовательский курс
  static Future<bool> deleteUserCourse(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userCoursesJson = prefs.getStringList(_userCoursesKey) ?? [];
      
      userCoursesJson.removeWhere((courseJson) {
        final courseData = json.decode(courseJson);
        return courseData['id'] == courseId;
      });
      
      await prefs.setStringList(_userCoursesKey, userCoursesJson);
      return true;
    } catch (e) {
      print('Ошибка удаления курса: $e');
      return false;
    }
  }

  /// Экспортирует курс в JSON файл
  static Future<String?> exportCourseToFile(Course course) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${course.id}.json');
      final courseJson = json.encode(course.toJson());
      await file.writeAsString(courseJson);
      return file.path;
    } catch (e) {
      print('Ошибка экспорта курса в файл: $e');
      return null;
    }
  }

  /// Импортирует курс из JSON файла
  static Future<Course?> importCourseFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final courseJson = await file.readAsString();
      final courseData = json.decode(courseJson);
      return Course.fromJson(courseData);
    } catch (e) {
      print('Ошибка импорта курса из файла: $e');
      return null;
    }
  }

  /// Генерирует уникальный ID для нового курса
  static String generateCourseId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user_course_$timestamp';
  }
}