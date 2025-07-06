import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/course.dart';
import 'widgets/board.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Course? course;

  @override
  void initState() {
    super.initState();
    loadCourse();
  }

  Future<void> loadCourse() async {
    final data = await rootBundle.loadString('assets/courses/kombinaciya_1.json');
    final jsonResult = json.decode(data);
    setState(() {
      course = Course.fromJson(jsonResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (course == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(course!.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(), // убрать скролл
          child: Center(
            child: Builder(builder: (context) {
              final size = MediaQuery.of(context).size;
              final boardSize = (size.width < size.height ? size.width : size.height) * 0.95;

              return SizedBox(
                width: boardSize,
                height: boardSize,
                child: CheckersBoard(
                  fen: "W:W24,27,30:B8,11,14",
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
