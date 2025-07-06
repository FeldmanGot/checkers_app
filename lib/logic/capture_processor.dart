import '../models/move.dart';
import '../models/pos.dart';

class CaptureProcessor {
  static void applyMove(Move move, List<List<String?>> board) {
    final piece = board[move.from.y][move.from.x];
    board[move.from.y][move.from.x] = null;
    board[move.to.y][move.to.x] = piece;

    // Удаление съеденных шашек
    for (final pos in move.captures) {
      board[pos.y][pos.x] = null;
    }

    // Повышение в дамку
    if (piece == 'w' && move.to.y == 0) {
      board[move.to.y][move.to.x] = 'W';
    }
    if (piece == 'b' && move.to.y == 7) {
      board[move.to.y][move.to.x] = 'B';
    }
  }
}
