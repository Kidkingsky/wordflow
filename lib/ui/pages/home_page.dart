import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../theme/wordflow_design.dart';
import '../widgets/learning_card.dart';
import '../widgets/phrase_lookup_text.dart';
import '../widgets/sentence_pattern_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, this.onOpenTab, super.key});
  final AppController controller;
  final ValueChanged<int>? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final word = controller.todayWord(today);
    final phrases = controller.lessonPhrases;
    final lesson = controller.currentLesson;
    final todayCount = controller.studiedToday;
    final dueCount = controller.dueItems.length;
    final progress = (todayCount / 6).clamp(0.0, 1.0).toDouble();
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 17, 22, 34),
      children: [
        Row(children: [
          const WordFlowWordmark(),
          const Spacer(),
          IconButton(
            onPressed: onOpenTab == null ? null : () => onOpenTab!(3),
            tooltip: '我的設定',
            icon: const Icon(Icons.person_outline),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor: WordFlowDesign.card,
              foregroundColor: WordFlowDesign.plum,
              side: const BorderSide(color: WordFlowDesign.rule),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        const SizedBox(height: 31),
        Text('${today.month}月${today.day}日 · 星期${weekdays[today.weekday - 1]}',
          style: WordFlowDesign.label),
        const SizedBox(height: 9),
        Text('今天，從一句英文開始。', style: WordFlowDesign.title(size: 25)),
        const SizedBox(height: 8),
        const Text('先理解句子，學會新單字，再換成生活、工作與健身情境。',
          style: WordFlowDesign.body),
        const SizedBox(height: 20),
        if (lesson != null) ...[
          _CoursePanel(controller: controller),
          const SizedBox(height: 20),
        ],
        const WordFlowSectionTitle(text: '今日句型 · 先聽，再試說'),
        const SizedBox(height: 12),
        if (phrases.isEmpty)
          const Text('這個程度或主題目前沒有實用詞句。',
              style: WordFlowDesign.body)
        else
          for (final entry in phrases.asMap().entries) ...[
            _SentenceStudyCard(
              key: ValueKey(entry.value.id),
              phrase: entry.value,
              number: entry.key + 1,
              controller: controller,
              expanded: entry.key == 0,
            ),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 10),
        const WordFlowSectionTitle(text: '情境延伸單字 · 同一課'),
        const SizedBox(height: 8),
        for (final item in controller.lessonWords)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.english, style: WordFlowDesign.english(size: 22)),
            subtitle: Text(item.chinese, style: WordFlowDesign.body),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLearningDetails(context, item, controller),
          ),
        const SizedBox(height: 14),
        _DailyWordCard(item: word, controller: controller),
        const SizedBox(height: 24),
        WordFlowSectionTitle(
          text: '今日練習',
          trailing: Text('$todayCount / 6', style: const TextStyle(
              color: WordFlowDesign.plum, fontSize: 16,
              fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            minHeight: 7, value: progress,
            backgroundColor: WordFlowDesign.rule,
            valueColor: const AlwaysStoppedAnimation(WordFlowDesign.plum),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(todayCount >= 6 ? '今天的學習目標已完成。'
              : '再練習 ${(6 - todayCount).clamp(0, 6)} 張卡片，完成今日目標。',
              style: WordFlowDesign.label)),
          TextButton(
            onPressed: onOpenTab == null ? null
                : () => onOpenTab!(dueCount > 0 ? 2 : 1),
            child: Text(dueCount > 0 ? '去複習 $dueCount 張 ↗' : '去探索 ↗'),
          ),
        ]),
        const SizedBox(height: 25),
        if (lesson != null)
          FilledButton.icon(
            onPressed: controller.finishLesson,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(controller.coursePath.last.id == lesson.id
                ? '完成本課' : '完成本課，前往下一課'),
          ),
        if (lesson != null && controller.completedLessonCount == controller.coursePath.length)
          Text(controller.level == 'A2'
              ? '此路線已完成！可在上方選擇 B1 進階課程或回頭複習。'
              : '此路線已完成！請回頭複習或探索其他主題。',
              style: WordFlowDesign.body),
        const SizedBox(height: 16),
        const Text('收藏與複習紀錄儲存在這支 iPhone，離線也能學習。',
            style: WordFlowDesign.label),
      ],
    );
  }
}

