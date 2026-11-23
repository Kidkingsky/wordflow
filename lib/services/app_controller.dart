import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/learning_logic.dart';
import '../models/learning_item.dart';
import '../models/review_record.dart';
import '../models/word_family.dart';
import 'speech_service.dart';

class AppController extends ChangeNotifier {
  AppController._(this.items, this._preferences, List<WordFamily> families)
      : _familyIndex = indexFamilies(families);

  static const _storageKey = 'wordflow_local_data_v1';

  final List<LearningItem> items;
  final SharedPreferencesAsync _preferences;
  final SpeechService speech = SpeechService();
  final Map<String, List<WordFamily>> _familyIndex;

  final Map<String, ReviewRecord> _records = {};
  final Set<String> _favorites = {};
  String category = 'all';
  String level = 'A2';
  /// 0.0–1.0 where 0.5 is natural speed on every platform; SpeechService
  /// converts it to the platform's own scale.
  double speechRate = 0.5;

  /// Voice chosen in settings (`name`), or null to pick the best one
  /// automatically.
  String? voiceName;

  static Future<AppController> initialize() async {
    final raw = await rootBundle.loadString('assets/content/content.json');
    final data = jsonDecode(raw) as List<dynamic>;
    final items = data
        .map((value) => LearningItem.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
    final familyRaw =
        await rootBundle.loadString('assets/content/word_families.json');
    final families = (jsonDecode(familyRaw) as List<dynamic>)
        .map((value) => WordFamily.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
    final controller =
        AppController._(items, SharedPreferencesAsync(), families);
    await controller._load();
    return controller;
  }

  Future<void> _load() async {
    try {
      final raw = await _preferences.getString(_storageKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      category = categories.containsKey(data['category'])
          ? data['category'] as String
          : 'all';
      level = data['level'] == 'B1' ? 'B1' : 'A2';
      speechRate = ((data['speechRate'] as num?)?.toDouble() ?? 0.5)
          .clamp(0.3, 0.7)
          .toDouble();
      voiceName = data['voiceName'] as String?;
      _favorites.addAll((data['favorites'] as List<dynamic>? ?? []).cast<String>());
      final saved = data['records'] as Map<String, dynamic>? ?? {};
      for (final entry in saved.entries) {
        _records[entry.key] =
            ReviewRecord.fromJson(entry.value as Map<String, dynamic>);
      }
    } catch (error) {
      // Invalid local storage should not make the app unusable.
      debugPrint('Could not read local learning history: $error');
    }
  }

  Future<void> _save() async {
    final data = {
      'category': category,
      'level': level,
      'speechRate': speechRate,
      'voiceName': voiceName,
      'favorites': _favorites.toList()..sort(),
      'records': _records.map((key, value) => MapEntry(key, value.toJson())),
    };
    try {
      await _preferences.setString(_storageKey, jsonEncode(data));
    } catch (error) {
      debugPrint('Could not save learning history: $error');
    }
  }

  void changeCategory(String value) {
    if (!categories.containsKey(value)) return;
    category = value;
    notifyListeners();
    _save();
  }

  void changeLevel(String value) {
    if (value != 'A2' && value != 'B1') return;
    level = value;
    notifyListeners();
    _save();
  }

  void changeSpeechRate(double value) {
    speechRate = value;
    notifyListeners();
    _save();
  }

  void changeVoice(String? name) {
    voiceName = name;
    notifyListeners();
    _save();
  }

  Future<void> speak(String text) =>
      speech.speak(text, rate: speechRate, voiceName: voiceName);

  /// Word families (affixes, compounds, phrasal verbs) containing [item].
  List<WordFamily> familiesFor(LearningItem item) =>
      item.isWord ? _familyIndex[item.english.toLowerCase()] ?? const [] : const [];

  bool isFavorite(LearningItem item) => _favorites.contains(item.id);

  void toggleFavorite(LearningItem item) {
    if (!_favorites.add(item.id)) _favorites.remove(item.id);
    notifyListeners();
    _save();
  }

  ReviewRecord record(LearningItem item) =>
      _records[item.id] ?? ReviewRecord.empty;

  /// True when the item was already answered "remembered" today and is not
  /// due again, so another "remembered" tap would not count.
  bool rememberedToday(LearningItem item) =>
      !record(item).canCountRemembered(DateTime.now());

  /// Returns false when the answer was ignored (repeat "remembered" today).
  bool review(LearningItem item, {required bool remembered}) {
    final now = DateTime.now();
    final current = record(item);
    if (remembered && !current.canCountRemembered(now)) return false;
    _records[item.id] = current.review(now: now, remembered: remembered);
    notifyListeners();
    _save();
    return true;
  }

  LearningItem? todayWord(DateTime today) => dailyPick(
        items,
        today: today,
        kind: 'word',
        category: category,
        level: level,
      );

  LearningItem? todayPhrase(DateTime today) => dailyPick(
        items,
        today: today,
        kind: 'phrase',
        category: category,
        level: level,
      );

  List<LearningItem> get dueItems {
    final now = DateTime.now();
    return items.where((item) => _records[item.id]?.isDue(now) ?? false).toList()
      ..sort((a, b) => record(a).nextDueDay.compareTo(record(b).nextDueDay));
  }

  int get studiedToday => _records.values
      .where((record) => record.lastReviewedDay == dayKey(DateTime.now()))
      .length;
  int get masteredCount => _records.values.where((record) => record.mastered).length;
  int get startedCount => _records.length;
  int get favoritesCount => _favorites.length;

  List<LearningItem> get favoriteItems =>
      items.where((item) => _favorites.contains(item.id)).toList();
}
