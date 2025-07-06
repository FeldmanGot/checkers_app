class Coordinate {
  final int row;
  final int col;

  const Coordinate({required this.row, required this.col});

  factory Coordinate.of(Coordinate other, {int addRow = 0, int addCol = 0}) => 
    Coordinate(row: other.row + addRow, col: other.col + addCol);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Coordinate && row == other.row && col == other.col;
  }
  
  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}