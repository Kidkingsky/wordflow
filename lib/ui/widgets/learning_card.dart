import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
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
          const SizedBox(height: 6),
          Text(item.exampleChinese, style: TextStyle(color: subtle, fontSize: 13, height: 1.45)),
          if (showReviewActions) ...[
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

  void _mark(BuildContext context, {required bool remembered}) {
    controller.review(item, remembered: remembered);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(remembered ? '答對了！已安排下一次複習。' : '已加入今日待複習清單。'),
        duration: const Duration(seconds: 2),
      ),
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
    await controller.speech.speak(text, rate: controller.speechRate);
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
