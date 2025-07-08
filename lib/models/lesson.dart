class LessonMove {
  final String move;
  final String side;
  final String type; // user, forced, hint
  final String explanation;
  final bool isCorrect;

  LessonMove({
    required this.move,
    required this.side,
    required this.type,
    required this.explanation,
    this.isCorrect = true,
  });

  factory LessonMove.fromJson(Map<String, dynamic> json) {
    return LessonMove(
      move: json['move'] ?? '',
      side: json['side'] ?? '',
      type: json['type'] ?? 'user',
      explanation: json['explanation'] ?? '',
      isCorrect: json['isCorrect'] ?? true,
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String type; // interactive, puzzle, practice
  final String position;
  final String explanation;
  final List<LessonMove> moves;
  final List<LessonMove> solution;
  final List<String> hints;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.position,
    required this.explanation,
    required this.moves,
    this.solution = const [],
    this.hints = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'interactive',
      position: json['position'] ?? '',
      explanation: json['explanation'] ?? '',
      moves: (json['moves'] as List? ?? [])
          .map((moveJson) => LessonMove.fromJson(moveJson))
          .toList(),
      solution: (json['solution'] as List? ?? [])
          .map((moveJson) => LessonMove.fromJson(moveJson))
          .toList(),
      hints: List<String>.from(json['hints'] ?? []),
    );
  }
}

class ExtendedCourse {
  final String id;
  final String title;
  final String author;
  final String description;
  final String difficulty;
  final String category;
  final List<Lesson> lessons;
  final List<String> tags;
  final int estimatedTime;
  final double rating;

  ExtendedCourse({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.lessons,
    required this.tags,
    required this.estimatedTime,
    required this.rating,
  });

  factory ExtendedCourse.fromJson(Map<String, dynamic> json) {
    return ExtendedCourse(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      category: json['category'] ?? 'general',
      lessons: (json['lessons'] as List? ?? [])
          .map((lessonJson) => Lesson.fromJson(lessonJson))
          .toList(),
      tags: List<String>.from(json['tags'] ?? []),
      estimatedTime: json['estimatedTime'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}
