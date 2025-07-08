// Логика русских шашек по мотивам lidraughts (TypeScript)
// Только ядро: генерация и применение ходов, правила, дамки, взятия

import 'dart:collection';
import '../models/pos.dart';

enum PieceColor { white, black }

enum PieceType { man, king }

class Piece {
  final PieceColor color;
  PieceType type;
  Piece(this.color, this.type);

  Piece copy() => Piece(color, type);
}

class Move {
  final Pos from;
  final Pos to;
  final List<Pos> captured;
  final bool isCapture;
  Move(this.from, this.to, {this.captured = const [], this.isCapture = false});
}

class Board {
  static const int size = 8;
  final List<List<Piece?>> squares;

  Board._(this.squares);

  factory Board.initial() {
    final squares = List.generate(size, (y) => List<Piece?>.filled(size, null));
    // Расставляем белых
    for (int y = 0; y < 3; y++) {
      for (int x = 0; x < size; x++) {
        if ((x + y) % 2 == 1) {
          squares[y][x] = Piece(PieceColor.white, PieceType.man);
        }
      }
    }
    // Расставляем чёрных
    for (int y = size - 3; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if ((x + y) % 2 == 1) {
          squares[y][x] = Piece(PieceColor.black, PieceType.man);
        }
      }
    }
    return Board._(squares);
  }

  Piece? pieceAt(Pos pos) => squares[pos.y][pos.x];
  void setPiece(Pos pos, Piece? piece) => squares[pos.y][pos.x] = piece;
  Board copy() {
    final newSquares =
        List.generate(size, (y) => List<Piece?>.from(squares[y]));
    return Board._(newSquares);
  }

  bool isInside(Pos pos) =>
      pos.x >= 0 && pos.x < size && pos.y >= 0 && pos.y < size;
}

class DraughtsLogic {
  static const List<Pos> manDirections = [
    Pos(-1, -1), Pos(1, -1), // вверх
    Pos(-1, 1), Pos(1, 1), // вниз
  ];

  static const List<Pos> kingDirections = [
    Pos(-1, -1),
    Pos(1, -1),
    Pos(-1, 1),
    Pos(1, 1)
  ];

  // Генерация всех возможных ходов для данного цвета
  static List<Move> generateMoves(Board board, PieceColor color) {
    List<Move> captures = [];
    List<Move> quietMoves = [];
    for (int y = 0; y < Board.size; y++) {
      for (int x = 0; x < Board.size; x++) {
        final piece = board.squares[y][x];
        if (piece != null && piece.color == color) {
          final from = Pos(x, y);
          // Сначала ищем взятия
          captures.addAll(_generateCaptures(board, from, piece));
        }
      }
    }
    if (captures.isNotEmpty) return captures;
    // Если взятий нет — ищем обычные ходы
    for (int y = 0; y < Board.size; y++) {
      for (int x = 0; x < Board.size; x++) {
        final piece = board.squares[y][x];
        if (piece != null && piece.color == color) {
          final from = Pos(x, y);
          quietMoves.addAll(_generateQuietMoves(board, from, piece));
        }
      }
    }
    return quietMoves;
  }

