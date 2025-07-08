class MoveStep {
  final String from;
  final String to;
  final bool capture;
  final String side;
  final String comment;
  final bool auto;
  final List<String> captured;

  MoveStep({
    required this.from,
    required this.to,
    required this.capture,
    required this.side,
    required this.comment,
    this.auto = false,
    this.captured = const [],
  });

  factory MoveStep.fromJson(Map<String, dynamic> json) {
    return MoveStep(
      from: json['from'],
      to: json['to'],
      capture: json['capture'],
      side: json['side'],
      comment: json['comment'],
      auto: json['auto'] ?? false,
      captured:
          json['captured'] != null ? List<String>.from(json['captured']) : [],
    );
  }
}

class Course {
  final String id;
  final String title;
  final String author;
  final String description;
  final List<MoveStep> steps;

  Course({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.steps,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      steps: (json['steps'] as List)
          .map((stepJson) => MoveStep.fromJson(stepJson))
          .toList(),
    );
  }
}
