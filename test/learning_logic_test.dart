import 'package:flutter_test/flutter_test.dart';
import 'package:wordflow/logic/learning_logic.dart';
import 'package:wordflow/models/learning_item.dart';
import 'package:wordflow/models/review_record.dart';

void main() {
  const word = LearningItem(
    id: 'w_travel_01',
    kind: 'word',
    category: 'travel',
    level: 'A2',
    english: 'reservation',
    chinese: '預訂',
    note: '飯店或餐廳的預訂',
    example: 'I have a reservation.',
    exampleChinese: '我有預約。',
  );
  const phrase = LearningItem(
    id: 'p_travel_01',
    kind: 'phrase',
    category: 'travel',
    level: 'A2',
    english: 'I would like to check in.',
    chinese: '我想辦理入住。',
    note: '飯店入住',
    example: 'I have a reservation.',
    exampleChinese: '我有訂房。',
  );

  test('daily recommendation is stable for the same day', () {
    final date = DateTime(2026, 11, 21);
    final a = dailyPick(
      [word, phrase],
      today: date,
      kind: 'word',
      category: 'travel',
      level: 'A2',
    );
    final b = dailyPick(
      [phrase, word],
      today: date,
      kind: 'word',
      category: 'travel',
      level: 'A2',
    );
    expect(a?.id, word.id);
    expect(b?.id, word.id);
  });

  test('daily recommendation respects kind, level and category', () {
    expect(
      dailyPick([word, phrase], today: DateTime(2026), kind: 'phrase', category: 'travel', level: 'A2')?.id,
      phrase.id,
    );
    expect(
      dailyPick([word, phrase], today: DateTime(2026), kind: 'word', category: 'fitness', level: 'A2'),
      isNull,
    );
    expect(
      dailyPick([word, phrase], today: DateTime(2026), kind: 'word', category: 'travel', level: 'B1'),
      isNull,
    );
  });

  test('a remembered card is due in 1 day then 3 days', () {
    final firstDay = DateTime(2026, 11, 21);
    final first = ReviewRecord.empty.review(now: firstDay, remembered: true);
    expect(first.nextDueDay, '2026-11-22');
    expect(first.isDue(DateTime(2026, 11, 21)), isFalse);
    expect(first.isDue(DateTime(2026, 11, 22)), isTrue);

    final second = first.review(now: DateTime(2026, 11, 22), remembered: true);
    expect(second.nextDueDay, '2026-11-25');
    final third = second.review(now: DateTime(2026, 11, 25), remembered: true);
    expect(third.mastered, isTrue);
    expect(third.nextDueDay, '2026-12-02');
  });

  test('remembered only counts once per day unless due again', () {
    final day = DateTime(2026, 11, 21);
    expect(ReviewRecord.empty.canCountRemembered(day), isTrue);

    final remembered = ReviewRecord.empty.review(now: day, remembered: true);
    expect(remembered.canCountRemembered(day), isFalse);
    expect(remembered.canCountRemembered(DateTime(2026, 11, 22)), isTrue);

    final forgotten = remembered.review(now: day, remembered: false);
    expect(forgotten.canCountRemembered(day), isTrue);
  });

  test('a forgotten card resets success streak and is due today', () {
    final first = ReviewRecord.empty.review(now: DateTime(2026, 11, 21), remembered: true);
    final retry = first.review(now: DateTime(2026, 11, 22), remembered: false);
    expect(retry.successStreak, 0);
    expect(retry.nextDueDay, '2026-11-22');
    expect(retry.isDue(DateTime(2026, 11, 22)), isTrue);
  });
}
