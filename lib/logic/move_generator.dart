import '../models/pos.dart';
import '../models/move.dart';

class MoveGenerator {
  static List<Move> getNormalMoves(int x, int y, List<List<String?>> board) {
    List<Move> moves = [];
    String? piece = board[y][x];
    if (piece == null) return moves;

    bool isKing = piece == piece.toUpperCase();

    List<Pos> directions = [
      Pos(-1, -1),
      Pos(1, -1),
      Pos(-1, 1),
      Pos(1, 1),
    ];

    if (isKing) {
      for (var dir in directions) {
        int nx = x + dir.x;
        int ny = y + dir.y;

        while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8 && board[ny][nx] == null) {
          moves.add(Move(Pos(x, y), Pos(nx, ny)));
          nx += dir.x;
          ny += dir.y;
        }
      }
    } else {
      // обычные шашки ходят только на 1 клетку вперёд
      List<Pos> simpleDirs = piece == "w"
          ? [Pos(-1, -1), Pos(1, -1)]
          : [Pos(-1, 1), Pos(1, 1)];

      for (var dir in simpleDirs) {
        int nx = x + dir.x;
        int ny = y + dir.y;
        if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8 && board[ny][nx] == null) {
          moves.add(Move(Pos(x, y), Pos(nx, ny)));
        }
      }
    }

    return moves;
  }

  static List<Move> getCaptureMoves(int x, int y, List<List<String?>> board) {
    List<Move> captures = [];
    String? piece = board[y][x];
    if (piece == null) return captures;
    bool isKing = piece == piece.toUpperCase();
    String enemy = piece.toLowerCase() == "w" ? "b" : "w";

    List<Pos> directions = [
      Pos(-1, -1), Pos(1, -1),
      Pos(-1, 1), Pos(1, 1),
    ];

    if (isKing) {
      for (var dir in directions) {
        int nx = x + dir.x;
        int ny = y + dir.y;
        bool captured = false;
        List<Pos> path = [];

        while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
          String? cell = board[ny][nx];
          if (cell == null) {
            if (captured) {
              captures.add(Move(Pos(x, y), Pos(nx, ny), captures: [...path]));
            }
            nx += dir.x;
            ny += dir.y;
          } else if (cell.toLowerCase() == enemy && !captured) {
            path = [Pos(nx, ny)];
            captured = true;
            nx += dir.x;
            ny += dir.y;
          } else {
            break;
          }
        }
      }
    } else {
      for (var dir in directions) {
        int mx = x + dir.x;
        int my = y + dir.y;
        int tx = x + 2 * dir.x;
        int ty = y + 2 * dir.y;

        if (tx >= 0 && tx < 8 && ty >= 0 && ty < 8 && board[ty][tx] == null) {
          String? mid = board[my][mx];
          if (mid != null && mid.toLowerCase() == enemy) {
            captures.add(Move(Pos(x, y), Pos(tx, ty), captures: [Pos(mx, my)]));
          }
        }
      }
    }

    return captures;
  }
}
