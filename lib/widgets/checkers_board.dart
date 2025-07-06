import 'package:flutter/material.dart';
import '../models/pos.dart';
import '../models/move.dart';

typedef OnUserMove = void Function(Pos from, Pos to);

class CheckersBoard extends StatefulWidget {
  final OnUserMove onUserMove;
  final List<Move> moves;

  const CheckersBoard({Key? key, required this.onUserMove, required this.moves}) : super(key: key);

  @override
  _CheckersBoardState createState() => _CheckersBoardState();
}

class _CheckersBoardState extends State<CheckersBoard> {
  static const int size = 8;

  List<List<int>> board = List.generate(
    size,
    (y) => List.generate(size, (x) => 0),
  );

  Pos? selected;

  @override
  void initState() {
    super.initState();
    _setupInitialBoard();
    _applyMoves(widget.moves);
  }

  @override
  void didUpdateWidget(covariant CheckersBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moves != widget.moves) {
      _setupInitialBoard();
      _applyMoves(widget.moves);
    }
  }

  void _setupInitialBoard() {
    board = List.generate(
      size,
      (y) => List.generate(size, (x) {
        if ((x + y) % 2 == 1 && y < 3) return 2; // черные шашки
        if ((x + y) % 2 == 1 && y > 4) return 1; // белые шашки
        return 0;
      }),
    );
  }

  void _applyMoves(List<Move> moves) {
    for (final move in moves) {
      final piece = board[move.from.y][move.from.x];
      board[move.from.y][move.from.x] = 0;
      board[move.to.y][move.to.x] = piece;
      for (final cap in move.captures) {
        board[cap.y][cap.x] = 0;
      }
    }
    setState(() {});
  }

  void _onSquareTap(int x, int y) {
    if (selected == null) {
      if (board[y][x] != 0) {
        setState(() {
          selected = Pos(x, y);
        });
      }
    } else {
      final from = selected!;
      final to = Pos(x, y);
      if (from == to) {
        setState(() {
          selected = null;
        });
        return;
      }
      widget.onUserMove(from, to);
      setState(() {
        selected = null;
      });
    }
  }

  Widget _buildSquare(int x, int y) {
    final isDark = (x + y) % 2 == 1;
    final color = isDark ? Colors.brown[700] : Colors.brown[300];

    Widget? piece;
    if (board[y][x] == 1) {
      piece = _buildPiece(Colors.white);
    } else if (board[y][x] == 2) {
      piece = _buildPiece(Colors.black);
    }

    final isSelected = selected?.x == x && selected?.y == y;

    return GestureDetector(
      onTap: () => _onSquareTap(x, y),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow : color,
        ),
        child: Center(child: piece),
      ),
    );
  }

  Widget _buildPiece(Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        itemCount: size * size,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
        ),
        itemBuilder: (context, index) {
          final x = index % size;
          final y = index ~/ size;
          return _buildSquare(x, y);
        },
      ),
    );
  }
}
