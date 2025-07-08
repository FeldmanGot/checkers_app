import 'package:flutter/material.dart';
import '../models/pos.dart';
import '../models/move.dart';

typedef OnUserMove = void Function(Pos from, Pos to);

class EnhancedCheckersBoard extends StatefulWidget {
  final OnUserMove onUserMove;
  final List<Move> moves;
  final String? position; // Позиция в FEN-подобном формате
  final Move? hintMove;
  final bool showHint;

  const EnhancedCheckersBoard({
    Key? key,
    required this.onUserMove,
    required this.moves,
    this.position,
    this.hintMove,
    this.showHint = false,
  }) : super(key: key);

  @override
  _EnhancedCheckersBoardState createState() => _EnhancedCheckersBoardState();
}

class _EnhancedCheckersBoardState extends State<EnhancedCheckersBoard>
    with TickerProviderStateMixin {
  static const int size = 8;
  late AnimationController _hintController;
  late AnimationController _moveController;
  late Animation<double> _hintAnimation;
  late Animation<double> _moveAnimation;

  List<List<int>> board = List.generate(
    size,
    (y) => List.generate(size, (x) => 0),
  );

  Pos? selected;
  Move? lastMove;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupBoard();
    _applyMoves(widget.moves);
  }

  void _setupAnimations() {
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _hintAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeInOut,
    ));

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _moveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOut,
    ));

    if (widget.showHint) {
      _hintController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnhancedCheckersBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.position != widget.position) {
      _setupBoard();
      _applyMoves(widget.moves);
    } else if (oldWidget.moves != widget.moves) {
      _setupBoard();
      _applyMoves(widget.moves);
      if (widget.moves.isNotEmpty) {
        lastMove = widget.moves.last;
        _moveController.forward(from: 0);
      }
    }

    if (widget.showHint && !oldWidget.showHint) {
      _hintController.repeat(reverse: true);
    } else if (!widget.showHint && oldWidget.showHint) {
      _hintController.stop();
    }
  }

  void _setupBoard() {
    if (widget.position != null && widget.position!.isNotEmpty) {
      _loadPositionFromString(widget.position!);
    } else {
      _setupInitialBoard();
    }
  }

  void _loadPositionFromString(String position) {
    // Формат: "белые_позиции:черные_позиции"
    // Пример: "b2,d2,f2,h2,a3,c3,e3,g3:b6,d6,f6,h6,a7,c7,e7,g7"

    // Очищаем доску
    board = List.generate(
      size,
      (y) => List.generate(size, (x) => 0),
    );

    try {
      final parts = position.split(':');
      if (parts.length >= 1 && parts[0].isNotEmpty) {
        // Белые шашки
        final whitePieces = parts[0].split(',');
        for (final piece in whitePieces) {
          if (piece.trim().length >= 2) {
            final pos = _parseAlgebraicNotation(piece.trim());
            if (pos != null) {
              board[pos.y][pos.x] = 1; // Белые шашки
            }
          }
        }
      }

      if (parts.length >= 2 && parts[1].isNotEmpty) {
        // Черные шашки
        final blackPieces = parts[1].split(',');
        for (final piece in blackPieces) {
          if (piece.trim().length >= 2) {
            final pos = _parseAlgebraicNotation(piece.trim());
            if (pos != null) {
              board[pos.y][pos.x] = 2; // Черные шашки
            }
          }
        }
      }
    } catch (e) {
      print('Ошибка загрузки позиции: $e');
      _setupInitialBoard();
    }
  }

  Pos? _parseAlgebraicNotation(String notation) {
    try {
      if (notation.length < 2) return null;
      final file = notation[0];
      final rank = notation[1];
      final x = file.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final y = 8 - int.parse(rank);

      if (x >= 0 && x < 8 && y >= 0 && y < 8) {
        return Pos(x, y);
      }
    } catch (e) {
      print('Ошибка парсинга нотации $notation: $e');
    }
    return null;
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

      // Убираем съеденные шашки
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
    final isLastMoveFrom = lastMove?.from.x == x && lastMove?.from.y == y;
    final isLastMoveTo = lastMove?.to.x == x && lastMove?.to.y == y;
    final isHintFrom =
        widget.hintMove?.from.x == x && widget.hintMove?.from.y == y;
    final isHintTo = widget.hintMove?.to.x == x && widget.hintMove?.to.y == y;

    Color squareColor;
    if (isSelected) {
      squareColor = Colors.amber;
    } else if (isLastMoveFrom || isLastMoveTo) {
      squareColor = isDark ? const Color(0xFF6B4423) : const Color(0xFFE6C787);
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
              borderRadius: BorderRadius.circular(4 * _hintAnimation.value),
            ),
            child: Center(child: piece),
          );
        },
      );
    }

    // Добавляем анимацию последнего хода
    if ((isLastMoveFrom || isLastMoveTo) && _moveController.isAnimating) {
      square = AnimatedBuilder(
        animation: _moveAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (0.1 * _moveAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                color: squareColor,
                border: Border.all(
                  color: Colors.yellow.withOpacity(_moveAnimation.value),
                  width: 2.0 * _moveAnimation.value,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(child: piece),
            ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 38 : 35,
      height: isSelected ? 38 : 35,
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
            blurRadius: isSelected ? 6 : 4,
            offset: Offset(isSelected ? 3 : 2, isSelected ? 3 : 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                color == Colors.white ? Colors.grey[200]! : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  color == Colors.white ? Colors.grey[400] : Colors.grey[700],
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateLabel(String text, {bool isFile = false}) {
    return Container(
      width: isFile ? null : 20,
      height: isFile ? 20 : null,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          // Буквы файлов сверху
          Row(
            children: [
              const SizedBox(width: 20), // отступ для цифр рангов
              ...List.generate(8, (index) {
                return Expanded(
                  child: _buildCoordinateLabel(
                    String.fromCharCode('a'.codeUnitAt(0) + index),
                    isFile: true,
                  ),
                );
              }),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                // Цифры рангов слева
                Column(
                  children: List.generate(8, (index) {
                    return Expanded(
                      child: _buildCoordinateLabel('${8 - index}'),
                    );
                  }),
                ),
                // Игровая доска
                Expanded(
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
