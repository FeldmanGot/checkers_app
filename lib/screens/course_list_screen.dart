import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../controllers/course_controller.dart';


// Импорт экрана для прохождения курса (убедись, что файл и класс существуют)
import 'course_player_screen.dart'; 

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  List<Map<String, dynamic>> courses = [];

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    final jsonStr = await rootBundle.loadString('assets/courses/kombinaciya_1.json');
    final data = json.decode(jsonStr);
    setState(() {
      courses = [data];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text(
          "Шашечные курсы",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Card(
              color: const Color(0xFF3A3A3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                title: Text(
                  course['title'] ?? 'Без названия',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  course['description'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoursePlayerScreen(course: course),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
