/// A group of words built from the same root: affixes (care → careful,
/// careless), compounds (fly → butterfly) and phrasal verbs (look after).
class WordFamily {
  const WordFamily({
    required this.id,
    required this.root,
    required this.meaning,
    required this.tip,
    required this.members,
  });

  final String id;
  final String root;
  final String meaning;
  final String tip;
  final List<FamilyMember> members;

  /// Every spelling in the family, root included, lower-cased.
  Iterable<String> get allWords =>
      [root, ...members.map((m) => m.english)].map((w) => w.toLowerCase());

  factory WordFamily.fromJson(Map<String, dynamic> json) => WordFamily(
        id: json['id'] as String,
        root: json['root'] as String,
        meaning: json['meaning'] as String,
        tip: json['tip'] as String? ?? '',
        members: (json['members'] as List<dynamic>)
            .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class FamilyMember {
  const FamilyMember({
    required this.english,
    required this.chinese,
    required this.hint,
  });

  final String english;
  final String chinese;

  /// How this word is formed, e.g. "-less 沒有" or "片語".
  final String hint;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        english: json['english'] as String,
        chinese: json['chinese'] as String,
        hint: json['hint'] as String? ?? '',
      );
}

/// Maps every word (root or member) to the families that contain it.
Map<String, List<WordFamily>> indexFamilies(List<WordFamily> families) {
  final index = <String, List<WordFamily>>{};
  for (final family in families) {
    for (final word in family.allWords.toSet()) {
      index.putIfAbsent(word, () => []).add(family);
    }
  }
  return index;
}
