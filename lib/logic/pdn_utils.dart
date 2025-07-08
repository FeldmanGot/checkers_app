import '../models/pos.dart';

/// Преобразует позицию (x, y) в PDN-нотацию (a1-h8), где a1 — правый нижний угол (x=7, y=0)
String posToPDN(Pos pos) {
  final file = String.fromCharCode('a'.codeUnitAt(0) + (7 - pos.x));
  final rank = (pos.y + 1).toString();
  return '$file$rank';
}

/// Преобразует PDN-нотацию (a1-h8) в позицию (x, y), где a1 — правый нижний угол (x=7, y=0)
Pos pdnToPos(String pdn) {
  final file = pdn[0];
  final rank = int.parse(pdn.substring(1));
  final x = 7 - (file.codeUnitAt(0) - 'a'.codeUnitAt(0));
  final y = rank - 1;
  return Pos(x, y);
}
