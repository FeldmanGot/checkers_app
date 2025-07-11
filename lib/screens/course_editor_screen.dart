import 'package:flutter/material.dart';
import '../logic/lidraughts_russian.dart'
    show
        Board,
        Piece,
        PieceColor,
        PieceType,
        DraughtsLogic,
        Move,
        BoardApplyMove;
import 'package:collection/collection.dart';
import '../logic/pdn_utils.dart';
import '../models/pos.dart';
import '../models/course.dart';
import '../widgets/board.dart';
import '../services/course_service.dart';

class CourseEditorScreen extends StatefulWidget {
  const CourseEditorScreen({Key? key}) : super(key: key);

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

enum EditorMode { moves, setup }

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  Board board = Board.initial();
  List<Move> moves = [];
  List<PieceColor> moveColors = [];
  PieceColor userColor = PieceColor.white;
  final PieceColor firstMoveColor = PieceColor.white;
  bool get _reverseRows => userColor == PieceColor.black;
  EditorMode mode = EditorMode.moves;
  PieceColor moveColor = PieceColor.white;
  PieceColor setupColor = PieceColor.white;
  PieceType setupType = PieceType.man;
  Pos? _selected;

  PieceColor get currentTurn => moveColor;

  @override
  void initState() {
    super.initState();
    board = Board.initial();
    moves = [];
    moveColor = firstMoveColor;
  }

  void _onSquareTap(Pos pos) {
    if (mode == EditorMode.setup) {
      final piece = board.pieceAt(pos);
      setState(() {
        if (piece == null) {
          board.setPiece(pos, Piece(setupColor, setupType));
        } else {
          // Если клик по шашке — удаляем, либо меняем тип
          if (piece.type == PieceType.man) {
            board.setPiece(pos, Piece(piece.color, PieceType.king));
          } else {
            board.setPiece(pos, null);
          }
        }
      });
      return;
    }
    // Режим ходов: свободный выбор цвета хода
    if (_selected == null) {
      final piece = board.pieceAt(pos);
      if (piece != null && piece.color == moveColor) {
        setState(() {
          _selected = pos;
        });
      }
    } else {
      final from = _selected!;
      final to = pos;
      final piece = board.pieceAt(from);
      if (piece != null && from != to) {
        final possibleMoves = DraughtsLogic.generateMoves(board, moveColor);
        final move = possibleMoves.firstWhereOrNull(
          (m) => m.from == from && m.to == to,
        );
        if (move != null) {
          setState(() {
            board = board.applyMove(move);
            moves.add(move);
            moveColors.add(piece.color);
            _selected = null;
          });
        } else {
          setState(() {
            _selected = null;
          });
        }
      } else {
        setState(() {
          _selected = null;
        });
      }
    }
  }

  void _undoMove() {
    if (moves.isNotEmpty) {
      setState(() {
        moves.removeLast();
        moveColors.removeLast();
        board = Board.initial();
        for (final move in moves) {
          board = board.applyMove(move);
        }
        _selected = null;
      });
    }
  }

  void _switchUserColor() {
    setState(() {
      userColor =
          userColor == PieceColor.white ? PieceColor.black : PieceColor.white;
    });
  }

  void _clearBoard() {
    setState(() {
      board = Board.initial();
      moves.clear();
      moveColors.clear();
      _selected = null;
    });
  }

