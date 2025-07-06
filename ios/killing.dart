import './men.dart';

class Killed {
  final bool isKilled;
  final Men? men;

  const Killed({required this.isKilled, required this.men});

  static const none = Killed(isKilled: false, men: null);
}