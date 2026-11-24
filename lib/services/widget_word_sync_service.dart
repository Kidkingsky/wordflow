import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/learning_item.dart';
import 'app_controller.dart';

/// SideStore/App Groups experiment. Existing learning records are untouched.
class WidgetWordSyncState {
  const WidgetWordSyncState({
    required this.available,
    required this.revision,
    this.wordId,
    this.reason,
    this.groupId,
  });

  final bool available;
  final int revision;
  final String? wordId;
  final String? reason;

  /// The App Group ID the host app actually opened (SideStore may rewrite it).
  final String? groupId;

  factory WidgetWordSyncState.fromMap(Map<dynamic, dynamic>? map) {
    final data = map ?? const <dynamic, dynamic>{};
    return WidgetWordSyncState(
      available: data['available'] == true,
      revision: (data['revision'] as num?)?.toInt() ?? 0,
      wordId: data['wordId'] as String?,
      reason: data['reason'] as String?,
      groupId: data['groupId'] as String?,
    );
  }
}

class WidgetWordSyncService {
  static const _channel =
      MethodChannel('com.kidkingsky.wordflow/widgetsync');

  static Future<WidgetWordSyncState> status() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const WidgetWordSyncState(
        available: false,
        revision: 0,
        reason: '此項測試僅支援 iPhone。',
      );
    }
    return WidgetWordSyncState.fromMap(
        await _channel.invokeMapMethod<dynamic, dynamic>('status'));
  }

  static Future<WidgetWordSyncState> nextWord(
      AppController controller) async {
    final current = await status();
    if (!current.available) return current;

    final choices = controller.items.where((item) =>
        item.isWord &&
        item.level == controller.level &&
        (controller.category == 'all' ||
            item.category == controller.category)).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (choices.isEmpty) {
      throw StateError('這個程度與主題目前沒有可選單字。');
    }

    var index = choices.indexWhere((item) => item.id == current.wordId);
    if (index == -1) {
      final daily = controller.todayWord(DateTime.now());
      index = choices.indexWhere((item) => item.id == daily?.id);
    }
    final next = choices[(index + 1) % choices.length];
    return WidgetWordSyncState.fromMap(
        await _channel.invokeMapMethod<dynamic, dynamic>(
            'setWord', <String, String>{'wordId': next.id}));
  }

  static Future<WidgetWordSyncState> showDailyWord() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return status();
    return WidgetWordSyncState.fromMap(
        await _channel.invokeMapMethod<dynamic, dynamic>('clear'));
  }

  static LearningItem? selectedItem(
      AppController controller, WidgetWordSyncState? state) {
    if (state?.wordId == null) return null;
    for (final item in controller.items) {
      if (item.id == state!.wordId && item.isWord) return item;
    }
    return null;
  }
}
