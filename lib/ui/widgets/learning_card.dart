import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../models/word_family.dart';
import '../../services/app_controller.dart';
import '../theme/wordflow_design.dart';
import 'phrase_lookup_text.dart';
import 'sentence_pattern_section.dart';

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
    final pattern = controller.patternFor(item);
    final dark = isHighlighted;
    final foreground = dark ? Colors.white : WordFlowDesign.ink;
    final subtle = dark ? const Color(0xFFECE3F2) : WordFlowDesign.muted;
    final panel = dark ? WordFlowDesign.plumDeep : WordFlowDesign.card;
    final divider = dark ? const Color(0xFF83718F) : WordFlowDesign.rule;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? WordFlowDesign.plumDeep : WordFlowDesign.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoBadge(
                text: item.level,
                background: dark ? const Color(0xFF6D587F) : WordFlowDesign.plumWash,
                foreground: dark ? const Color(0xFFF2E9F8) : WordFlowDesign.plum,
              ),
              const SizedBox(width: 7),
              _InfoBadge(
                text: categoryName(item.category),
                background: dark ? const Color(0xFF6D587F) : WordFlowDesign.paper,
                foreground: dark ? const Color(0xFFF2E9F8) : WordFlowDesign.muted,
              ),
              if (item.partOfSpeech.isNotEmpty) ...[
                const SizedBox(width: 7),
                _InfoBadge(
                  text: item.partOfSpeech,
                  background: dark ? const Color(0xFF75618B) : WordFlowDesign.plumWash,
                  foreground: dark ? Colors.white : WordFlowDesign.plum,
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
                  color: dark ? const Color(0xFFE8DFF0) : WordFlowDesign.plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (item.isWord)
            Text(
              item.english,
              style: TextStyle(
                fontSize: 37,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
                height: 1.16,
                letterSpacing: -0.5,
                color: foreground,
              ),
            )
          else
            PhraseLookupText(
              text: item.english,
              controller: controller,
              contextPhrase: item,
              onOpenWord: (word) => showLearningDetails(
                context, word, controller),
              style: TextStyle(
                fontSize: 27,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
                height: 1.16,
                letterSpacing: -0.5,
                color: foreground,
              ),
            ),
          if (!item.isWord) ...[
            const SizedBox(height: 5),
            Text('點選英文單字，可查中文與聽發音。',
              style: TextStyle(color: subtle, fontSize: 12)),
          ],
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
            if (item.isWord)
              Text(item.example,
                style: TextStyle(color: foreground, fontSize: 15, height: 1.5))
            else
              PhraseLookupText(
                text: item.example,
                controller: controller,
                contextPhrase: item,
                onOpenWord: (word) => showLearningDetails(
                  context, word, controller),
                style: TextStyle(color: foreground, fontSize: 15, height: 1.5),
              ),
            if (item.exampleChinese.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.exampleChinese,
                  style: TextStyle(color: subtle, fontSize: 13, height: 1.45)),
            ],
          ],
          if (pattern != null) ...[
            const SizedBox(height: 18),
            SentencePatternSection(
              phrase: item,
              pattern: pattern,
              controller: controller,
              onSpeak: (text) => speakEnglish(context, controller, text),
              onOpenWord: (word) => showLearningDetails(context, word, controller),
            ),
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
                color: dark ? const Color(0xFF6B5680) : WordFlowDesign.sage,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 20,
                      color: dark ? WordFlowDesign.sage : WordFlowDesign.plum),
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
                      foregroundColor: dark ? const Color(0xFFE8DFF0) : WordFlowDesign.plum,
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
                      foregroundColor: dark ? Colors.white : WordFlowDesign.plum,
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
                      backgroundColor: dark ? WordFlowDesign.sage : WordFlowDesign.plum,
                      foregroundColor: dark ? WordFlowDesign.plumDeep : Colors.white,
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
    final subtle = dark ? const Color(0xFFECE3F2) : WordFlowDesign.muted;
    final foreground = dark ? Colors.white : WordFlowDesign.ink;
    final chipBg = dark ? const Color(0xFF6B5680) : WordFlowDesign.paper;
    final accent = dark ? WordFlowDesign.sage : WordFlowDesign.plum;
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
    backgroundColor: WordFlowDesign.paper,
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
