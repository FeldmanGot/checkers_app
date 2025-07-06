import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import './game_table.dart';
import './coordinate.dart';
import './men.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Шашечный тренажер',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DraughtsTrainer(),
    );
  }
}

class DraughtsTrainer extends StatefulWidget {
  const DraughtsTrainer({super.key});

  @override
  State<DraughtsTrainer> createState() => _DraughtsTrainerState();
}

class _DraughtsTrainerState extends State<DraughtsTrainer> {
  late GameTable gameTable;
  double blockSize = 1;
  Map<String, dynamic>? currentCourse;
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    initGame();
    loadCourse();
  }

  void initGame() {
    gameTable = GameTable();
    gameTable.initMenOnTable();
  }

  Future<void> loadCourse() async {
    try {
      final data = await rootBundle.loadString('assets/kurs_1.json');
      setState(() {
        currentCourse = jsonDecode(data);
      });
    } catch (e) {
      debugPrint('Ошибка загрузки курса: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    initScreenSize(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCourse?['title'] ?? 'Шашечный тренажер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(initGame),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: buildGameTable(),
            ),
          ),
          if (currentCourse != null) buildCourseControls(),
        ],
      ),
    );
  }

  Widget buildGameTable() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5C3B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(gameTable.countRow, (row) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(gameTable.countCol, (col) {
            final coor = Coordinate(row: row, col: col);
            return buildBlock(coor);
          }),
        ),
      ),
    );
  }

  Widget buildBlock(Coordinate coor) {
    final block = gameTable.getBlockTable(coor);
    final isLight = gameTable.isBlockTypeF(coor);
    final isSelected = gameTable.selectedCoordinate == coor;
    final isPossibleMove = gameTable.possibleMoves.contains(coor);

    return GestureDetector(
      onTap: () => handleBlockTap(coor),
      child: Container(
        width: blockSize,
        height: blockSize,
        decoration: BoxDecoration(
          color: isPossibleMove 
              ? const Color(0xFFF7F769)
              : isLight 
                  ? const Color(0xFFEBECD0)
                  : const Color(0xFF779556),
          border: isSelected 
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: block.men != null 
            ? buildMenWidget(block.men!)
            : null,
      ),
    );
  }

  Widget buildMenWidget(Men men) {
    return Center(
      child: Container(
        width: blockSize * 0.8,
        height: blockSize * 0.8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: men.player == 1 ? Colors.white : Colors.black,
          border: men.isKing 
              ? Border.all(color: const Color(0xFFF7F769), width: 2)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(0, 1),
          ],
        ),
        child: men.isKing
            ? Icon(
                Icons.star,
                color: men.player == 1 ? Colors.black : Colors.white,
                size: blockSize * 0.4,
              )
            : null,
      ),
    );
  }

  void handleBlockTap(Coordinate coor) {
    setState(() {
      // Если выбрана шашка текущего игрока
      if (hasCurrentPlayerMen(coor)) {
        gameTable.selectedCoordinate = coor;
        gameTable.possibleMoves = gameTable.getPossibleMoves(coor);
      } 
      // Если выбран возможный ход
      else if (gameTable.possibleMoves.contains(coor)) {
        gameTable.moveMen(gameTable.selectedCoordinate!, coor);
      }
    });
  }

  bool hasCurrentPlayerMen(Coordinate coor) {
    return gameTable.hasMen(coor) && 
           gameTable.getBlockTable(coor).men!.player == gameTable.currentPlayerTurn;
  }

  Widget buildCourseControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        children: [
          Text(
            currentCourse!['steps'][currentStep]['description'] ?? '',
            style: const TextStyle(fontSize: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: currentStep > 0 
                    ? () => setState(() => currentStep--)
                    : null,
              ),
              Text('Шаг ${currentStep + 1} из ${currentCourse!['steps'].length}'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: currentStep < currentCourse!['steps'].length - 1
                    ? () => setState(() => currentStep++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void initScreenSize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    blockSize = (shortestSide / 8) - 4;
  }
}