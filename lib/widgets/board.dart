import 'package:flutter/material.dart';
import '../logic/move_generator.dart';
import '../logic/capture_checker.dart';
import '../logic/capture_processor.dart';
import '../models/pos.dart';
import '../models/move.dart';
import '../logic/victory_checker.dart';

class CheckersBoard extends StatefulWidget {
  final String fen;

  const CheckersBoard({super.key, required this.fen});

  @override
  State<CheckersBoard> createState() => _CheckersBoardState();
}

class _CheckersBoardState extends State<CheckersBoard> {
  late List<List<String?>> board;
  String currentPlayer = "w";
  int? selectedX;
  int? selectedY;
  List<Move> possibleMoves = [];
  List<Pos> mustCapture = [];

  @override
  void initState() {
    super.initState();
    board = List.generate(8, (y) => List.generate(8, (x) {
      if ((x + y) % 2 == 1) {
        if (y <= 2) return "b";
        if (y >= 5) return "w";
      }
      return null;
    }));
    mustCapture = CaptureChecker.getMandatoryCaptures(board, currentPlayer);
  }

  void _onCellTap(int x, int y) {
    final tapped = Pos(x, y);
    final piece = board[y][x];
    final isDark = (x + y) % 2 == 1;

    if (!isDark) return;

    setState(() {
      if (selectedX == null && piece != null && piece.toLowerCase() == currentPlayer) {
        final allCaptures = CaptureChecker.getMandatoryCaptures(board, currentPlayer);

        if (allCaptures.any((p) => p == tapped)) {
          possibleMoves = MoveGenerator.getCaptureMoves(x, y, board);
          mustCapture = allCaptures;
          selectedX = x;
          selectedY = y;
        } else if (allCaptures.isEmpty) {
          possibleMoves = MoveGenerator.getNormalMoves(x, y, board);
          selectedX = x;
          selectedY = y;
        }
      } else if (selectedX != null) {
        final move = possibleMoves.firstWhere(
          (m) => m.to == tapped,
          orElse: () => Move(const Pos(-1, -1), const Pos(-1, -1)),
        );

        if (move.to.x != -1) {
          CaptureProcessor.applyMove(move, board);
// Проверка на победу после хода
final winByElimination = VictoryChecker.checkWinByElimination(board);
final winByNoMoves = VictoryChecker.checkWinByNoMoves(board, currentPlayer == "w" ? "b" : "w");

if (winByElimination != null || winByNoMoves != null) {
  String winner = winByElimination ?? winByNoMoves!;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Game Over"),
      content: Text("Player ${winner == "w" ? "White" : "Black"} wins!"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              // перезапускаем игру
              board = List.generate(8, (y) => List.generate(8, (x) {
                if ((x + y) % 2 == 1) {
                  if (y <= 2) return "b";
                  if (y >= 5) return "w";
                }
                return null;
              }));
              currentPlayer = "w";
              selectedX = null;
              selectedY = null;
              possibleMoves = [];
              mustCapture = CaptureChecker.getMandatoryCaptures(board, currentPlayer);
            });
          },
          child: const Text("New Game"),
        )
      ],
    ),
  );
  return; // Прерываем дальнейшую обработку хода
}

          final furtherCaptures = MoveGenerator.getCaptureMoves(move.to.x, move.to.y, board);
          if (move.captures.isNotEmpty && furtherCaptures.isNotEmpty) {
            selectedX = move.to.x;
            selectedY = move.to.y;
            possibleMoves = furtherCaptures;
            return;
          }

          currentPlayer = currentPlayer == "w" ? "b" : "w";
          selectedX = null;
          selectedY = null;
          possibleMoves = [];
          mustCapture = CaptureChecker.getMandatoryCaptures(board, currentPlayer);
        } else {
          selectedX = null;
          selectedY = null;
          possibleMoves = [];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final boardSize = (screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height) * 0.9;
    const checkerRatio = 0.85;

    return Center(
      child: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Column(
              children: List.generate(8, (y) {
                return Expanded(
                  child: Row(
                    children: List.generate(8, (x) {
                      final isPossibleTarget = possibleMoves.any(
                        (m) => m.to.x == x && m.to.y == y,
                      );
                      final isDark = (x + y) % 2 == 1;
                      final piece = board[y][x];
                      final isSelected = selectedX == x && selectedY == y;

                      return GestureDetector(
                        onTap: () => _onCellTap(x, y),
                        child: Container(
                          width: boardSize / 8,
                          height: boardSize / 8,
                          color: isPossibleTarget
                              ? Colors.greenAccent
                              : isDark
                                  ? Colors.brown[700]
                                  : Colors.brown[300],
                          child: Center(
                            child: piece != null
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: (boardSize / 8) * checkerRatio,
                                    height: (boardSize / 8) * checkerRatio,
                                    decoration: BoxDecoration(
                                      color: piece.toLowerCase() == "w"
                                          ? Colors.white
                                          : Colors.black,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.yellow : Colors.black,
                                        width: isSelected ? 3 : 1.5,
                                      ),
                                    ),
                                    child: piece == piece.toUpperCase()
                                        ? const Center(
                                            child: Text(
                                              "D", // дамка
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                          )
                                        : null,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
