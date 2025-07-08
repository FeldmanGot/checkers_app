import 'dart:convert';
import 'package:flutter/services.dart';

class LessonProgress {
  final String lessonId;
  final bool completed;
  final DateTime? completedAt;
  final int attempts;
  final int correctMoves;
  final int totalMoves;
  final double accuracy;
  final int hintsUsed;
  final DateTime? lastStudied;

  LessonProgress({
    required this.lessonId,
    this.completed = false,
    this.completedAt,
    this.attempts = 0,
    this.correctMoves = 0,
    this.totalMoves = 0,
    this.accuracy = 0.0,
    this.hintsUsed = 0,
    this.lastStudied,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'] ?? '',
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      attempts: json['attempts'] ?? 0,
      correctMoves: json['correctMoves'] ?? 0,
      totalMoves: json['totalMoves'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      hintsUsed: json['hintsUsed'] ?? 0,
      lastStudied: json['lastStudied'] != null
          ? DateTime.parse(json['lastStudied'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'attempts': attempts,
      'correctMoves': correctMoves,
      'totalMoves': totalMoves,
      'accuracy': accuracy,
      'hintsUsed': hintsUsed,
      'lastStudied': lastStudied?.toIso8601String(),
    };
  }

  LessonProgress copyWith({
    bool? completed,
    DateTime? completedAt,
    int? attempts,
    int? correctMoves,
    int? totalMoves,
    double? accuracy,
    int? hintsUsed,
    DateTime? lastStudied,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      attempts: attempts ?? this.attempts,
      correctMoves: correctMoves ?? this.correctMoves,
      totalMoves: totalMoves ?? this.totalMoves,
      accuracy: accuracy ?? this.accuracy,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      lastStudied: lastStudied ?? this.lastStudied,
    );
  }
}

class CourseProgress {
  final String courseId;
  final List<LessonProgress> lessonProgresses;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int streak;
  final DateTime? lastStudied;

  CourseProgress({
    required this.courseId,
    required this.lessonProgresses,
    required this.startedAt,
    this.completedAt,
    this.streak = 0,
    this.lastStudied,
  });

  double get overallProgress {
    if (lessonProgresses.isEmpty) return 0.0;
    final completed = lessonProgresses.where((p) => p.completed).length;
    return completed / lessonProgresses.length;
  }

  double get averageAccuracy {
    if (lessonProgresses.isEmpty) return 0.0;
    final accuracies =
        lessonProgresses.where((p) => p.totalMoves > 0).map((p) => p.accuracy);
    if (accuracies.isEmpty) return 0.0;
    return accuracies.reduce((a, b) => a + b) / accuracies.length;
  }

  bool get isCompleted => lessonProgresses.every((p) => p.completed);

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] ?? '',
      lessonProgresses: (json['lessonProgresses'] as List? ?? [])
          .map((progressJson) => LessonProgress.fromJson(progressJson))
          .toList(),
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      streak: json['streak'] ?? 0,
      lastStudied: json['lastStudied'] != null
          ? DateTime.parse(json['lastStudied'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'lessonProgresses': lessonProgresses.map((p) => p.toJson()).toList(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'streak': streak,
      'lastStudied': lastStudied?.toIso8601String(),
    };
  }
}

// Singleton класс для управления прогрессом
class ProgressManager {
  static final ProgressManager _instance = ProgressManager._internal();
  factory ProgressManager() => _instance;
  ProgressManager._internal();

  final Map<String, CourseProgress> _courseProgresses = {};

  Map<String, CourseProgress> get courseProgresses =>
      Map.unmodifiable(_courseProgresses);

  CourseProgress? getCourseProgress(String courseId) {
    return _courseProgresses[courseId];
  }

  LessonProgress? getLessonProgress(String courseId, String lessonId) {
    final courseProgress = _courseProgresses[courseId];
    if (courseProgress == null) return null;

    try {
      return courseProgress.lessonProgresses
          .firstWhere((p) => p.lessonId == lessonId);
    } catch (e) {
      return null;
    }
  }

  void updateLessonProgress(String courseId, LessonProgress lessonProgress) {
    var courseProgress = _courseProgresses[courseId];

    if (courseProgress == null) {
      courseProgress = CourseProgress(
        courseId: courseId,
        lessonProgresses: [lessonProgress],
        startedAt: DateTime.now(),
        lastStudied: DateTime.now(),
      );
      _courseProgresses[courseId] = courseProgress;
      return;
    }

    final existingIndex = courseProgress.lessonProgresses
        .indexWhere((p) => p.lessonId == lessonProgress.lessonId);

    if (existingIndex != -1) {
      courseProgress.lessonProgresses[existingIndex] = lessonProgress;
    } else {
      courseProgress.lessonProgresses.add(lessonProgress);
    }

    // Обновляем время последнего обучения
    _courseProgresses[courseId] = CourseProgress(
      courseId: courseProgress.courseId,
      lessonProgresses: courseProgress.lessonProgresses,
      startedAt: courseProgress.startedAt,
      completedAt: courseProgress.isCompleted ? DateTime.now() : null,
      streak: courseProgress.streak,
      lastStudied: DateTime.now(),
    );
  }

  // Методы для сохранения/загрузки прогресса (в реальном приложении - в базу данных)
  void saveProgress() {
    // Здесь можно реализовать сохранение в SharedPreferences или базу данных
  }

  void loadProgress() {
    // Здесь можно реализовать загрузку из SharedPreferences или базы данных
  }
}