  void _exportPDN() {
    final pdn = _generatePDN();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт PDN'),
        content: SingleChildScrollView(
          child: SelectableText(pdn),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  String _generatePDN() {
    final now = DateTime.now();
    final white = userColor == PieceColor.white ? 'User' : 'Engine';
    final black = userColor == PieceColor.black ? 'User' : 'Engine';
    final fen = _boardToFEN(Board.initial());
    final headers = [
      '[Event "Custom Course"]',
      '[Site "draughts_trainer"]',
      '[Date "${now.year.toString().padLeft(4, '0')}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}"]',
      '[White "$white"]',
      '[Black "$black"]',
      '[FEN "$fen"]',
      '[Annotator "draughts_trainer"]',
    ];
    final movesStr = _movesToPDN(moves);
    return headers.join('\n') + '\n\n' + movesStr;
  }

  String _boardToFEN(Board board) {
    // Преобразует текущую позицию в FEN lidraughts
    // W:W...:B...
    List<String> white = [];
    List<String> black = [];
    for (int y = 0; y < Board.size; y++) {
      for (int x = 0; x < Board.size; x++) {
        final piece = board.squares[y][x];
        if (piece != null) {
          final square = posToPDN(Pos(x, y));
          final s = (piece.type == PieceType.king ? 'K' : '') + square;
          if (piece.color == PieceColor.white) {
            white.add(s);
          } else {
            black.add(s);
          }
        }
      }
    }
    return 'W:W${white.join(',')}:B${black.join(',')}';
  }

  String _movesToPDN(List<Move> moves) {
    List<String> result = [];
    int moveNum = 1;
    for (int i = 0; i < moves.length; i += 2) {
      final whiteMove = i < moves.length
          ? '${posToPDN(moves[i].from)}-${posToPDN(moves[i].to)}'
          : '';
      final blackMove = (i + 1) < moves.length
          ? '${posToPDN(moves[i + 1].from)}-${posToPDN(moves[i + 1].to)}'
          : '';
      if (blackMove.isNotEmpty) {
        result.add('$moveNum. $whiteMove $blackMove');
      } else {
        result.add('$moveNum. $whiteMove');
      }
      moveNum++;
    }
    return result.join(' ');
  }

  String _moveToString(Move move) {
    return '${posToPDN(move.from)}-${posToPDN(move.to)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактор курса (PDN)'),
        actions: [
          IconButton(
            icon: Icon(mode == EditorMode.setup ? Icons.edit : Icons.grid_on),
            tooltip: mode == EditorMode.setup
                ? 'Режим ходов'
                : 'Редактировать доску',
            onPressed: () {
              setState(() {
                mode = mode == EditorMode.setup
                    ? EditorMode.moves
                    : EditorMode.setup;
                _selected = null;
              });
            },
          ),
          if (mode == EditorMode.moves)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Я играю за... (сменить цвет)',
              onPressed: _switchUserColor,
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Очистить доску',
            onPressed: _clearBoard,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Сохранить в курсы',
            onPressed: _saveToCourses,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Удалить последний ход',
            onPressed: _undoMove,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Экспортировать PDN',
            onPressed: _exportPDN,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: mode == EditorMode.moves
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Ходят: '),
                      DropdownButton<PieceColor>(
                        value: moveColor,
                        items: [
                          DropdownMenuItem(
                            value: PieceColor.white,
                            child: Text('Белые'),
                          ),
                          DropdownMenuItem(
                            value: PieceColor.black,
                            child: Text('Чёрные'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => moveColor = v);
                        },
                      ),
                      const SizedBox(width: 24),
                      Text(
                          'Вы играете за: ${userColor == PieceColor.white ? 'Белых' : 'Чёрных'}'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Добавить: '),
                      DropdownButton<PieceColor>(
                        value: setupColor,
                        items: [
                          DropdownMenuItem(
                            value: PieceColor.white,
                            child: Text('Белая'),
                          ),
                          DropdownMenuItem(
                            value: PieceColor.black,
                            child: Text('Чёрная'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => setupColor = v);
                        },
                      ),
                      DropdownButton<PieceType>(
                        value: setupType,
                        items: [
                          DropdownMenuItem(
                            value: PieceType.man,
                            child: Text('Шашка'),
                          ),
                          DropdownMenuItem(
                            value: PieceType.king,
                            child: Text('Дамка'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => setupType = v);
                        },
                      ),
                    ],
                  ),
          ),
          Expanded(
            flex: 3,
            child: _buildBoard(),
          ),
          Expanded(
            flex: 2,
            child: _buildMoveList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return BoardWidget(
      board: board,
      currentPlayer: moveColor,
      onSquareTap: _onSquareTap,
      selectedPos: _selected,
      reverseBoard: _reverseRows,
    );
  }

  Widget _buildMoveList() {
    return ListView.builder(
      itemCount: moves.length,
      itemBuilder: (context, index) {
        final move = moves[index];
        return ListTile(
          title: Text('${index + 1}. ${_moveToString(move)}'),
        );
      },
    );
  }

  void _saveToCourses() async {
    if (moves.isEmpty) {
      _showMessage('Добавьте хотя бы один ход перед сохранением курса');
      return;
    }

    final result = await _showSaveCourseDialog();
    if (result != null) {
      final course = _createCourse(result);
      final success = await CourseService.saveUserCourse(course);
      
      if (success) {
        _showMessage('Курс успешно сохранен!');
        Navigator.of(context).pop(course);
      } else {
        _showMessage('Ошибка при сохранении курса');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Map<String, String>?> _showSaveCourseDialog() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить курс'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Название курса',
                  hintText: 'Введите название...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(
                  labelText: 'Автор',
                  hintText: 'Введите имя автора...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Введите описание курса...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название курса')),
                );
                return;
              }
              
              Navigator.of(context).pop({
                'title': titleController.text.trim(),
                'author': authorController.text.trim().isEmpty 
                    ? 'Аноним' 
                    : authorController.text.trim(),
                'description': descriptionController.text.trim().isEmpty 
                    ? 'Пользовательский курс' 
                    : descriptionController.text.trim(),
              });
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _moveToStepMap(Move m, int index) {
    // Преобразуем Move в Map совместимый с MoveStep
    // Используем сохранённый цвет хода
    final side = moveColors[index] == PieceColor.white ? 'white' : 'black';
    return {
      'from': posToPDN(m.from),
      'to': posToPDN(m.to),
      'capture': m.isCapture,
      'side': side,
      'comment': '',
      'auto': false,
      'captured': [],
    };
  }

  Course _createCourse(Map<String, String> metadata) {
    final steps = moves
        .asMap()
        .entries
        .map((entry) => _createMoveStep(entry.value, entry.key))
        .toList();

    return Course(
      id: CourseService.generateCourseId(),
      title: metadata['title']!,
      author: metadata['author']!,
      description: metadata['description']!,
      steps: steps,
    );
  }

  MoveStep _createMoveStep(Move move, int index) {
    final side = moveColors[index] == PieceColor.white ? 'w' : 'b';
    return MoveStep(
      from: posToPDN(move.from),
      to: posToPDN(move.to),
      capture: move.isCapture,
      side: side,
      comment: move.isCapture 
        ? 'Взятие ${move.captured.length} шашек' 
        : 'Обычный ход',
    );
  }
}
