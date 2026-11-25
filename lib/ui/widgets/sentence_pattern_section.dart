import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../models/sentence_pattern.dart';
import '../../services/app_controller.dart';
import '../theme/wordflow_design.dart';
import 'phrase_lookup_text.dart';

/// Learn an expression, inspect the structure, then actively recall the same
/// pattern in a relevant situation. No network or AI grading is required.
class SentencePatternSection extends StatelessWidget {
  const SentencePatternSection({
    required this.phrase,
    required this.pattern,
    required this.controller,
    required this.onSpeak,
    required this.onOpenWord,
    super.key,
  });

  final LearningItem phrase;
  final SentencePattern pattern;
  final AppController controller;
  final ValueChanged<String> onSpeak;
  final ValueChanged<LearningItem> onOpenWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: WordFlowDesign.panel(color: WordFlowDesign.paper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('從這句學單字', style: WordFlowDesign.label),
          const SizedBox(height: 8),
          for (final word in pattern.focus)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(word.english, style: WordFlowDesign.english(size: 19)),
                        const SizedBox(height: 3),
                        Text(word.chinese, style: WordFlowDesign.body),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '朗讀 ${word.english}',
                  onPressed: () => onSpeak(word.english),
                  icon: const Icon(Icons.volume_up_outlined, size: 20),
                ),
              ],
            ),
          const Divider(color: WordFlowDesign.rule),
          const SizedBox(height: 6),
          const Text('句型結構 · 可以替換的部分', style: WordFlowDesign.label),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: WordFlowDesign.panel(color: WordFlowDesign.plumWash),
            child: Text(pattern.formula, style: const TextStyle(
              color: WordFlowDesign.plum, fontWeight: FontWeight.w700,
              fontSize: 16, height: 1.45)),
          ),
          const SizedBox(height: 10),
          Text('何時使用：${pattern.usage}', style: WordFlowDesign.body),
          const SizedBox(height: 6),
          Text('用法提醒：${pattern.tip}', style: WordFlowDesign.body),
          const SizedBox(height: 16),
          const Text('把句型用到你的生活', style: WordFlowDesign.label),
          const SizedBox(height: 5),
          const Text('先看中文，試著自己說一句英文，再展開參考答案。展開後可點字查義、聽發音。',
              style: WordFlowDesign.body),
          const SizedBox(height: 8),
          for (final example in pattern.examples)
            _PracticeExample(
              key: ValueKey('${phrase.id}/${example.category}'),
              phrase: phrase,
              example: example,
              controller: controller,
              onSpeak: onSpeak,
              onOpenWord: onOpenWord,
            ),
          const SizedBox(height: 8),
          const Text('試著把其中一個人、物品或動作換成你今天真的會用到的內容。',
              style: WordFlowDesign.label),
        ],
      ),
    );
  }
}

class _PracticeExample extends StatelessWidget {
  const _PracticeExample({
    required this.phrase,
    required this.example,
    required this.controller,
    required this.onSpeak,
    required this.onOpenWord,
    super.key,
  });

  final LearningItem phrase;
  final SentenceExample example;
  final AppController controller;
  final ValueChanged<String> onSpeak;
  final ValueChanged<LearningItem> onOpenWord;

  @override
  Widget build(BuildContext context) {
    final contextSentence = LearningItem(
      id: '${phrase.id}/${example.category}',
      kind: 'phrase',
      level: phrase.level,
      category: example.category,
      english: example.english,
      chinese: example.chinese,
      note: '', example: '', exampleChinese: '',
    );
    return ExpansionTile(
      key: PageStorageKey('${phrase.id}/practice/${example.category}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text('${categoryName(example.category)} · 試著說英文',
          style: WordFlowDesign.label),
      subtitle: Text(example.chinese, style: WordFlowDesign.body),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: PhraseLookupText(
              text: example.english,
              controller: controller,
              contextPhrase: contextSentence,
              onOpenWord: onOpenWord,
              style: WordFlowDesign.english(size: 20),
            )),
            IconButton(
              tooltip: '朗讀參考答案',
              onPressed: () => onSpeak(example.english),
              icon: const Icon(Icons.volume_up_outlined),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('參考說法之一；可以換成自己的自然表達。', style: WordFlowDesign.label),
        ),
      ],
    );
  }
}
