import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:collection/collection.dart';
import 'logic/lidraughts_russian.dart'
    show
        Board,
        Piece,
        PieceColor,
        PieceType,
        DraughtsLogic,
        Move,
        BoardApplyMove;
import 'models/course.dart';
import 'models/pos.dart';
import 'logic/pdn_utils.dart';
import 'widgets/board.dart';

class CoursePlayerScreen extends StatefulWidget {
  final Course course;

  const CoursePlayerScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  Course? course;
  Board board = Board.initial();
  int currentStep = 0;
  bool showHint = false;
  String errorMessage = '';
  bool isLoading = true;
  bool isGameOver = false;
  String gameResult = '';
  Pos? selectedPos;
  PieceColor userColor = PieceColor.white;

  @override
  void initState() {
    super.initState();
    board = Board.initial();
    currentStep = 0;
    userColor = PieceColor.white;
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      setState(() {
        course = widget.course;
        isLoading = false;
      });
      print('=== КУРС ЗАГРУЖЕН ===');
      print('Название: ${course?.title}');
      print('Количество шагов: ${course?.steps.length}');
      print('Первый ход: ${course?.steps.first.side}');

      // Определяем цвет пользователя на основе первого хода
      if (course != null && course!.steps.isNotEmpty) {
        final firstStep = course!.steps[0];
        // Если первый ход за белых, то пользователь играет за черных
        // Если первый ход за черных, то пользователь играет за белых
        userColor = _sideToColor(firstStep.side) == PieceColor.white
            ? PieceColor.black
            : PieceColor.white;
      }
      print('Пользователь играет за: $userColor');

      // После загрузки курса — автоход, если первый ход не за пользователя
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (course != null && course!.steps.isNotEmpty) {
          final step = course!.steps[0];
          if (_sideToColor(step.side) != userColor) {
            print('🔄 Делаем первый автоход за ${step.side}');
            _makeAutoMove();
          } else {
            print('👤 Первый ход за пользователя');
          }
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки курса: $e';
        isLoading = false;
      });
    }
  }

  // После пользовательского хода — всегда делаем следующий ход из курса
  void _makeNextMoveFromCourse() {
    if (course == null || isGameOver || currentStep >= course!.steps.length)
      return;
    print('🔄 Вызываем автоход после пользовательского хода');
    _makeAutoMove();
  }

  PieceColor _sideToColor(String side) {
    return side == 'w' ? PieceColor.white : PieceColor.black;
  }

  void _onUserMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (course == null || currentStep >= course!.steps.length) return;

    var expectedStep = course!.steps[currentStep];
    var expectedFrom = pdnToPos(expectedStep.from);
    var expectedTo = pdnToPos(expectedStep.to);

    // Преобразуем координаты доски в Pos
    final from = Pos(fromCol, fromRow);
    final to = Pos(toCol, toRow);

    // Отладочная информация
    print('=== ПОЛЬЗОВАТЕЛЬСКИЙ ХОД ===');
    print('Пользовательский ход: ${from.x},${from.y} → ${to.x},${to.y}');
    print(
        'Ожидаемый ход: ${expectedFrom.x},${expectedFrom.y} → ${expectedTo.x},${expectedTo.y}');
    print('Текущий шаг: $currentStep, сторона: ${expectedStep.side}');

    final piece = board.pieceAt(from);
    if (piece != null) {
      final possibleMoves = DraughtsLogic.generateMoves(board, piece.color);
      print('Возможные ходы пользователя:');
      for (final m in possibleMoves) {
        print('  ${m.from.x},${m.from.y} → ${m.to.x},${m.to.y}');
      }
    } else {
      print('❌ Нет шашки на позиции пользователя: ${from.x},${from.y}');
    }

    if (from.x == expectedFrom.x &&
        from.y == expectedFrom.y &&
        to.x == expectedTo.x &&
        to.y == expectedTo.y) {
      // Правильный ход
      print('✅ Правильный ход!');
      setState(() {
        // Применяем ход к доске
        if (piece != null) {
          final possibleMoves = DraughtsLogic.generateMoves(board, piece.color);
          final move = possibleMoves.firstWhereOrNull(
            (m) => m.from == from && m.to == to,
          );
          if (move != null) {
            board = board.applyMove(move);
            print('Ход применен к доске');
          } else {
            print('❌ Не найден ход для применения!');
          }
        }

        currentStep++;
        selectedPos = null;
      });
      // После пользовательского хода — всегда делаем следующий ход из курса
      _makeNextMoveFromCourse();
      if (currentStep >= course!.steps.length) {
        setState(() {
          isGameOver = true;
          gameResult = 'Победа!';
        });
      }
    } else {
      // Неправильный ход
      print('❌ Неправильный ход!');
      _showMessage('Неправильный ход! Попробуйте еще раз.');
    }
  }

  void _onSquareTap(Pos pos) {
    print('🎯 _onSquareTap вызван для позиции: ${pos.x},${pos.y}');
    print('🎯 _onSquareTap: course != null: ${course != null}');
    print('🎯 _onSquareTap: currentStep: $currentStep');
    print('🎯 _onSquareTap: course?.steps.length: ${course?.steps.length}');
    print('🎯 _onSquareTap: isGameOver: $isGameOver');

    if (course == null || currentStep >= course!.steps.length || isGameOver)
      return;

    final piece = board.pieceAt(pos);
    print('Шашка на позиции: ${piece?.color} ${piece?.type}');

    if (selectedPos == null) {
      // Выбираем шашку
      if (piece != null && piece.color == userColor) {
        print('✅ Выбираем шашку на позиции: ${pos.x},${pos.y}');
        setState(() {
          selectedPos = pos;
        });
      } else {
        print('❌ Нельзя выбрать шашку: ${piece?.color} != ${userColor}');
      }
    } else {
      // Делаем ход
      final from = selectedPos!;
      final to = pos;

      print('🔄 Делаем ход: ${from.x},${from.y} → ${to.x},${to.y}');

      if (from != to) {
        // Передаем координаты в правильном порядке: (row, col, row, col)
        _onUserMove(from.y, from.x, to.y, to.x);
      } else {
        // Отменяем выбор
        print('❌ Отменяем выбор');
        setState(() {
          selectedPos = null;
        });
      }
    }
  }

  void _makeAutoMove() {
    if (currentStep >= course!.steps.length) return;

    var step = course!.steps[currentStep];
    var from = pdnToPos(step.from);
    var to = pdnToPos(step.to);

    print('=== АВТОХОД ===');
    print('Автоход: ${from.x},${from.y} → ${to.x},${to.y}');
    print('Сторона: ${step.side}');

    final piece = board.pieceAt(from);
    if (piece != null) {
      final possibleMoves = DraughtsLogic.generateMoves(board, piece.color);
      print('Возможные автоходы:');
      for (final m in possibleMoves) {
        print('  ${m.from.x},${m.from.y} → ${m.to.x},${m.to.y}');
      }
      final move = possibleMoves.firstWhereOrNull(
        (m) => m.from == from && m.to == to,
      );
      if (move != null) {
        setState(() {
          board = board.applyMove(move);
          currentStep++;
          print('✅ Автоход применен, новый шаг: $currentStep');
        });
      } else {
        print('❌ Не удалось найти ход для автохода');
      }
    } else {
      print('❌ Нет шашки на позиции автохода: ${from.x},${from.y}');
    }
    if (currentStep >= course!.steps.length) {
      setState(() {
        isGameOver = true;
        gameResult = 'Победа!';
      });
    }
  }

  void _toggleHint() {
    setState(() {
      showHint = !showHint;
    });
  }

  void _resetCourse() {
    setState(() {
      board = Board.initial();
      currentStep = 0;
      errorMessage = '';
      isGameOver = false;
      gameResult = '';
      selectedPos = null;
    });
    print('🔄 Курс сброшен');
    // После сброса — автоход только если первый ход не за пользователя
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (course != null && course!.steps.isNotEmpty) {
        final step = course!.steps[0];
        if (_sideToColor(step.side) != userColor) {
          print('🔄 Делаем автоход после сброса');
          _makeAutoMove();
        }
      }
    });
  }

  void _showMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2B2B2B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Загрузка курса...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (course == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        appBar: AppBar(
          title: const Text('Ошибка'),
          backgroundColor: const Color(0xFF2B2B2B),
        ),
        body: Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: Text('Курс: ${course!.title}'),
        backgroundColor: const Color(0xFF2B2B2B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCourse,
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            'Курс: ${course?.title ?? 'Загрузка...'}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Шаг ${currentStep + 1} из ${course?.steps.length ?? 0}'),
          SizedBox(height: 20),
          Expanded(
            child:             BoardWidget(
              board: board,
              currentPlayer: PieceColor.white,
              onSquareTap: _onSquareTap,
              selectedPos: selectedPos,
            ),
          ),
          SizedBox(height: 20),
          if (errorMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: errorMessage.contains('Правильно') ||
                        errorMessage.contains('Победа')
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: errorMessage.contains('Правильно') ||
                          errorMessage.contains('Победа')
                      ? Colors.green[800]
                      : Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (isGameOver)
            Column(
              children: [
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(15),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    gameResult,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      board = Board.initial();
                      currentStep = 0;
                      isGameOver = false;
                      gameResult = '';
                      errorMessage = '';
                    });
                  },
                  child: Text('Начать заново'),
                ),
              ],
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
