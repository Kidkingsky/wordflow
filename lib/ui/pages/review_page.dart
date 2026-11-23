import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../theme/wordflow_design.dart';
import '../widgets/learning_card.dart';
import '../widgets/phrase_lookup_text.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final Set<String> _completedInSession = {};
  // Cards answered "還不熟" this session, in order. They stay in the queue but
  // move to the back so the learner sees them again before the round ends.
  final List<String> _retryQueue = [];
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final pending = widget.controller.dueItems
        .where((item) => !_completedInSession.contains(item.id))
        .toList();
    final due = [
      ...pending.where((item) => !_retryQueue.contains(item.id)),
      for (final id in _retryQueue) ...pending.where((item) => item.id == id),
    ];
    final item = due.isNotEmpty ? due.first : null;
    final total = _completedInSession.length + due.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 36),
      children: [
        Text('間隔複習', style: WordFlowDesign.title(size: 29)),
        const SizedBox(height: 5),
        const Text('先想一下，再翻開答案。', style: WordFlowDesign.label),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: WordFlowDesign.sage,
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF167F83),
                child: Icon(Icons.auto_awesome),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('本次複習進度', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('不熟的題目會排到最後，這一輪再練一次。',
                        style: TextStyle(fontSize: 11, color: Color(0xFF467675))),
                  ],
                ),
              ),
              Text('${_completedInSession.length} / $total',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 26),
        if (item == null)
          _EmptyReview(
            completed: _completedInSession.isNotEmpty,
            onRestart: () => setState(() {
              _completedInSession.clear();
              _retryQueue.clear();
              _showAnswer = false;
            }),
          )
        else
          _ReviewFlashcard(
            item: item,
            isRetry: _retryQueue.contains(item.id),
            showAnswer: _showAnswer,
            controller: widget.controller,
            onFlip: () => setState(() => _showAnswer = true),
            onReview: (remembered) {
              widget.controller.review(item, remembered: remembered);
              setState(() {
                _retryQueue.remove(item.id);
                if (remembered) {
                  _completedInSession.add(item.id);
                } else {
                  _retryQueue.add(item.id);
                }
                _showAnswer = false;
              });
            },
          ),
      ],
    );
  }
}

class _ReviewFlashcard extends StatelessWidget {
  const _ReviewFlashcard({
    required this.item,
    required this.controller,
    required this.isRetry,
    required this.showAnswer,
    required this.onFlip,
    required this.onReview,
  });

  final LearningItem item;
  final AppController controller;
  final bool isRetry;
  final bool showAnswer;
  final VoidCallback onFlip;
  final ValueChanged<bool> onReview;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          color: WordFlowDesign.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: WordFlowDesign.rule),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${item.level}  ·  ${categoryName(item.category)}  ·  ${item.isWord ? '單字' : '詞句'}${isRetry ? '  ·  再試一次' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF167F83),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            if (item.isWord || !showAnswer)
              Text(
                item.english,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 37,
                  fontWeight: FontWeight.w500,
                  color: WordFlowDesign.ink,
                ),
              )
            else
              PhraseLookupText(
                text: item.english,
                controller: controller,
                contextPhrase: item,
                textAlign: TextAlign.center,
                onOpenWord: (word) => showLearningDetails(
                  context, word, controller),
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 37,
                  fontWeight: FontWeight.w500,
                  color: WordFlowDesign.ink,
                ),
              ),
            const SizedBox(height: 12),
            Center(
              child: IconButton.filledTonal(
                tooltip: '朗讀英文',
                onPressed: () => speakEnglish(context, controller, item.english),
                icon: const Icon(Icons.volume_up),
              ),
            ),
            const SizedBox(height: 24),
            if (!showAnswer)
              FilledButton.icon(
                onPressed: onFlip,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('翻開答案'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              )
            else ...[
              const Divider(),
              const SizedBox(height: 14),
              Text(item.chinese,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(item.note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6E7E8A))),
              if (item.example.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(item.example,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (item.exampleChinese.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.exampleChinese,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6E7E8A))),
                ],
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onReview(false),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('還不熟'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onReview(true),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('記住了'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.completed, required this.onRestart});
  final bool completed;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: WordFlowDesign.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: WordFlowDesign.rule),
        ),
        child: Column(
          children: [
            const Icon(Icons.task_alt_rounded, size: 64, color: Color(0xFF167F83)),
            const SizedBox(height: 17),
            Text(
              completed ? '這一輪完成了！' : '今天沒有待複習的項目',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            Text(
              completed ? '辛苦了，明天還有新的學習挑戰。' : '先到「今日」學幾個單字或句子吧。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6E7E8A)),
            ),
            if (completed) ...[
              const SizedBox(height: 18),
              TextButton(onPressed: onRestart, child: const Text('重新查看目前待複習項目')),
            ],
          ],
        ),
      );
}
