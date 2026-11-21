import '../models/learning_item.dart';

/// Deterministic daily rotation. The same day, filter and device produce the
/// same recommendation. Future: replace with server or on-device personalization.
LearningItem? dailyPick(
  List<LearningItem> items, {
  required DateTime today,
  required String kind,
  required String category,
  required String level,
}) {
  final eligible = items.where((item) {
    return item.kind == kind &&
        (category == 'all' || item.category == category) &&
        item.level == level;
  }).toList();

  if (eligible.isEmpty) return null;
  eligible.sort((a, b) => a.id.compareTo(b.id));
  final epoch = DateTime.utc(2025, 1, 1);
  final utcDay = DateTime.utc(today.year, today.month, today.day);
  final dayNumber = utcDay.difference(epoch).inDays;
  // Offset words and phrases differently to prevent two cards from cycling
  // through their lists at the same phase.
  final offset = kind == 'phrase' ? 7 : 0;
  return eligible[(dayNumber + offset) % eligible.length];
}
