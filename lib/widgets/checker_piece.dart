import 'package:flutter/material.dart';
import '../logic/lidraughts_russian.dart' show PieceColor, PieceType;

class CheckerPiece extends StatelessWidget {
  final bool isWhite;
  final bool isKing;
  final bool isSelected;
  final double size;

  const CheckerPiece({
    Key? key,
    required this.isWhite,
    required this.isKing,
    this.isSelected = false,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getPieceColor(),
        border: isSelected
            ? Border.all(color: Colors.yellow, width: 3)
            : Border.all(color: Colors.black26, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isKing ? _buildKingCrown() : null,
    );
  }

  Color _getPieceColor() {
    if (isWhite) {
      return isKing
          ? const Color(0xFFF0F0F0) // Светло-серый для белой дамки
          : const Color(0xFFFFFFFF); // Белый для простой шашки
    } else {
      return isKing
          ? const Color(0xFF8B4513) // Коричневый для чёрной дамки
          : const Color(0xFF8B0000); // Тёмно-красный для простой шашки
    }
  }

  Widget _buildKingCrown() {
    return Center(
      child: Container(
        width: size * 0.4,
        height: size * 0.4,
        decoration: BoxDecoration(
          color: isWhite ? Colors.amber : Colors.yellow,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black54,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.star,
          size: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}
