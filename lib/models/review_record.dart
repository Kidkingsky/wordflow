class ReviewRecord {
  const ReviewRecord({
    required this.successStreak,
    required this.reviewCount,
    required this.lastReviewedDay,
    required this.nextDueDay,
  });

  final int successStreak;
  final int reviewCount;
  final String lastReviewedDay;
  final String nextDueDay;

  bool get mastered => successStreak >= 3;

  bool isDue(DateTime now) => nextDueDay.compareTo(dayKey(now)) <= 0;

  ReviewRecord review({required DateTime now, required bool remembered}) {
    final nextStreak = remembered ? successStreak + 1 : 0;
    const days = [1, 3, 7, 14, 30, 60];
    final step = nextStreak > days.length ? days.length - 1 : nextStreak - 1;
    final interval = remembered ? days[step] : 0;
    return ReviewRecord(
      successStreak: nextStreak,
      reviewCount: reviewCount + 1,
      lastReviewedDay: dayKey(now),
      nextDueDay: dayKey(DateTime(now.year, now.month, now.day + interval)),
    );
  }

  Map<String, dynamic> toJson() => {
        'successStreak': successStreak,
        'reviewCount': reviewCount,
        'lastReviewedDay': lastReviewedDay,
        'nextDueDay': nextDueDay,
      };

  factory ReviewRecord.fromJson(Map<String, dynamic> json) {
    return ReviewRecord(
      successStreak: (json['successStreak'] as num?)?.toInt() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      lastReviewedDay: json['lastReviewedDay'] as String? ?? '',
      nextDueDay: json['nextDueDay'] as String? ?? '',
    );
  }

  static const empty = ReviewRecord(
    successStreak: 0,
    reviewCount: 0,
    lastReviewedDay: '',
    nextDueDay: '',
  );
}

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
