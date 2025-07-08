import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/pos.dart';
import '../models/move.dart';
import '../models/progress.dart';
import '../widgets/enhanced_checkers_board.dart';

class LessonScreen extends StatefulWidget {
  final ExtendedCourse course;

  const LessonScreen({super.key, required this.course});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int currentLessonIndex = 0;
  int currentMoveIndex = 0;
  List<Move> movesHistory = [];
  String message = '';
  MessageType messageType = MessageType.info;
  bool showHint = false;
  int hintsUsed = 0;
  int attempts = 0;
  int correctMoves = 0;
  DateTime lessonStartTime = DateTime.now();

  final ProgressManager progressManager = ProgressManager();

  Lesson get currentLesson => widget.course.lessons[currentLessonIndex];
  bool get isLessonCompleted => currentMoveIndex >= currentLesson.moves.length;
  bool get isCourseCompleted =>
      currentLessonIndex >= widget.course.lessons.length - 1 &&
      isLessonCompleted;

  @override
  void initState() {
    super.initState();
    _initializeLesson();
  }

  void _initializeLesson() {
    setState(() {
      currentMoveIndex = 0;
      movesHistory = [];
      message = currentLesson.explanation;
      messageType = MessageType.info;
      showHint = false;
      hintsUsed = 0;
      attempts = 0;
      correctMoves = 0;
      lessonStartTime = DateTime.now();
    });

    // Выполняем автоматические ходы в начале урока
    _executeAutomaticMoves();
  }

  void _executeAutomaticMoves() {
    // Выполняем ходы типа "forced" автоматически
    while (currentMoveIndex < currentLesson.moves.length) {
      final move = currentLesson.moves[currentMoveIndex];
      if (move.type != 'user') {
        final convertedMove = _convertMove(move.move);
        if (convertedMove != null) {
          setState(() {
            movesHistory.add(convertedMove);
            currentMoveIndex++;
          });
        } else {
          break;
        }
      } else {
        break;
      }
    }
  }

  Move? _convertMove(String moveNotation) {
    try {
      // Парсим нотацию вида "c3-d4" или "e5xc3"
      final isCapture = moveNotation.contains('x');
      final parts = moveNotation.split(isCapture ? 'x' : '-');

      if (parts.length != 2) return null;

      final from = _parsePosition(parts[0]);
      final to = _parsePosition(parts[1]);

      List<Pos> captures = [];
      if (isCapture) {
        // Простая логика для взятий - добавляем промежуточные позиции
        final dx = to.x - from.x;
        final dy = to.y - from.y;
        if (dx.abs() == dy.abs() && dx.abs() > 1) {
          final stepX = dx > 0 ? 1 : -1;
          final stepY = dy > 0 ? 1 : -1;
          for (int step = 1; step < dx.abs(); step++) {
            captures.add(Pos(from.x + step * stepX, from.y + step * stepY));
          }
        }
      }

      return Move(from, to, captures: captures);
    } catch (e) {
      print('Ошибка конвертации хода: $e');
      return null;
    }
  }

  Pos _parsePosition(String notation) {
    final file = notation[0];
    final rank = notation[1];
    final x = file.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final y = 8 - int.parse(rank);
    return Pos(x, y);
  }

  void _onUserMove(Pos from, Pos to) {
    if (isLessonCompleted) return;

    attempts++;

    final expectedMove = currentLesson.moves[currentMoveIndex];
    if (expectedMove.type != 'user') {
      setState(() {
        message = 'Сейчас не ваш ход!';
        messageType = MessageType.error;
      });
      return;
    }

    final expectedConverted = _convertMove(expectedMove.move);
    if (expectedConverted == null) {
      setState(() {
        message = 'Ошибка в данных урока';
        messageType = MessageType.error;
      });
      return;
    }

    final userMove = Move(from, to);

    if (userMove.from == expectedConverted.from &&
        userMove.to == expectedConverted.to) {
      // Правильный ход
      correctMoves++;
      setState(() {
        movesHistory.add(userMove);
        currentMoveIndex++;
        message = expectedMove.explanation;
        messageType = MessageType.success;
        showHint = false;
      });

      // Выполняем следующие автоматические ходы
      _executeAutomaticMoves();

      // Проверяем завершение урока
      if (isLessonCompleted) {
        _onLessonCompleted();
      }
    } else {
      // Неправильный ход
      setState(() {
        message = 'Неправильный ход! ${expectedMove.explanation}';
        messageType = MessageType.error;
      });
    }
  }

