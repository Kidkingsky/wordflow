import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordflow/models/sentence_pattern.dart';

void main() {
  test('each course phrase has a reusable pattern and three practice contexts', () {
    final course = jsonDecode(File('assets/content/course_content.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final patterns = (course['patterns'] as Map<String, dynamic>).map(
      (id, value) => MapEntry(id,
          SentencePattern.fromJson(value as Map<String, dynamic>)));
    final lessons = (course['lessons'] as List).cast<Map<String, dynamic>>();
    for (final lesson in lessons) {
      for (final id in (lesson['phraseIds'] as List).cast<String>()) {
        expect(patterns.containsKey(id), isTrue, reason: id);
        final pattern = patterns[id]!;
        expect(pattern.formula, isNotEmpty);
        expect(pattern.usage, isNotEmpty);
        expect(pattern.tip, isNotEmpty);
        expect(pattern.focus.length, greaterThanOrEqualTo(2));
        expect(pattern.examples.map((entry) => entry.category).toSet(),
            containsAll(['daily', 'work', 'fitness']));
        for (final example in pattern.examples) {
          expect(example.english, isNotEmpty);
          expect(example.chinese, isNotEmpty);
        }
      }
    }
  });
}
