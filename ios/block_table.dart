import './men.dart';
import './killing.dart';

class BlockTable {
  final int row;
  final int col;
  Men? men;
  bool isHighlight = false;
  bool isHighlightAfterKilling = false;
  bool killableMore = false;
  Killed victim;

  BlockTable({
    required this.row,
    required this.col,
    this.men,
    this.victim = Killed.none,
  });
}