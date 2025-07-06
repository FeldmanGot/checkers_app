import './block_table.dart';
import './coordinate.dart';
import './killing.dart';
import './men.dart';

class GameTable {
  static const int MODE_WALK_NORMAL = 1;
  static const int MODE_WALK_AFTER_KILLING = 2;
  
  final int countRow;
  final int countCol;
  late final List<List<BlockTable>> table;
  int currentPlayerTurn = 1; // 1 - белые, 2 - черные
  Coordinate? selectedCoordinate;
  List<Coordinate> possibleMoves = [];

  GameTable({this.countRow = 8, this.countCol = 8}) {
    init();
  }

  void init() {
    table = List.generate(countRow, (row) => 
      List.generate(countCol, (col) => BlockTable(row: row, col: col));
  }

  void initMenOnTable() {
    // Белые шашки (игрок 1)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < countCol; col++) {
        if ((row + col) % 2 == 1) {
          addMen(Coordinate(row: row, col: col), player: 1);
        }
      }
    }
    
    // Черные шашки (игрок 2)
    for (int row = countRow - 3; row < countRow; row++) {
      for (int col = 0; col < countCol; col++) {
        if ((row + col) % 2 == 1) {
          addMen(Coordinate(row: row, col: col), player: 2);
        }
      }
    }
  }

  BlockTable getBlockTable(Coordinate coor) => table[coor.row][coor.col];

  bool isBlockAvailable(Coordinate coor) {
    return coor.row >= 0 && coor.row < countRow && 
           coor.col >= 0 && coor.col < countCol;
  }

  bool hasMen(Coordinate coor) => 
      isBlockAvailable(coor) && getBlockTable(coor).men != null;

  bool hasMenEnemy(Coordinate coor) => 
      hasMen(coor) && getBlockTable(coor).men!.player != currentPlayerTurn;

  bool isBlockTypeF(Coordinate coor) => (coor.row + coor.col) % 2 == 0;

  void addMen(Coordinate coor, {required int player, bool isKing = false}) {
    if (!isBlockTypeF(coor)) {
      getBlockTable(coor).men = Men(
        player: player, 
        coordinate: coor,
        isKing: isKing
      );
    }
  }

  void moveMen(Coordinate from, Coordinate to) {
    final men = getBlockTable(from).men!;
    getBlockTable(from).men = null;
    getBlockTable(to).men = men;
    men.coordinate = to;
    
    // Проверка на превращение в дамку
    if ((men.player == 1 && to.row == countRow - 1) || 
        (men.player == 2 && to.row == 0)) {
      men.upgradeToKing();
    }
    
    togglePlayerTurn();
  }

  void togglePlayerTurn() {
    currentPlayerTurn = currentPlayerTurn == 1 ? 2 : 1;
    selectedCoordinate = null;
    possibleMoves.clear();
  }

  List<Coordinate> getPossibleMoves(Coordinate coor) {
    final moves = [];
    final men = getBlockTable(coor).men;
    if (men == null) return moves;

    // Простые шашки
    if (!men.isKing) {
      final direction = men.player == 1 ? 1 : -1;
      checkSimpleMove(moves, coor, direction);
      checkCaptureMoves(moves, coor, direction);
    } 
    // Дамки
    else {
      checkKingMoves(moves, coor);
    }

    return moves;
  }

  void checkSimpleMove(List<Coordinate> moves, Coordinate coor, int direction) {
    final left = Coordinate(row: coor.row + direction, col: coor.col - 1);
    final right = Coordinate(row: coor.row + direction, col: coor.col + 1);

    if (isBlockAvailable(left) && !hasMen(left)) moves.add(left);
    if (isBlockAvailable(right) && !hasMen(right)) moves.add(right);
  }

  void checkCaptureMoves(List<Coordinate> moves, Coordinate coor, int direction) {
    // Логика взятия для простых шашек
    final directions = [
      Coordinate(row: direction, col: -1),
      Coordinate(row: direction, col: 1),
    ];

    for (final dir in directions) {
      final enemyPos = Coordinate(row: coor.row + dir.row, col: coor.col + dir.col);
      final landingPos = Coordinate(row: coor.row + 2 * dir.row, col: coor.col + 2 * dir.col);

      if (isBlockAvailable(enemyPos) && 
          isBlockAvailable(landingPos) &&
          hasMenEnemy(enemyPos) && 
          !hasMen(landingPos)) {
        moves.add(landingPos);
      }
    }
  }

  void checkKingMoves(List<Coordinate> moves, Coordinate coor) {
    // Логика ходов для дамок
    for (int rowDir = -1; rowDir <= 1; rowDir += 2) {
      for (int colDir = -1; colDir <= 1; colDir += 2) {
        var currentRow = coor.row + rowDir;
        var currentCol = coor.col + colDir;

        while (isBlockAvailable(Coordinate(row: currentRow, col: currentCol))) {
          final currentPos = Coordinate(row: currentRow, col: currentCol);
          if (hasMen(currentPos)) break;

          moves.add(currentPos);
          currentRow += rowDir;
          currentCol += colDir;
        }
      }
    }
  }
}