import 'pos.dart';

class Move {
  final Pos from;
  final Pos to;
  final List<Pos> captures;

  const Move(this.from, this.to, {this.captures = const []});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Move &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}
