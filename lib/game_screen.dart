import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'models/course.dart';
import 'models/pos.dart';
import 'widgets/board.dart';
import 'package:flutter/services.dart';
import 'logic/lidraughts_russian.dart'
    show
        Board,
        Piece,
        PieceColor,
        PieceType,
        DraughtsLogic,
        Move,
        BoardApplyMove;
import 'logic/pdn_utils.dart';

class GameScreen extends StatefulWidget {
  final Course course;

  const GameScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Board board = Board.initial();
  int currentStep = 0;
  List<Move> appliedMoves = [];
  bool isGameOver = false;
  String? gameResult;

  @override
  void initState() {
    super.initState();
    board = Board.initial();

    // Отладочная информация о загрузке курса
    print('Курс загружен: ${widget.course.title}');
    print('Количество шагов: ${widget.course.steps.length}');

    // Проверяем первые несколько шагов на наличие поля captured
    for (int i = 0; i < widget.course.steps.length && i < 10; i++) {
      var step = widget.course.steps[i];
      print(
          'Шаг $i: ${step.from} → ${step.to}, capture: ${step.capture}, captured: ${step.captured}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Информация о курсе
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.course.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.course.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Автор: ${widget.course.author}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Доска
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 400, maxHeight: 400),
                        child: BoardWidget(
                          board: board,
                          currentPlayer: PieceColor.white,
                          onUserMove: _handleUserMove,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Информация о ходе
                  if (currentStep < widget.course.steps.length)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Ход ${currentStep + 1} из ${widget.course.steps.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.course.steps[currentStep].comment,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Результат игры
                  if (isGameOver)
                    Card(
                      color: gameResult == 'Победа!'
                          ? Colors.green[100]
                          : Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          gameResult!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Кнопки управления
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Начать заново'),
                ),
                ElevatedButton(
                  onPressed: _showHint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Подсказка'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleUserMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (isGameOver) return;

    if (currentStep >= widget.course.steps.length) {
      _showMessage('Игра завершена!');
      return;
    }

    var expectedStep = widget.course.steps[currentStep];
    var expectedFrom = pdnToPos(expectedStep.from);
    var expectedTo = pdnToPos(expectedStep.to);

    // Преобразуем координаты доски в Pos
    final from = Pos(fromCol, fromRow);
    final to = Pos(toCol, toRow);

    // Сохраняем состояние для возможного отката
    Board prevBoard = board.copy();
    int prevStep = currentStep;
    List<Move> prevMoves = List<Move>.from(appliedMoves);

    if (from.x == expectedFrom.x &&
        from.y == expectedFrom.y &&
        to.x == expectedTo.x &&
        to.y == expectedTo.y) {
      // Правильный ход - применяем его к доске
      final piece = board.pieceAt(from);
      if (piece != null) {
        final possibleMoves = DraughtsLogic.generateMoves(board, piece.color);
        final move = possibleMoves.firstWhereOrNull(
          (m) => m.from == from && m.to == to,
        );
        if (move != null) {
          setState(() {
            board = board.applyMove(move);
            appliedMoves.add(move);
            currentStep++;

            if (currentStep >= widget.course.steps.length) {
              isGameOver = true;
              gameResult = 'Победа!';
            }
          });
        } else {
          _showMessage('Невозможный ход!');
        }
      } else {
        _showMessage('Нет шашки на начальной позиции!');
      }
    } else {
      // Неправильный ход
      _showMessage('Неправильный ход! Попробуйте еще раз.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _resetGame() {
    setState(() {
      board = Board.initial();
      currentStep = 0;
      appliedMoves.clear();
      isGameOver = false;
      gameResult = null;
    });
  }

  void _showHint() {
    if (currentStep < widget.course.steps.length) {
      var step = widget.course.steps[currentStep];
      _showMessage('Подсказка: ${step.from} → ${step.to}');
    }
  }
}
