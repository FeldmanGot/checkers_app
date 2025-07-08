class Pos {
  final int x;
  final int y;
  const Pos(this.x, this.y);

  @override
  String toString() => 'Pos($x,$y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pos &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Pos operator +(Pos other) => Pos(x + other.x, y + other.y);
  Pos operator -(Pos other) => Pos(x - other.x, y - other.y);
}
