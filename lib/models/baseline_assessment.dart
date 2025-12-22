// Baseline Assessment Models for Student Learning Levels

enum LearningLevel {
  beginner,
  basic,
  comfortable,
}

extension LearningLevelExtension on LearningLevel {
  String get displayName {
    switch (this) {
      case LearningLevel.beginner:
        return 'Beginner';
      case LearningLevel.basic:
        return 'Basic';
      case LearningLevel.comfortable:
        return 'Comfortable';
    }
  }

  String get description {
    switch (this) {
      case LearningLevel.beginner:
        return 'Needs foundational support';
      case LearningLevel.basic:
        return 'Has basic understanding';
      case LearningLevel.comfortable:
        return 'Confident with concepts';
    }
  }
}

class BaselineAssessment {
  final String subject;
  final LearningLevel level;
  final int? score; // Optional manual score (out of 10)
  final DateTime assessedOn;
  final String? notes;

  BaselineAssessment({
    required this.subject,
    required this.level,
    this.score,
    required this.assessedOn,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'level': level.name,
      'score': score,
      'assessedOn': assessedOn.toIso8601String(),
      'notes': notes,
    };
  }

  static BaselineAssessment fromMap(Map<String, dynamic> map) {
    return BaselineAssessment(
      subject: map['subject'] ?? '',
      level: LearningLevel.values.firstWhere(
        (e) => e.name == map['level'],
        orElse: () => LearningLevel.beginner,
      ),
      score: map['score'],
      assessedOn: DateTime.parse(map['assessedOn']),
      notes: map['notes'],
    );
  }
}

// Topic tracking states
enum TopicState {
  notStarted,
  needsRevision,
  understood,
}

extension TopicStateExtension on TopicState {
  String get displayName {
    switch (this) {
      case TopicState.notStarted:
        return 'Not Started';
      case TopicState.needsRevision:
        return 'Needs Revision';
      case TopicState.understood:
        return 'Understood';
    }
  }

  String get emoji {
    switch (this) {
      case TopicState.notStarted:
        return '❌';
      case TopicState.needsRevision:
        return '⚠️';
      case TopicState.understood:
        return '✔️';
    }
  }
}

class TopicProgress {
  final String subject;
  final String topic;
  final TopicState state;
  final DateTime lastUpdated;
  final String? updatedBy; // Volunteer name

  TopicProgress({
    required this.subject,
    required this.topic,
    required this.state,
    required this.lastUpdated,
    this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'topic': topic,
      'state': state.name,
      'lastUpdated': lastUpdated.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  static TopicProgress fromMap(Map<String, dynamic> map) {
    return TopicProgress(
      subject: map['subject'] ?? '',
      topic: map['topic'] ?? '',
      state: TopicState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => TopicState.notStarted,
      ),
      lastUpdated: DateTime.parse(map['lastUpdated']),
      updatedBy: map['updatedBy'],
    );
  }
}