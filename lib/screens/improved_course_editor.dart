import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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

class ImprovedCourseEditor extends StatefulWidget {
  final Course? existingCourse;

  const ImprovedCourseEditor({Key? key, this.existingCourse}) : super(key: key);

  @override
  State<ImprovedCourseEditor> createState() => _ImprovedCourseEditorState();
}

enum EditorMode { moves, setup }

class _ImprovedCourseEditorState extends State<ImprovedCourseEditor> {
  late Board board;
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

  // Поля для метаданных курса
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final List<TextEditingController> _commentControllers = [];

  PieceColor get currentTurn => moveColor;

  @override
  void initState() {
    super.initState();
    
    // Если редактируем существующий курс
    if (widget.existingCourse != null) {
      _loadExistingCourse();
    } else {
      _initializeNewCourse();
    }
  }

  void _initializeNewCourse() {
    board = Board.initial();
    moves = [];
    moveColors = [];
    moveColor = firstMoveColor;
    _titleController.text = 'Новый курс';
    _descriptionController.text = 'Описание курса';
    _authorController.text = 'Автор';
  }

  void _loadExistingCourse() {
    final course = widget.existingCourse!;
    _titleController.text = course.title;
    _descriptionController.text = course.description;
    _authorController.text = course.author;
    
    // Загружаем ходы из курса
    board = Board.initial();
    moves = [];
    moveColors = [];
    _commentControllers.clear();
    
    for (final step in course.steps) {
      final from = pdnToPos(step.from);
      final to = pdnToPos(step.to);
      
      // Находим соответствующий Move
      final piece = board.pieceAt(from);
      if (piece != null) {
        final possibleMoves = DraughtsLogic.generateMoves(board, piece.color);
        final move = possibleMoves.firstWhereOrNull(
          (m) => m.from == from && m.to == to,
        );
        
        if (move != null) {
          moves.add(move);
          moveColors.add(piece.color);
          board = board.applyMove(move);
          
          // Добавляем контроллер для комментария
          final commentController = TextEditingController();
          commentController.text = step.comment;
          _commentControllers.add(commentController);
        }
      }
    }
    
    moveColor = firstMoveColor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    for (final controller in _commentControllers) {
      controller.dispose();
    }
    super.dispose();
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
    
    // Режим ходов
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
            
            // Добавляем контроллер для комментария к новому ходу
            final commentController = TextEditingController();
            commentController.text = 'Ход ${moves.length}';
            _commentControllers.add(commentController);
            
            // Переключаем цвет хода
            moveColor = moveColor == PieceColor.white ? PieceColor.black : PieceColor.white;
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
        if (_commentControllers.isNotEmpty) {
          _commentControllers.removeLast().dispose();
        }
        
        // Пересчитываем доску
        board = Board.initial();
        for (final move in moves) {
          board = board.applyMove(move);
        }
        _selected = null;
        
        // Восстанавливаем цвет хода
        moveColor = moves.length % 2 == 0 ? firstMoveColor : 
                   (firstMoveColor == PieceColor.white ? PieceColor.black : PieceColor.white);
      });
    }
  }

  void _clearBoard() {
    setState(() {
      board = Board.initial();
      moves.clear();
      moveColors.clear();
      for (final controller in _commentControllers) {
        controller.dispose();
      }
      _commentControllers.clear();
      _selected = null;
      moveColor = firstMoveColor;
    });
  }

  Future<void> _saveCourse() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Введите название курса');
      return;
    }

    try {
      final course = _createCourseFromEditor();
      await _saveCourseToFile(course);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Курс успешно сохранен!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop(course);
    } catch (e) {
      _showMessage('Ошибка сохранения: $e');
    }
  }

  Course _createCourseFromEditor() {
    List<MoveStep> steps = [];
    
    for (int i = 0; i < moves.length; i++) {
      final move = moves[i];
      final color = moveColors[i];
      final comment = i < _commentControllers.length ? _commentControllers[i].text : '';
      
      steps.add(MoveStep(
        from: posToPDN(move.from),
        to: posToPDN(move.to),
        side: color == PieceColor.white ? 'w' : 'b',
        comment: comment,
        capture: move.isCapture,
        captured: move.captured.map((pos) => posToPDN(pos)).toList(),
        auto: false,
      ));
    }
    
    return Course(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      author: _authorController.text.trim(),
      steps: steps,
      userColor: userColor,
      created: DateTime.now(),
    );
  }

  Future<void> _saveCourseToFile(Course course) async {
    final directory = await getApplicationDocumentsDirectory();
    final coursesDir = Directory('${directory.path}/courses');
    
    if (!await coursesDir.exists()) {
      await coursesDir.create(recursive: true);
    }
    
    // Создаем безопасное имя файла
    final fileName = course.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    
    final file = File('${coursesDir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.json');
    
    final courseJson = {
      'title': course.title,
      'description': course.description,
      'author': course.author,
      'created': course.created.toIso8601String(),
      'userColor': course.userColor == PieceColor.white ? 'white' : 'black',
      'steps': course.steps.map((step) => {
        'from': step.from,
        'to': step.to,
        'side': step.side,
        'comment': step.comment,
        'capture': step.capture,
        'captured': step.captured,
        'auto': step.auto,
      }).toList(),
    };
    
    await file.writeAsString(jsonEncode(courseJson));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактор курсов'),
        backgroundColor: const Color(0xFF1B1B1B),
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
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Отменить последний ход',
            onPressed: _undoMove,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Очистить доску',
            onPressed: _clearBoard,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Сохранить курс',
            onPressed: _saveCourse,
          ),
        ],
      ),
      body: Row(
        children: [
          // Левая панель - информация о курсе и ходы
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildCourseInfoPanel(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildMovesList()),
                ],
              ),
            ),
          ),
          
          // Центр - доска
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildGameControls(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildBoard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о курсе',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Автор',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: mode == EditorMode.moves
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ходят: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: moveColor == PieceColor.white ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      moveColor == PieceColor.white ? 'Белые' : 'Чёрные',
                      style: TextStyle(
                        color: moveColor == PieceColor.white ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text('Ходов: ${moves.length}'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Добавить: '),
                  DropdownButton<PieceColor>(
                    value: setupColor,
                    items: const [
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
                  const SizedBox(width: 16),
                  DropdownButton<PieceType>(
                    value: setupType,
                    items: const [
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
    );
  }

  Widget _buildBoard() {
    return BoardWidget(
      board: board,
      currentPlayer: moveColor,
      onSquareTap: _onSquareTap,
      selectedPos: _selected,
      reverseBoard: _reverseRows,
      showCoordinates: true,
    );
  }

  Widget _buildMovesList() {
    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Список ходов',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: moves.length,
              itemBuilder: (context, index) {
                final move = moves[index];
                final color = moveColors[index];
                final commentController = index < _commentControllers.length 
                    ? _commentControllers[index] 
                    : null;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color == PieceColor.white ? Colors.white : Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${index + 1}. ${posToPDN(move.from)}-${posToPDN(move.to)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (move.isCapture)
                              const Icon(Icons.close, color: Colors.red, size: 16),
                          ],
                        ),
                        if (commentController != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: 'Комментарий к ходу',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(8),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}