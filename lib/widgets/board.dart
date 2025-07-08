import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../logic/lidraughts_russian.dart'
    show Board, Piece, PieceColor, PieceType, DraughtsLogic, Move;
import '../models/pos.dart';
import 'checker_piece.dart';

class BoardWidget extends StatefulWidget {
  final Board board;
  final PieceColor currentPlayer;
  final Function(int, int, int, int)? onUserMove;
  final Function(Pos)? onSquareTap;
  final Pos? selectedPos;
  final bool showCoordinates;
  final bool reverseBoard;

  const BoardWidget({
    Key? key,
    required this.board,
    required this.currentPlayer,
    this.onUserMove,
    this.onSquareTap,
    this.selectedPos,
    this.showCoordinates = false,
    this.reverseBoard = false,
  }) : super(key: key);

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  Pos? selectedPos;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54, width: 2),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final x = index % 8;
            final y = index ~/ 8;

            // Применяем reverseBoard если нужно
            final displayY = widget.reverseBoard ? (7 - y) : y;
            final pos = Pos(x, displayY);

            final piece = widget.board.pieceAt(pos);
            final isDark = (x + displayY) % 2 == 1;
            final isSelected = widget.selectedPos == pos || selectedPos == pos;

            return GestureDetector(
              onTap: isDark ? () => _handleSquareTap(pos) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: _getSquareColor(isDark, isSelected),
                  border: Border.all(
                    color: isSelected ? Colors.yellow : Colors.transparent,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: piece != null
                    ? Center(
                        child: CheckerPiece(
                          isWhite: piece.color == PieceColor.white,
                          isKing: piece.type == PieceType.king,
                          isSelected: isSelected,
                          size: 40.0,
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getSquareColor(bool isDark, bool isSelected) {
    if (isSelected) {
      return const Color(0xFFB59F3B); // lichess highlight
    }
    return isDark
        ? const Color(0xFF8B7355) // Тёмные клетки
        : const Color(0xFFEEEED2); // Светлые клетки
  }

  void _handleSquareTap(Pos pos) {
    print(
        '🎯 BoardWidget: _handleSquareTap вызван для позиции: ${pos.x},${pos.y}');
    print('🎯 BoardWidget: onSquareTap != null: ${widget.onSquareTap != null}');

    if (widget.onSquareTap != null) {
      print('🎯 BoardWidget: Вызываем onSquareTap!');
      widget.onSquareTap!(pos);
      return;
    }

    print('🎯 BoardWidget: onSquareTap == null, используем старую логику');
    if (widget.onUserMove == null) return;

    final piece = widget.board.pieceAt(pos);

    if (piece != null && piece.color == widget.currentPlayer) {
      setState(() {
        selectedPos = pos;
      });
      return;
    }

    if (piece == null && selectedPos != null) {
      final from = selectedPos!;
      final to = pos;

      final possibleMoves =
          DraughtsLogic.generateMoves(widget.board, widget.currentPlayer);
      final move = possibleMoves.firstWhereOrNull(
        (m) => m.from == from && m.to == to,
      );

      if (move != null) {
        widget.onUserMove!(from.y, from.x, to.y, to.x);

        setState(() {
          selectedPos = null;
        });
      }
    }
  }
}
