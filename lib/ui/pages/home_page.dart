import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../widgets/learning_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final word = controller.todayWord(today);
    final phrase = controller.todayPhrase(today);
    final todayCount = controller.studiedToday;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORDFLOW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Color(0xFF178082),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    '每天一點，英文更自然。',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF152839),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF2EC),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF167F83)),
            ),
          ],
        ),
        const SizedBox(height: 23),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: const Color(0xFFDCF1ED),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 21, color: Color(0xFF137D7D)),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text('今天的學習目標', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  Text('$todayCount / 5',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: (todayCount / 5).clamp(0, 1).toDouble(),
                  minHeight: 9,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF167F83)),
                ),
              ),
              const SizedBox(height: 9),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('學會 5 個內容，就完成每日小挑戰。',
                    style: TextStyle(fontSize: 12, color: Color(0xFF467675))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('選擇今天想學的主題',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.entries.map((entry) {
              final selected = controller.category == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) => controller.changeCategory(entry.key),
                  selectedColor: const Color(0xFFCEF0E8),
                  side: BorderSide.none,
                  backgroundColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 23),
        const _SectionHeading(title: '每日推薦單字', subtitle: 'WORD OF THE DAY'),
        const SizedBox(height: 12),
        if (word != null)
          LearningCard(item: word, controller: controller)
        else
          const _MissingItem(),
        const SizedBox(height: 27),
        const _SectionHeading(title: '每日實用詞句', subtitle: 'PHRASE OF THE DAY'),
        const SizedBox(height: 12),
        if (phrase != null)
          LearningCard(item: phrase, controller: controller, isHighlighted: true)
        else
          const _MissingItem(),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: const Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: Color(0xFF167F83)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '學完後到「複習」測試記憶；每天的推薦會依日期輪換，不需要網路。',
                  style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF536773)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: Color(0xFF91A0AA))),
        ],
      );
}

class _MissingItem extends StatelessWidget {
  const _MissingItem();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('目前沒有符合這個程度／主題的內容，請換個主題看看。'),
        ),
      );
}
