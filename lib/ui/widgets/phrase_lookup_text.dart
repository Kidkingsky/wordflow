import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../logic/phrase_word_lookup.dart';
import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../theme/wordflow_design.dart';

/// Tappable English words that still wrap as natural continuous sentence text.
/// No remote translation service, account, or extra iOS entitlement is needed.
class PhraseLookupText extends StatefulWidget {
  const PhraseLookupText({
    required this.text,
    required this.controller,
    required this.style,
    this.contextPhrase,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.onOpenWord,
    super.key,
  });

  final String text;
  final AppController controller;
  final TextStyle style;
  final LearningItem? contextPhrase;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final ValueChanged<LearningItem>? onOpenWord;

  @override
  State<PhraseLookupText> createState() => _PhraseLookupTextState();
}

class _PhraseLookupTextState extends State<PhraseLookupText> {
  late List<RegExpMatch> _matches;
  late List<TapGestureRecognizer> _recognizers;

  @override
  void initState() {
    super.initState();
    _installRecognizers();
  }

  void _installRecognizers() {
    _matches = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?(?:-[A-Za-z]+)*")
        .allMatches(widget.text)
        .toList();
    _recognizers = [
      for (final match in _matches)
        TapGestureRecognizer()
          ..onTap = () => _showWord(
              widget.text.substring(match.start, match.end)),
    ];
  }

  @override
  void didUpdateWidget(covariant PhraseLookupText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _installRecognizers();
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Future<void> _speak(String english) async {
    try {
      await widget.controller.speak(english);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前無法播放發音，請檢查裝置語音設定。')),
      );
    }
  }

  void _showWord(String word) {
    if (!mounted) return;
    final definition = lookupPhraseWord(word, widget.controller.items);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: WordFlowDesign.paper,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(definition.catalogItem == null
                  ? '詞句單字解釋' : 'WordFlow 單字庫',
                style: WordFlowDesign.label),
              const SizedBox(height: 13),
              Text(definition.english,
                style: WordFlowDesign.english(size: 38)),
              const SizedBox(height: 8),
              if (definition.partOfSpeech.isNotEmpty)
                Text(definition.partOfSpeech,
                  style: const TextStyle(
                    color: WordFlowDesign.plum,
                    fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(definition.isKnown
                  ? definition.chinese
                  : '此單字目前尚未收錄中文解釋，可先聽發音。',
                style: const TextStyle(
                  color: WordFlowDesign.ink,
                  fontSize: 19, fontWeight: FontWeight.w600, height: 1.45)),
              if (widget.contextPhrase != null) ...[
                const SizedBox(height: 20),
                const Divider(color: WordFlowDesign.rule),
                const SizedBox(height: 17),
                const Text('放回原句理解', style: WordFlowDesign.label),
                const SizedBox(height: 9),
                Text(widget.contextPhrase!.english,
                  style: WordFlowDesign.english(size: 21)),
                const SizedBox(height: 7),
                Text(widget.contextPhrase!.chinese,
                  style: WordFlowDesign.body),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _speak(definition.english),
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('播放這個單字的發音'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              ),
              if (definition.catalogItem != null &&
                  widget.onOpenWord != null) ...[
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: () {
                    final item = definition.catalogItem!;
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) widget.onOpenWord?.call(item);
                    });
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('查看完整單字卡'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                ),
              ],
              if (definition.fromPhraseGlossary) ...[
                const SizedBox(height: 12),
                const Text('此為詞句常用詞的離線提示，實際意思仍要搭配整句理解。',
                  style: WordFlowDesign.label),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var i = 0; i < _matches.length; i++) {
      final match = _matches[i];
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: widget.text.substring(match.start, match.end),
        recognizer: _recognizers[i],
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: widget.style.color?.withValues(alpha: 0.48)
              ?? WordFlowDesign.plum,
          decorationThickness: 1,
        ),
      ));
      cursor = match.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
