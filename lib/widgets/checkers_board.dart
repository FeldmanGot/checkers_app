import 'package:flutter/material.dart';
import '../models/pos.dart';
import '../models/move.dart';

typedef OnUserMove = void Function(Pos from, Pos to);

class CheckersBoard extends StatefulWidget {
  final OnUserMove onUserMove;
  final List<Move> moves;
  final Move? hintMove; // для показа подсказки
  final bool showHint;

  const CheckersBoard({
    Key? key, 
    required this.onUserMove, 
    required this.moves,
    this.hintMove,
    this.showHint = false,
  }) : super(key: key);

  @override
  _CheckersBoardState createState() => _CheckersBoardState();
}

class _CheckersBoardState extends State<CheckersBoard> with TickerProviderStateMixin {
  static const int size = 8;
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

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
    
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _hintAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showHint) {
      _hintController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CheckersBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moves != widget.moves) {
      _setupInitialBoard();
      _applyMoves(widget.moves);
    }
    
    if (widget.showHint && !oldWidget.showHint) {
      _hintController.repeat(reverse: true);
    } else if (!widget.showHint && oldWidget.showHint) {
      _hintController.stop();
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
    final isSelected = selected?.x == x && selected?.y == y;
    final isHintFrom = widget.hintMove?.from.x == x && widget.hintMove?.from.y == y;
    final isHintTo = widget.hintMove?.to.x == x && widget.hintMove?.to.y == y;

    Color squareColor;
    if (isSelected) {
      squareColor = Colors.amber;
    } else if (isDark) {
      squareColor = const Color(0xFF8B4513); // коричневый
    } else {
      squareColor = const Color(0xFFDEB887); // бежевый
    }

    Widget? piece;
    if (board[y][x] == 1) {
      piece = _buildPiece(Colors.white, isSelected: isSelected);
    } else if (board[y][x] == 2) {
      piece = _buildPiece(Colors.black, isSelected: isSelected);
    }

    Widget square = Container(
      decoration: BoxDecoration(
        color: squareColor,
        border: Border.all(color: Colors.black54, width: 0.5),
      ),
      child: Center(child: piece),
    );

    // Добавляем анимацию подсказки
    if (widget.showHint && (isHintFrom || isHintTo)) {
      square = AnimatedBuilder(
        animation: _hintAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: squareColor,
              border: Border.all(
                color: isHintFrom ? Colors.green : Colors.blue,
                width: 3.0 * _hintAnimation.value,
              ),
            ),
            child: Center(child: piece),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => _onSquareTap(x, y),
      child: square,
    );
  }

  Widget _buildPiece(Color color, {bool isSelected = false}) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: color == Colors.white 
              ? [Colors.white, Colors.grey[300]!]
              : [Colors.grey[800]!, Colors.black],
          stops: const [0.3, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.amber : Colors.black87,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color == Colors.white 
                ? Colors.grey[200]! 
                : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color == Colors.white 
                  ? Colors.grey[400] 
                  : Colors.grey[700],
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
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
        ),
      ),
    );
  }
}