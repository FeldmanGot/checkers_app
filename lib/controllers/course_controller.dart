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
    // Проверяем, что строка имеет правильный формат
    if (notation.length < 2) {
      throw ArgumentError('Invalid position notation: $notation');
    }
    
    final file = notation[0]; // a-h
    final rank = notation[1]; // 1-8
    
    // Проверяем, что файл и ранг корректны
    if (file.codeUnitAt(0) < 'a'.codeUnitAt(0) || 
        file.codeUnitAt(0) > 'h'.codeUnitAt(0)) {
      throw ArgumentError('Invalid file in position: $notation');
    }
    
    final rankInt = int.tryParse(rank);
    if (rankInt == null || rankInt < 1 || rankInt > 8) {
      throw ArgumentError('Invalid rank in position: $notation');
    }
    
    final x = file.codeUnitAt(0) - 'a'.codeUnitAt(0); // a=0, b=1, ..., h=7
    final y = 8 - rankInt; // 8=0, 7=1, ..., 1=7 (переворачиваем доску)
    
    return Pos(x, y);
  }

  bool checkUserMove(Move move) {
    if (isFinished || !isUserTurn) return false;
    
    try {
      final expected = steps[currentStep];
      
      // Проверяем, что expected имеет нужные поля
      if (expected['from'] == null || expected['to'] == null) {
        print('Invalid step data at index $currentStep: $expected');
        return false;
      }
      
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
    } catch (e) {
      print('Error in checkUserMove: $e');
      return false;
    }
  }

  // Выполняем ход противника автоматически
  Move? makeOpponentMove() {
    if (isFinished || isUserTurn) return null;

    try {
      final moveData = steps[currentStep];
      
      // Проверяем, что moveData имеет нужные поля
      if (moveData['from'] == null || moveData['to'] == null) {
        print('Invalid move data at index $currentStep: $moveData');
        return null;
      }
      
      final from = _parsePosition(moveData['from']);
      final to = _parsePosition(moveData['to']);
      
      // Для взятий нужно определить съеденные фигуры
      List<Pos> captures = [];
      if (moveData['capture'] == true) {
        // Взятие - определяем направление и находим съеденные фигуры
        final dx = to.x - from.x;
        final dy = to.y - from.y;
        
        // Проверяем, что это диагональное движение
        if (dx.abs() == dy.abs() && dx.abs() > 1) {
          // Направление движения
          final stepX = dx > 0 ? 1 : -1;
          final stepY = dy > 0 ? 1 : -1;
          
          // Добавляем все позиции между from и to как потенциально съеденные
          // (в реальной игре здесь была бы логика определения, какие именно фигуры съедаются)
          for (int step = 1; step < dx.abs(); step++) {
            captures.add(Pos(from.x + step * stepX, from.y + step * stepY));
          }
        }
      }
      
      final move = Move(from, to, captures: captures);
      currentStep++;
      return move;
    } catch (e) {
      print('Error in makeOpponentMove: $e');
      return null;
    }
  }

  // Получаем все ходы противника, которые нужно выполнить сейчас
  List<Move> getAllPendingOpponentMoves() {
    List<Move> opponentMoves = [];
    while (!isFinished && !isUserTurn) {
      final move = makeOpponentMove();
      if (move != null) {
        opponentMoves.add(move);
      } else {
        break; // Прерываем цикл, если не удалось создать ход
      }
    }
    return opponentMoves;
  }
}