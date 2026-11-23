import 'package:flutter/services.dart';

import 'app_controller.dart';

/// Starts a user-requested, time-limited Live Activity. Not a permanent widget.
class WordFlowLockScreenService {
  static const MethodChannel _channel =
      MethodChannel('com.kidkingsky.wordflow/lockscreen');

  static Future<void> start(AppController controller) async {
    final choices = controller.items
        .where((item) =>
            item.isWord &&
            item.level == controller.level &&
            (controller.category == 'all' ||
                item.category == controller.category))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (choices.length < 4) {
      throw StateError('這個主題沒有足夠的單字，請改選其他主題。');
    }

    final now = DateTime.now();
    final date = DateTime.utc(now.year, now.month, now.day);
    final day = date.difference(DateTime.utc(2025, 1, 1)).inDays;
    final words = List.generate(4, (index) {
      final item = choices[((day * 4 + index) % choices.length +
              choices.length) %
          choices.length];
      return <String, String>{
        'english': item.english,
        'chinese': item.chinese,
      };
    });

    await _channel.invokeMethod<String>('start', <String, Object>{
      'words': words,
      'level': controller.level,
      'category': controller.category,
    });
  }

  static Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }
}
