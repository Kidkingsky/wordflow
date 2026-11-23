import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../theme/wordflow_design.dart';
import '../widgets/learning_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, this.onOpenTab, super.key});
  final AppController controller;
  final ValueChanged<int>? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final word = controller.todayWord(today);
    final phrase = controller.todayPhrase(today);
    final todayCount = controller.studiedToday;
    final dueCount = controller.dueItems.length;
    final progress = (todayCount / 5).clamp(0.0, 1.0).toDouble();
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
        Text('今天，學一個好用的英文。', style: WordFlowDesign.title(size: 25)),
        const SizedBox(height: 8),
        const Text('用一個單字，累積每天都用得上的英文。',
          style: WordFlowDesign.body),
        const SizedBox(height: 20),
        _DailyWordCard(item: word, controller: controller),
        const SizedBox(height: 27),
        WordFlowSectionTitle(
          text: '今日練習',
          trailing: Text('$todayCount / 5', style: const TextStyle(
              color: WordFlowDesign.plum, fontSize: 16,
              fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress,
            backgroundColor: WordFlowDesign.rule,
            valueColor: const AlwaysStoppedAnimation(WordFlowDesign.plum),
          ),
        ),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: Text(todayCount >= 5 ? '今天的學習目標已完成。'
              : '再學 ${(5 - todayCount).clamp(0, 5)} 個，完成今日目標。',
              style: WordFlowDesign.label)),
          TextButton(
            onPressed: onOpenTab == null ? null
                : () => onOpenTab!(dueCount > 0 ? 2 : 1),
            child: Text(dueCount > 0 ? '去複習 $dueCount 張 ↗' : '去探索 ↗'),
          ),
        ]),
        const SizedBox(height: 18),
        const WordFlowSectionTitle(text: '選擇學習主題'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final option in categories.entries)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.value),
                  selected: controller.category == option.key,
                  onSelected: (_) => controller.changeCategory(option.key),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 27),
        const WordFlowSectionTitle(text: '今日實用詞句'),
        const SizedBox(height: 12),
        if (phrase == null)
          const Text('這個程度或主題目前沒有實用詞句。',
              style: WordFlowDesign.body)
        else
          Material(
            color: WordFlowDesign.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: WordFlowDesign.rule)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showLearningDetails(context, phrase, controller),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phrase.english,
                        style: WordFlowDesign.english(size: 23)),
                      const SizedBox(height: 9),
                      Text(phrase.chinese, style: WordFlowDesign.body),
                    ],
                  )),
                  const SizedBox(width: 9),
                  const Icon(Icons.north_east,
                    size: 20, color: WordFlowDesign.plum),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 25),
        const Text('收藏與複習紀錄儲存在這支 iPhone，離線也能學習。',
            style: WordFlowDesign.label),
      ],
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
            const Text('每日單字', style: TextStyle(
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