  // Генерация всех взятий для шашки (возможны многошаговые цепочки)
  static List<Move> _generateCaptures(Board board, Pos from, Piece piece,
      [Set<Pos>? visited, List<Pos>? captured]) {
    visited ??= {from};
    captured ??= [];
    List<Move> result = [];
    final directions =
        piece.type == PieceType.man ? manDirections : kingDirections;
    for (final dir in directions) {
      if (piece.type == PieceType.man) {
        // Простая шашка: только на одну клетку через соперника
        final over = from + dir;
        final to = over + dir;
        if (board.isInside(to) && board.isInside(over)) {
          final overPiece = board.pieceAt(over);
          if (overPiece != null &&
              overPiece.color != piece.color &&
              board.pieceAt(to) == null &&
              !visited.contains(to) &&
              !captured.contains(over)) {
            // Копируем доску для рекурсии
            final newBoard = board.copy();
            newBoard.setPiece(from, null);
            newBoard.setPiece(over, null);
            newBoard.setPiece(to, Piece(piece.color, piece.type));
            final newCaptured = List<Pos>.from(captured)..add(over);
            final newVisited = Set<Pos>.from(visited)..add(to);
            // Рекурсивно ищем продолжение цепочки
            final further =
                _generateCaptures(newBoard, to, piece, newVisited, newCaptured);
            if (further.isEmpty) {
              result
                  .add(Move(from, to, captured: newCaptured, isCapture: true));
            } else {
              for (final m in further) {
                result.add(
                    Move(from, m.to, captured: m.captured, isCapture: true));
              }
            }
          }
        }
      } else {
        // Дамка: может брать на любое расстояние по диагонали
        Pos pos = from + dir;
        bool found = false;
        while (board.isInside(pos)) {
          final p = board.pieceAt(pos);
          if (p == null) {
            pos += dir;
            continue;
          }
          if (p.color == piece.color || captured.contains(pos)) break;
          // нашли шашку соперника, ищем пустые клетки за ней
          Pos landing = pos + dir;
          while (board.isInside(landing) && board.pieceAt(landing) == null) {
            // Копируем доску для рекурсии
            final newBoard = board.copy();
            newBoard.setPiece(from, null);
            newBoard.setPiece(pos, null);
            newBoard.setPiece(landing, Piece(piece.color, piece.type));
            final newCaptured = List<Pos>.from(captured)..add(pos);
            final newVisited = Set<Pos>.from(visited)..add(landing);
            // Рекурсивно ищем продолжение цепочки
            final further = _generateCaptures(
                newBoard, landing, piece, newVisited, newCaptured);
            if (further.isEmpty) {
              result.add(
                  Move(from, landing, captured: newCaptured, isCapture: true));
            } else {
              for (final m in further) {
                result.add(
                    Move(from, m.to, captured: m.captured, isCapture: true));
              }
            }
            landing += dir;
            found = true;
          }
          break;
        }
      }
    }
    return result;
  }

  // Генерация обычных ходов (без взятия)
  static List<Move> _generateQuietMoves(Board board, Pos from, Piece piece) {
    List<Move> result = [];
    final directions =
        piece.type == PieceType.man ? manDirections : kingDirections;
    for (final dir in directions) {
      if (piece.type == PieceType.man) {
        final to = from + dir;
        if (board.isInside(to) && board.pieceAt(to) == null) {
          result.add(Move(from, to));
        }
      } else {
        // Дамка: любое расстояние по диагонали
        Pos pos = from + dir;
        while (board.isInside(pos) && board.pieceAt(pos) == null) {
          result.add(Move(from, pos));
          pos += dir;
        }
      }
    }
    return result;
  }
}

extension BoardApplyMove on Board {
  /// Применяет ход к доске, возвращает новую доску
  Board applyMove(Move move) {
    final newBoard = copy();
    final piece = pieceAt(move.from);
    if (piece == null) throw Exception('Нет шашки на позиции ${move.from}');
    // Удаляем шашку с исходной клетки
    newBoard.setPiece(move.from, null);
    // Удаляем захваченные шашки
    for (final pos in move.captured) {
      newBoard.setPiece(pos, null);
    }
    // Проверяем превращение в дамку
    PieceType type = piece.type;
    if (piece.type == PieceType.man) {
      if ((piece.color == PieceColor.white && move.to.y == 0) ||
          (piece.color == PieceColor.black && move.to.y == Board.size - 1)) {
        type = PieceType.king;
      }
    }
    newBoard.setPiece(move.to, Piece(piece.color, type));
    return newBoard;
  }
}

// Далее будут: генерация ходов, применение хода, правила взятия, дамки и т.д.
