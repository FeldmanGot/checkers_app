import '../models/pos.dart';
import '../models/move.dart';
import 'move_generator.dart';

class VictoryChecker {
  // 1. Победа по съедению всех шашек
  static String? checkWinByElimination(List<List<String?>> board) {
    bool hasWhite = false;
    bool hasBlack = false;

    for (var row in board) {
      for (var cell in row) {
        if (cell == null) continue;
        if (cell.toLowerCase() == "w") hasWhite = true;
        if (cell.toLowerCase() == "b") hasBlack = true;
      }
    }

    if (!hasWhite) return "b"; // чёрные победили
    if (!hasBlack) return "w"; // белые победили

    return null;
  }

  // 2. Победа по невозможности хода
  static String? checkWinByNoMoves(List<List<String?>> board, String currentPlayer) {
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final piece = board[y][x];
        if (piece != null && piece.toLowerCase() == currentPlayer) {
          final normal = MoveGenerator.getNormalMoves(x, y, board);
          final capture = MoveGenerator.getCaptureMoves(x, y, board);
          if (normal.isNotEmpty || capture.isNotEmpty) {
            return null; // Ходы есть, никто не победил
          }
        }
      }
    }

    // Ходов нет
    return currentPlayer == "w" ? "b" : "w"; // Победил соперник
  }

  // 3. Условие победы по обучающим ходам (как в Chessable)
  static bool checkTrainingGoalReached(
      List<Move> executedMoves, List<Move> expectedMoves) {
    if (executedMoves.length != expectedMoves.length) return false;

    for (int i = 0; i < executedMoves.length; i++) {
      if (executedMoves[i] != expectedMoves[i]) return false;
    }
    return true;
  }
}
