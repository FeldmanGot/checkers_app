import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/move.dart';
import '../models/pos.dart';
import '../controllers/course_controller.dart';
import '../widgets/checkers_board.dart';

class CoursePlayerScreen extends StatefulWidget {
  final String jsonAssetPath;

  const CoursePlayerScreen({Key? key, required this.jsonAssetPath}) : super(key: key);

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  late CourseController controller;
  bool isLoading = true;
  String errorMessage = '';
  List<Move> movesHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final jsonString = await rootBundle.loadString(widget.jsonAssetPath);
      final List<dynamic> steps = json.decode(jsonString)['steps'];
      setState(() {
        controller = CourseController(steps: steps);
        isLoading = false;
        movesHistory = [];
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки курса: $e';
        isLoading = false;
      });
    }
  }

  void _onUserMove(Pos from, Pos to) {
    final userMove = Move(from, to);
    final isCorrect = controller.checkUserMove(userMove);

    if (isCorrect) {
      setState(() {
        errorMessage = '';
        movesHistory.add(userMove);
      });

      final opponentMove = controller.makeOpponentMove();
      if (opponentMove != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            movesHistory.add(opponentMove);
          });
        });
      }
    } else {
      setState(() {
        errorMessage = '❌ Неправильный ход! Попробуй ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('📚 Обучение шашкам')),
      body: Column(
        children: [
          Expanded(
            child: CheckersBoard(
              onUserMove: _onUserMove,
              moves: movesHistory,
            ),
          ),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
