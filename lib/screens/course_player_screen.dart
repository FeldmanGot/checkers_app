import 'package:flutter/material.dart';
import '../controllers/course_controller.dart';

class CoursePlayerScreen extends StatelessWidget {
  final Map<String, dynamic> course;

  const CoursePlayerScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: Text(course['title'] ?? 'Курс'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          course['description'] ?? 'Описание отсутствует',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
