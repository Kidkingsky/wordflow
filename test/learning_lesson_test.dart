import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordflow/models/learning_item.dart';
import 'package:wordflow/models/learning_lesson.dart';

void main() {
  final course = jsonDecode(File('assets/content/course_content.json').readAsStringSync())
      as Map<String, dynamic>;
  final lessons = (course['lessons'] as List).cast<Map<String, dynamic>>()
      .map(LearningLesson.fromJson).toList();
  final base = (jsonDecode(File('assets/content/content.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final items = <String, LearningItem>{
    for (final item in [...base, ...(course['items'] as List).cast<Map<String, dynamic>>()]
        .map(LearningItem.fromJson)) item.id: item,
  };
  test('course starts at the first incomplete lesson and respects topic order', () {
    final path = eligibleLessons(lessons, level: 'A2', category: 'daily');
    expect(path.length, greaterThanOrEqualTo(3));
    expect(selectLesson(path, completedIds: {})?.id, 'a2_daily_01');
    expect(selectLesson(path, completedIds: {'a2_daily_01'})?.id, 'a2_daily_02');
    expect(selectLesson(path, selectedId: 'a2_daily_01',
        completedIds: {'a2_daily_01'})?.id, 'a2_daily_01');
    expect(selectLesson(path, completedIds: path.map((l) => l.id).toSet())?.id,
        path.last.id);
    expect(eligibleLessons(lessons, level: 'B1', category: 'all').length, greaterThanOrEqualTo(12));
  });
  test('every lesson links to four words and at least two bilingual phrases', () {
    expect(lessons.length, greaterThanOrEqualTo(24));
    for (final lesson in lessons) {
      final words = lesson.resolve(items, words: true);
      final phrases = lesson.resolve(items, words: false);
      expect(words.length, 4);
      expect(phrases.length, greaterThanOrEqualTo(2));
      for (final item in [...words, ...phrases]) {
        expect(item.example, isNotEmpty);
        expect(item.exampleChinese, isNotEmpty);
      }
      expect(words.every((item) => item.isWord), isTrue);
      expect(phrases.every((item) => !item.isWord), isTrue);
    }
  });
}
