import '../models/pos.dart';
import 'move_generator.dart';

class CaptureChecker {
  static List<Pos> getMandatoryCaptures(List<List<String?>> board, String player) {
    List<Pos> mustCapture = [];

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        String? piece = board[y][x];
        if (piece != null && piece.toLowerCase() == player) {
          if (MoveGenerator.getCaptureMoves(x, y, board).isNotEmpty) {
            mustCapture.add(Pos(x, y));
          }
        }
      }
    }

    return mustCapture;
  }
}
