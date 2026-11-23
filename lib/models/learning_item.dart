class LearningItem {
  const LearningItem({
    required this.id,
    required this.kind,
    required this.category,
    required this.level,
    required this.english,
    required this.chinese,
    required this.note,
    required this.example,
    required this.exampleChinese,
  });

  final String id;
  final String kind; // word | phrase
  final String category; // travel | daily | fitness | work
  final String level; // A2 | B1
  final String english;
  final String chinese;
  final String note;
  final String example;
  final String exampleChinese;

  bool get isWord => kind == 'word';

  /// The vocabulary stores the grammatical class at the start of note.
  String get partOfSpeech {
    if (!isWord) return '';
    final label = note.split('｜').first.trim();
    const wordClasses = <String>{
      '名詞', '動詞', '形容詞', '副詞', '介系詞', '連接詞',
      '代名詞', '名詞／動詞', '動詞／名詞', '名詞片語',
      '名詞複數', '常用詞',
    };
    return wordClasses.contains(label) ? label : '';
  }

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      id: json['id'] as String,
      kind: json['kind'] as String,
      category: json['category'] as String,
      level: json['level'] as String,
      english: json['english'] as String,
      chinese: json['chinese'] as String,
      note: json['note'] as String,
      example: json['example'] as String,
      exampleChinese: json['exampleChinese'] as String,
    );
  }
}

const categories = <String, String>{
  'all': '全部',
  'travel': '旅遊',
  'daily': '生活',
  'fitness': '健身',
  'work': '工作',
};

String categoryName(String category) => categories[category] ?? category;