  void _onLessonCompleted() {
    final accuracy = attempts > 0 ? correctMoves / attempts : 1.0;
    final progress = LessonProgress(
      lessonId: currentLesson.id,
      completed: true,
      completedAt: DateTime.now(),
      attempts: attempts,
      correctMoves: correctMoves,
      totalMoves: currentLesson.moves.where((m) => m.type == 'user').length,
      accuracy: accuracy,
      hintsUsed: hintsUsed,
      lastStudied: DateTime.now(),
    );

    progressManager.updateLessonProgress(widget.course.id, progress);

    setState(() {
      message = 'Урок завершен! Точность: ${(accuracy * 100).toInt()}%';
      messageType = MessageType.success;
    });

    // Показываем диалог завершения урока
    _showLessonCompletedDialog(accuracy);
  }

  void _showLessonCompletedDialog(double accuracy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3A3A),
        title: const Text(
          '🎉 Урок завершен!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ваши результаты:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Точность:', style: TextStyle(color: Colors.white70)),
                Text(
                  '${(accuracy * 100).toInt()}%',
                  style: TextStyle(
                    color: accuracy > 0.8
                        ? Colors.green
                        : accuracy > 0.6
                            ? Colors.orange
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Попытки:', style: TextStyle(color: Colors.white70)),
                Text('$attempts', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Подсказки:', style: TextStyle(color: Colors.white70)),
                Text('$hintsUsed', style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (!isCourseCompleted) {
                _nextLesson();
              }
            },
            child: Text(
              isCourseCompleted ? 'Завершить курс' : 'Следующий урок',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeLesson();
            },
            child: const Text(
              'Повторить',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _nextLesson() {
    if (currentLessonIndex < widget.course.lessons.length - 1) {
      setState(() {
        currentLessonIndex++;
      });
      _initializeLesson();
    }
  }

  void _showHint() {
    if (currentMoveIndex < currentLesson.moves.length &&
        currentLesson.hints.isNotEmpty) {
      setState(() {
        showHint = true;
        hintsUsed++;
        final hintIndex = (hintsUsed - 1) % currentLesson.hints.length;
        message = 'Подсказка: ${currentLesson.hints[hintIndex]}';
        messageType = MessageType.hint;
      });
    }
  }

  void _resetLesson() {
    _initializeLesson();
  }

  Widget _buildLessonHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF3A3A3A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  currentLesson.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLessonTypeColor(currentLesson.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getLessonTypeLabel(currentLesson.type),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentLesson.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Урок ${currentLessonIndex + 1} из ${widget.course.lessons.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                'Ход ${currentMoveIndex + 1} из ${currentLesson.moves.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentLesson.moves.isEmpty
                ? 0
                : currentMoveIndex / currentLesson.moves.length,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Color _getLessonTypeColor(String type) {
    switch (type) {
      case 'interactive':
        return Colors.blue;
      case 'puzzle':
        return Colors.purple;
      case 'practice':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getLessonTypeLabel(String type) {
    switch (type) {
      case 'interactive':
        return 'Интерактив';
      case 'puzzle':
        return 'Головоломка';
      case 'practice':
        return 'Практика';
      default:
        return 'Урок';
    }
  }

  Widget _buildMessageBar() {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getMessageColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getMessageColor()),
      ),
      child: Row(
        children: [
          Icon(
            _getMessageIcon(),
            color: _getMessageColor(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getMessageColor(),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMessageColor() {
    switch (messageType) {
      case MessageType.success:
        return Colors.green;
      case MessageType.error:
        return Colors.red;
      case MessageType.hint:
        return Colors.orange;
      case MessageType.info:
      default:
        return Colors.blue;
    }
  }

  IconData _getMessageIcon() {
    switch (messageType) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.hint:
        return Icons.lightbulb;
      case MessageType.info:
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        title: Text(
          widget.course.title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: currentLesson.hints.isNotEmpty ? _showHint : null,
            tooltip: 'Подсказка',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetLesson,
            tooltip: 'Начать заново',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLessonHeader(),
          _buildMessageBar(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: EnhancedCheckersBoard(
                onUserMove: _onUserMove,
                moves: movesHistory,
                position: currentLesson.position,
                hintMove: showHint &&
                        currentMoveIndex < currentLesson.moves.length
                    ? _convertMove(currentLesson.moves[currentMoveIndex].move)
                    : null,
                showHint: showHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum MessageType { info, success, error, hint }
