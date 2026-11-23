import 'package:flutter_test/flutter_test.dart';
import 'package:wordflow/models/word_family.dart';
import 'package:wordflow/services/speech_service.dart';

void main() {
  final care = WordFamily.fromJson({
    'id': 'care',
    'root': 'care',
    'meaning': '在乎',
    'tip': '-ful 充滿，-less 沒有',
    'members': [
      {'english': 'careful', 'chinese': '小心的', 'hint': '-ful'},
      {'english': 'Careless', 'chinese': '粗心的', 'hint': '-less'},
      {'english': 'take care of', 'chinese': '照顧', 'hint': '片語'},
    ],
  });
  final take = WordFamily.fromJson({
    'id': 'take',
    'root': 'take',
    'meaning': '拿',
    'members': [
      {'english': 'take care of', 'chinese': '照顧', 'hint': '片語'},
    ],
  });

  test('family index finds a family from the root or any member', () {
    final index = indexFamilies([care, take]);
    expect(index['care']?.single.id, 'care');
    expect(index['careless']?.single.id, 'care', reason: 'lookup is lower-case');
    expect(index['take care of']?.map((f) => f.id), ['care', 'take']);
    expect(index['unknown'], isNull);
  });

  test('voice ranking prefers high quality US voices over novelty voices', () {
    final premium = scoreVoice(name: 'Ava', locale: 'en-US', quality: 'premium');
    final compact = scoreVoice(name: 'Samantha', locale: 'en-US', quality: 'default');
    final british = scoreVoice(name: 'Daniel', locale: 'en-GB', quality: 'default');
    final novelty = scoreVoice(name: 'Zarvox', locale: 'en-US', quality: 'default');
    expect(premium, greaterThan(compact));
    expect(compact, greaterThan(british));
    expect(british, greaterThan(novelty));
  });
}
