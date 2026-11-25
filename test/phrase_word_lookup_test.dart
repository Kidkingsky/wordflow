import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordflow/logic/phrase_word_lookup.dart';
import 'package:wordflow/models/learning_item.dart';

void main() {
  test('tokenizer preserves contractions and hyphenated words', () {
    expect(englishWordTokens("Let's check-in, I'm ready!"),
        ["Let's", 'check-in', "I'm", 'ready']);
  });

  test('normalization unifies smart quotes and casing', () {
    expect(normalizeEnglishWord('I’m'), "i'm");
    expect(normalizeEnglishWord('SINGING'), 'singing');
  });

  test('exact dictionary result preserves its proper Chinese meaning', () {
    const word = LearningItem(
      id: '1', kind: 'word', category: 'travel', level: 'A2',
      english: 'gate', chinese: '登機門', note: '名詞｜登機出入口',
      example: '', exampleChinese: '',
    );
    final result = lookupPhraseWord('Gate', [word]);
    expect(result.chinese, '登機門');
    expect(result.partOfSpeech, '名詞');
    expect(result.catalogItem?.id, '1');
  });

  test('common phrase words have curated Chinese hints', () {
    expect(lookupPhraseWord('the', []).chinese, isNotEmpty);
    expect(lookupPhraseWord('I’m', []).chinese, isNotEmpty);
    expect(lookupPhraseWord('boarding', []).chinese, isNotEmpty);
  });

  test('unknown words are not assigned guessed definitions', () {
    expect(lookupPhraseWord('nonexistenttoken', []).isKnown, isFalse);
  });

  test('all bundled phrases and phrase examples have offline hints', () {
    final raw = File('assets/content/content.json').readAsStringSync();
    final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final course = jsonDecode(File('assets/content/course_content.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final merged = <String, LearningItem>{
      for (final item in data.map(LearningItem.fromJson)) item.id: item,
      for (final item in (course['items'] as List)
          .cast<Map<String, dynamic>>().map(LearningItem.fromJson)) item.id: item,
    };
    final items = merged.values.toList();
    for (final phrase in items.where((item) => !item.isWord)) {
      for (final sentence in [phrase.english, phrase.example]) {
        for (final token in englishWordTokens(sentence)) {
          expect(lookupPhraseWord(token, items).isKnown, isTrue,
            reason: 'Missing '+token+' in phrase: '+sentence);
        }
      }
    }
  });
}
