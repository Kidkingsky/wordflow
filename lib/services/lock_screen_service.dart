import 'package:flutter/services.dart';

import 'app_controller.dart';

/// Starts a user-requested, time-limited Live Activity. Not a permanent widget.
class WordFlowLockScreenService {
  static const MethodChannel _channel =
      MethodChannel('com.kidkingsky.wordflow/lockscreen');

  static Future<void> start(AppController controller) async {
    final choices = controller.lessonWords;
    if (choices.length < 4) {
      throw StateError('這一課沒有足夠的單字，請先選擇課程。');
    }
    final words = List.generate(4, (index) {
      final item = choices[index];
      return <String, String>{
        'english': item.english,
        'chinese': item.chinese,
        'partOfSpeech': item.partOfSpeech,
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
