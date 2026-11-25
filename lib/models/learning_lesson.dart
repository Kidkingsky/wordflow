import 'learning_item.dart';

/// A stable, ordered, topic-based lesson. IDs reference the common library,
/// so progress and favorites remain attached to the original learning items.
class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.level,
    required this.category,
    required this.title,
    required this.objective,
    required this.wordIds,
    required this.phraseIds,
  });

  final String id, level, category, title, objective;
  final List<String> wordIds, phraseIds;

  factory LearningLesson.fromJson(Map<String, dynamic> json) => LearningLesson(
        id: json['id'] as String,
        level: json['level'] as String,
        category: json['category'] as String,
        title: json['title'] as String,
        objective: json['objective'] as String,
        wordIds: (json['wordIds'] as List<dynamic>).cast<String>(),
        phraseIds: (json['phraseIds'] as List<dynamic>).cast<String>(),
      );

  List<LearningItem> resolve(Map<String, LearningItem> items, {required bool words}) =>
      (words ? wordIds : phraseIds).map((id) => items[id]!).toList();
}

/// Keep the editorial course order; category paths are subsequences of it.
List<LearningLesson> eligibleLessons(List<LearningLesson> lessons,
        {required String level, required String category}) =>
    lessons.where((lesson) => lesson.level == level &&
        (category == 'all' || lesson.category == category)).toList();

LearningLesson? selectLesson(List<LearningLesson> lessons,
    {String? selectedId, required Set<String> completedIds}) {
  if (lessons.isEmpty) return null;
  for (final lesson in lessons) {
    if (lesson.id == selectedId) return lesson;
  }
  for (final lesson in lessons) {
    if (!completedIds.contains(lesson.id)) return lesson;
  }
  return lessons.last;
}
