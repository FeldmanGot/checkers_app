import '../models/move.dart';
import '../models/pos.dart';

class CourseController {
  final List<dynamic> steps;
  int currentStep = 0;

  CourseController({required this.steps});

  bool get isFinished => currentStep >= steps.length;
  bool get isUserTurn => !isFinished && steps[currentStep]['side'] == 'w';

  bool checkUserMove(Move move) {
    final expected = steps[currentStep];
    if (move.from.x == expected['from'][0] &&
        move.from.y == expected['from'][1] &&
        move.to.x == expected['to'][0] &&
        move.to.y == expected['to'][1]) {
      currentStep++;
      return true;
    }
    return false;
  }

Move? makeOpponentMove() {
  if (isFinished || steps[currentStep]['side'] != 'b') return null;

  final moveData = steps[currentStep];
  final move = Move(
    Pos(moveData['from'][0], moveData['from'][1]),
    Pos(moveData['to'][0], moveData['to'][1]),
    captures: (moveData['captures'] as List?)?.map<Pos>((cap) => Pos(cap[0], cap[1])).toList() ?? [],
  );
  currentStep++;
  return move;
}
}
