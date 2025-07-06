import '../models/move.dart';
import '../models/pos.dart';

class CourseController {
  final List<dynamic> steps;
  int currentStep = 0;

  CourseController({required this.steps});

  bool get isFinished => currentStep >= steps.length;
  
  // Определяем, чей ход по номеру шага (четные - белые, нечетные - черные)
  bool get isUserTurn {
    if (isFinished) return false;
    // Пользователь играет за белых, ходы белых - четные индексы (0, 2, 4, ...)
    return currentStep % 2 == 0;
  }

  // Получаем текущий ход для отображения
  String get currentSide {
    if (isFinished) return '';
    return currentStep % 2 == 0 ? 'w' : 'b';
  }

  // Конвертируем алгебраическую нотацию в координаты
  Pos _parsePosition(String notation) {
    final file = notation[0]; // a-h
    final rank = notation[1]; // 1-8
    
    final x = file.codeUnitAt(0) - 'a'.codeUnitAt(0); // a=0, b=1, ..., h=7
    final y = 8 - int.parse(rank); // 8=0, 7=1, ..., 1=7 (переворачиваем доску)
    
    return Pos(x, y);
  }

  bool checkUserMove(Move move) {
    if (isFinished || !isUserTurn) return false;
    
    final expected = steps[currentStep];
    final expectedFrom = _parsePosition(expected['from']);
    final expectedTo = _parsePosition(expected['to']);
    
    if (move.from.x == expectedFrom.x &&
        move.from.y == expectedFrom.y &&
        move.to.x == expectedTo.x &&
        move.to.y == expectedTo.y) {
      currentStep++;
      return true;
    }
    return false;
  }

  // Выполняем ход противника автоматически
  Move? makeOpponentMove() {
    if (isFinished || isUserTurn) return null;

    final moveData = steps[currentStep];
    final from = _parsePosition(moveData['from']);
    final to = _parsePosition(moveData['to']);
    
    // Для взятий нужно определить съеденные фигуры
    List<Pos> captures = [];
    if (moveData['capture'] == true) {
      // Простое взятие - фигура между from и to
      final dx = to.x - from.x;
      final dy = to.y - from.y;
      if (dx.abs() == 2 && dy.abs() == 2) {
        captures.add(Pos(from.x + dx ~/ 2, from.y + dy ~/ 2));
      }
    }
    
    final move = Move(from, to, captures: captures);
    currentStep++;
    return move;
  }

  // Получаем все ходы противника, которые нужно выполнить сейчас
  List<Move> getAllPendingOpponentMoves() {
    List<Move> opponentMoves = [];
    while (!isFinished && !isUserTurn) {
      final move = makeOpponentMove();
      if (move != null) {
        opponentMoves.add(move);
      }
    }
    return opponentMoves;
  }
}