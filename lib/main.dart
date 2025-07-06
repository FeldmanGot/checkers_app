import 'package:flutter/material.dart';
import 'screens/course_list_screen.dart'; // путь к экрану с курсами
import 'course_player_screen.dart';

void main() {
  runApp(const CheckersTrainerApp());
}

class CheckersTrainerApp extends StatelessWidget {
  const CheckersTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Шашечный тренажёр',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CourseListScreen(), // меняем стартовый экран
    );
  }
}
