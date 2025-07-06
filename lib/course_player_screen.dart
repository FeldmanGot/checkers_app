import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'models/move.dart';
import 'models/pos.dart';
import 'controllers/course_controller.dart';
import 'widgets/checkers_board.dart';

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
  String courseTitle = '';
  String courseDescription = '';

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final jsonString = await rootBundle.loadString(widget.jsonAssetPath);
      final courseData = json.decode(jsonString);
      final List<dynamic> steps = courseData['steps'];
      
      setState(() {
        controller = CourseController(steps: steps);
        courseTitle = courseData['title'] ?? 'Курс шашек';
        courseDescription = courseData['description'] ?? '';
        isLoading = false;
        movesHistory = [];
        errorMessage = '';
      });

      // Выполняем начальные ходы противника, если курс начинается с них
      _executeInitialOpponentMoves();
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки курса: $e';
        isLoading = false;
      });
      print('Ошибка загрузки курса: $e');
    }
  }

  void _executeInitialOpponentMoves() {
    final opponentMoves = controller.getAllPendingOpponentMoves();
    if (opponentMoves.isNotEmpty) {
      setState(() {
        movesHistory.addAll(opponentMoves);
      });
    }
  }

  void _onUserMove(Pos from, Pos to) {
    if (controller.isFinished) {
      setState(() {
        errorMessage = '🎉 Курс завершен!';
      });
      return;
    }

    if (!controller.isUserTurn) {
      setState(() {
        errorMessage = '⏳ Сейчас ход противника!';
      });
      return;
    }

    final userMove = Move(from, to);
    print('User move: ${from.x},${from.y} -> ${to.x},${to.y}');
    print('Current step: ${controller.currentStep}');
    
    final isCorrect = controller.checkUserMove(userMove);

    if (isCorrect) {
      setState(() {
        errorMessage = '';
        movesHistory.add(userMove);
      });

      // Выполняем все последующие ходы противника
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final opponentMoves = controller.getAllPendingOpponentMoves();
          if (opponentMoves.isNotEmpty) {
            setState(() {
              movesHistory.addAll(opponentMoves);
            });
          }

          // Проверяем завершение курса
          if (controller.isFinished) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  errorMessage = '🎉 Поздравляем! Курс успешно завершен!';
                });
              }
            });
          }
        }
      });
    } else {
      setState(() {
        errorMessage = '❌ Неправильный ход! Попробуйте ещё раз.';
      });
    }
  }

  void _resetCourse() {
    setState(() {
      movesHistory = [];
      errorMessage = '';
      controller.currentStep = 0;
    });
    _executeInitialOpponentMoves();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2B2B2B),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: Text(
          courseTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCourse,
            tooltip: 'Перезапустить курс',
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о курсе
          if (courseDescription.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                courseDescription,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Прогресс
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Шаг: ${controller.currentStep + 1} / ${controller.steps.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  controller.isFinished 
                      ? '✅ Завершено' 
                      : controller.isUserTurn 
                          ? '👤 Ваш ход' 
                          : '🤖 Ход противника',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          
          // Доска
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: CheckersBoard(
                onUserMove: _onUserMove,
                moves: movesHistory,
              ),
            ),
          ),
          
          // Сообщения об ошибках/успехе
          if (errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorMessage.contains('❌') 
                    ? Colors.red.withOpacity(0.2)
                    : errorMessage.contains('🎉')
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: errorMessage.contains('❌') 
                      ? Colors.red
                      : errorMessage.contains('🎉')
                          ? Colors.green
                          : Colors.orange,
                ),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: errorMessage.contains('❌') 
                      ? Colors.red
                      : errorMessage.contains('🎉')
                          ? Colors.green
                          : Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}