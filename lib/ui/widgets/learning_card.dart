import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../models/word_family.dart';
import '../../services/app_controller.dart';

class LearningCard extends StatelessWidget {
  const LearningCard({
    required this.item,
    required this.controller,
    this.isHighlighted = false,
    this.showReviewActions = true,
    super.key,
  });

  final LearningItem item;
  final AppController controller;
  final bool isHighlighted;
  final bool showReviewActions;

  @override
  Widget build(BuildContext context) {
    final dark = isHighlighted;
    final foreground = dark ? Colors.white : const Color(0xFF152839);
    final subtle = dark ? const Color(0xFFB3CBD0) : const Color(0xFF6E7E8A);
    final panel = dark ? const Color(0xFF172F42) : Colors.white;
    final divider = dark ? const Color(0xFF355064) : const Color(0xFFEAF0F2);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(26),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x080A283F),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoBadge(
                text: item.level,
                background: dark ? const Color(0xFF2B5061) : const Color(0xFFE1F3F0),
                foreground: dark ? const Color(0xFFD2F9ED) : const Color(0xFF137B7C),
              ),
              const SizedBox(width: 7),
              _InfoBadge(
                text: categoryName(item.category),
                background: dark ? const Color(0xFF2B5061) : const Color(0xFFEFF2F4),
                foreground: dark ? const Color(0xFFD2F9ED) : const Color(0xFF516370),
              ),
              if (item.partOfSpeech.isNotEmpty) ...[
                const SizedBox(width: 7),
                _InfoBadge(
                  text: item.partOfSpeech,
                  background: dark ? const Color(0xFF3C5276) : const Color(0xFFECE4F8),
                  foreground: dark ? Colors.white : const Color(0xFF684C9F),
                ),
              ],
              const Spacer(),
              IconButton(
                tooltip: controller.isFavorite(item) ? '取消收藏' : '加入收藏',
                onPressed: () => controller.toggleFavorite(item),
                icon: Icon(
                  controller.isFavorite(item)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: dark ? const Color(0xFFB9F3E7) : const Color(0xFF147F83),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            item.english,
            style: TextStyle(
              fontSize: item.isWord ? 33 : 26,
              fontWeight: FontWeight.w800,
              height: 1.16,
              letterSpacing: -0.5,
              color: foreground,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.chinese,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '朗讀英文',
                onPressed: () => speakEnglish(context, controller, item.english),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.note, style: TextStyle(color: subtle, height: 1.5, fontSize: 13)),
          if (item.example.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: divider),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  item.isWord ? 'EXAMPLE' : 'IN CONTEXT',
                  style: TextStyle(
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                    color: subtle,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => speakEnglish(context, controller, item.example),
                  child: Icon(Icons.play_circle_outline, color: subtle, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.example,
              style: TextStyle(color: foreground, fontSize: 15, height: 1.5),
            ),
            if (item.exampleChinese.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.exampleChinese,
                  style: TextStyle(color: subtle, fontSize: 13, height: 1.45)),
            ],
          ],
          for (final family in controller.familiesFor(item)) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: divider),
            const SizedBox(height: 16),
            _FamilySection(
              family: family,
              current: item.english,
              dark: dark,
              onSpeak: (text) => speakEnglish(context, controller, text),
            ),
          ],
          if (showReviewActions && controller.rememberedToday(item)) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF214257) : const Color(0xFFE6F4F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 20,
                      color: dark ? const Color(0xFF8EE2D3) : const Color(0xFF167F83)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '今天已記住，${_nextReviewLabel()}再複習',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _mark(context, remembered: false),
                    style: TextButton.styleFrom(
                      foregroundColor: dark ? const Color(0xFFB9F3E7) : const Color(0xFF245064),
                    ),
                    child: const Text('其實還不熟'),
                  ),
                ],
              ),
            ),
          ] else if (showReviewActions) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _mark(context, remembered: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dark ? Colors.white : const Color(0xFF245064),
                      side: BorderSide(color: divider),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('再練習'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _mark(context, remembered: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: dark ? const Color(0xFF8EE2D3) : const Color(0xFF167F83),
                      foregroundColor: dark ? const Color(0xFF132A38) : Colors.white,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('我記住了'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _nextReviewLabel() {
    final due = DateTime.tryParse(controller.record(item).nextDueDay);
    if (due == null) return '之後';
    final now = DateTime.now();
    final days = due.difference(DateTime(now.year, now.month, now.day)).inDays;
    return days <= 1 ? '明天' : '$days 天後';
  }

  void _mark(BuildContext context, {required bool remembered}) {
    if (!controller.review(item, remembered: remembered)) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(remembered ? '答對了！已安排下一次複習。' : '已加入今日待複習清單。'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// "同家族單字": the root plus affix / compound / phrasal-verb relatives.
class _FamilySection extends StatelessWidget {
  const _FamilySection({
    required this.family,
    required this.current,
    required this.dark,
    required this.onSpeak,
  });

  final WordFamily family;
  final String current;
  final bool dark;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    final subtle = dark ? const Color(0xFFB3CBD0) : const Color(0xFF6E7E8A);
    final foreground = dark ? Colors.white : const Color(0xFF152839);
    final chipBg = dark ? const Color(0xFF214257) : const Color(0xFFF1F5F7);
    final accent = dark ? const Color(0xFF8EE2D3) : const Color(0xFF684C9F);
    final entries = [
      FamilyMember(english: family.root, chinese: family.meaning, hint: '字根'),
      ...family.members,
    ].where((m) => m.english.toLowerCase() != current.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 16, color: subtle),
            const SizedBox(width: 6),
            Text(
              '同家族單字 · ${family.root}',
              style: TextStyle(
                letterSpacing: 0.4,
                fontWeight: FontWeight.w800,
                color: subtle,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (family.tip.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(family.tip,
              style: TextStyle(color: subtle, fontSize: 12, height: 1.45)),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in entries)
              Material(
                color: chipBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSpeak(member.english),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(member.english,
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 2),
                        Text(member.chinese,
                            style: TextStyle(color: subtle, fontSize: 11)),
                        if (member.hint.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(member.hint,
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9)),
      child: Text(
        text,
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

Future<void> speakEnglish(
  BuildContext context,
  AppController controller,
  String text,
) async {
  try {
    await controller.speak(text);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('目前無法播放語音，請檢查裝置的語音功能。')),
    );
  }
}

void showLearningDetails(
  BuildContext context,
  LearningItem item,
  AppController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F9FA),
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => LearningCard(item: item, controller: controller),
        ),
      ),
    ),
  );
}
