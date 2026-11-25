/// Reusable sentence structures tied to existing phrase IDs. A pattern
/// complements the phrase rather than creating a duplicate review card.
class SentenceFocus {
  const SentenceFocus({required this.english, required this.chinese});
  final String english, chinese;
  factory SentenceFocus.fromJson(Map<String, dynamic> json) => SentenceFocus(
        english: json['english'] as String,
        chinese: json['chinese'] as String,
      );
}

class SentenceExample {
  const SentenceExample({
    required this.category,
    required this.english,
    required this.chinese,
  });
  final String category, english, chinese;
  factory SentenceExample.fromJson(Map<String, dynamic> json) =>
      SentenceExample(
        category: json['category'] as String,
        english: json['english'] as String,
        chinese: json['chinese'] as String,
      );
}

class SentencePattern {
  const SentencePattern({
    required this.formula,
    required this.usage,
    required this.tip,
    required this.focus,
    required this.examples,
  });
  final String formula, usage, tip;
  final List<SentenceFocus> focus;
  final List<SentenceExample> examples;

  factory SentencePattern.fromJson(Map<String, dynamic> json) => SentencePattern(
        formula: json['formula'] as String,
        usage: json['usage'] as String,
        tip: json['tip'] as String,
        focus: (json['focus'] as List<dynamic>)
            .map((value) => SentenceFocus.fromJson(value as Map<String, dynamic>))
            .toList(growable: false),
        examples: (json['examples'] as List<dynamic>)
            .map((value) => SentenceExample.fromJson(value as Map<String, dynamic>))
            .toList(growable: false),
      );
}