class _CoursePanel extends StatelessWidget {
  const _CoursePanel({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final lesson = controller.currentLesson!;
    final path = controller.coursePath;
    final number = path.indexWhere((item) => item.id == lesson.id) + 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WordFlowDesign.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${lesson.level} · ${categoryName(lesson.category)} · 第 $number / ${path.length} 課',
              style: WordFlowDesign.label),
          const SizedBox(height: 6),
          Text(lesson.title, style: WordFlowDesign.title(size: 23)),
          const SizedBox(height: 6),
          Text(lesson.objective, style: WordFlowDesign.body),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'A2', label: Text('A2 基礎')),
              ButtonSegment(value: 'B1', label: Text('B1 進階')),
            ],
            selected: {controller.level},
            onSelectionChanged: (value) => controller.changeLevel(value.first),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: controller.completedLessonCount / path.length),
          const SizedBox(height: 6),
          Text('已完成 ${controller.completedLessonCount} / ${path.length} 課（完成不等於已精熟）',
              style: WordFlowDesign.label),
          const SizedBox(height: 12),
          const Text('選擇學習主題', style: WordFlowDesign.label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final option in categories.entries)
                ChoiceChip(
                  label: Text(option.value),
                  selected: controller.category == option.key,
                  onSelected: (_) => controller.changeCategory(option.key),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => SafeArea(
                    child: ListView(
                      children: [
                        const ListTile(title: Text('選擇學習課程')),
                        for (final entry in path.asMap().entries)
                          ListTile(
                            leading: Icon(controller.lessonCompleted(entry.value)
                                ? Icons.check_circle_outline : Icons.menu_book_outlined),
                            selected: entry.value.id == lesson.id,
                            title: Text('${entry.key + 1}. ${entry.value.title}'),
                            subtitle: Text(categoryName(entry.value.category)),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              controller.openLesson(entry.value.id);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                child: const Text('所有課程'),
              ),
              if (Theme.of(context).platform == TargetPlatform.iOS)
                OutlinedButton(
                  onPressed: () async {
                    final ok = await controller.syncCurrentLesson();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? '已送出本課單字與詞句，請確認 Widget 更新。'
                          : '無法使用 App Groups；Widget 仍可獨立學習。'),
                    ));
                  },
                  child: const Text('同步本課至 Widget'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentenceStudyCard extends StatelessWidget {
  const _SentenceStudyCard({
    required this.phrase,
    required this.number,
    required this.controller,
    required this.expanded,
    super.key,
  });
  final LearningItem phrase;
  final int number;
  final AppController controller;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final pattern = controller.patternFor(phrase);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WordFlowDesign.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('句型 $number · ${phrase.level}', style: WordFlowDesign.label),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: PhraseLookupText(
                text: phrase.english,
                controller: controller,
                contextPhrase: phrase,
                onOpenWord: (word) => showLearningDetails(context, word, controller),
                style: WordFlowDesign.english(size: 26),
              )),
              IconButton(
                tooltip: '朗讀完整句子',
                onPressed: () => speakEnglish(context, controller, phrase.english),
                icon: const Icon(Icons.volume_up_outlined, color: WordFlowDesign.plum),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(phrase.chinese, style: WordFlowDesign.body),
          const SizedBox(height: 6),
          const Text('點句中的單字查意思與發音', style: WordFlowDesign.label),
          if (pattern != null)
            ExpansionTile(
              key: PageStorageKey('pattern/${phrase.id}'),
              initiallyExpanded: expanded,
              tilePadding: EdgeInsets.zero,
              title: const Text('拆解句型與跨情境練習', style: WordFlowDesign.body),
              children: [
                SentencePatternSection(
                  phrase: phrase,
                  pattern: pattern,
                  controller: controller,
                  onSpeak: (text) => speakEnglish(context, controller, text),
                  onOpenWord: (word) => showLearningDetails(context, word, controller),
                ),
              ],
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showLearningDetails(context, phrase, controller),
              icon: const Icon(Icons.school_outlined),
              label: const Text('情境例句與複習'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyWordCard extends StatelessWidget {
  const _DailyWordCard({required this.item, required this.controller});
  final LearningItem? item;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: WordFlowDesign.panel(),
        child: const Text('目前沒有符合的單字，請試試其他主題。',
            style: WordFlowDesign.body),
      );
    }
    final word = item!;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 21, 22, 16),
      decoration: BoxDecoration(
        color: WordFlowDesign.plum,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('本課主單字', style: TextStyle(
              color: Color(0xFFF0E7F2),
              fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C688D),
                borderRadius: BorderRadius.circular(8)),
              child: Text(word.level, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 30),
          Text(word.english,
              style: WordFlowDesign.english(size: 42, color: Colors.white),
              maxLines: 2),
          const SizedBox(height: 12),
          if (word.partOfSpeech.isNotEmpty)
            Text(word.partOfSpeech,
              style: const TextStyle(color: Color(0xFFE8DFF0),
                fontSize: 13)),
          const SizedBox(height: 7),
          Text(word.chinese, style: const TextStyle(
            color: Colors.white, fontSize: 20,
            fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 25),
          const Divider(color: Color(0xFF897699), height: 1),
          const SizedBox(height: 17),
          Text(word.example.isNotEmpty
              ? word.example : '每天學一個，慢慢累積英文力。',
            style: const TextStyle(color: Colors.white,
              fontSize: 15, height: 1.5)),
          if (word.exampleChinese.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(word.exampleChinese, style: const TextStyle(
              color: Color(0xFFE8DFF0), fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            TextButton.icon(
              onPressed: () => showLearningDetails(context, word, controller),
              icon: const Icon(Icons.arrow_forward, size: 17),
              label: const Text('深入學習'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            const Spacer(),
            IconButton(
              tooltip: '朗讀英文',
              onPressed: () => speakEnglish(context, controller, word.english),
              icon: const Icon(Icons.volume_up_outlined),
              color: Colors.white,
            ),
            IconButton(
              tooltip: controller.isFavorite(word) ? '取消收藏' : '加入收藏',
              onPressed: () => controller.toggleFavorite(word),
              icon: Icon(controller.isFavorite(word)
                  ? Icons.bookmark : Icons.bookmark_border),
              color: Colors.white,
            ),
          ]),
          if (controller.rememberedToday(word))
            const Text('今天已記住', style: TextStyle(
              color: WordFlowDesign.sage, fontSize: 12)),
        ],
      ),
    );
  }
}
