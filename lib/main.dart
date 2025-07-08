import 'package:flutter/material.dart';
import 'screens/improved_course_list_screen.dart';

void main() {
  runApp(const CheckersTrainerApp());
}

class CheckersTrainerApp extends StatelessWidget {
  const CheckersTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Шашечная академия',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Colors.blue,
              secondary: Colors.orange,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B1B1B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF3A3A3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const ImprovedCourseListScreen(),
    );
  }
}
