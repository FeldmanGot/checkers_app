import 'package:flutter/material.dart';
import './coordinate.dart';

class Men {
  final int player;
  Coordinate coordinate;
  bool isKing;

  Men({
    required this.player,
    required this.coordinate,
    this.isKing = false,
  });

  factory Men.of(Men men, {Coordinate? newCoor}) => Men(
    player: men.player,
    coordinate: newCoor ?? men.coordinate,
    isKing: men.isKing,
  );

  void upgradeToKing() {
    isKing = true;
  }
}