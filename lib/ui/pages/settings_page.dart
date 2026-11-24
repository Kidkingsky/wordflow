import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../../services/lock_screen_service.dart';
import '../../services/widget_word_sync_service.dart';
import '../theme/wordflow_design.dart';
import '../../services/speech_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 36),
      children: [
        Text('我的學習', style: WordFlowDesign.title(size: 29)),
        const SizedBox(height: 4),
        const Text('照自己的節奏，每天一點點。',
            style: TextStyle(fontSize: 13, color: Color(0xFF6E7E8A))),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _Metric(value: controller.startedCount, label: '開始學習')),
            const SizedBox(width: 10),
            Expanded(child: _Metric(value: controller.masteredCount, label: '已掌握')),
            const SizedBox(width: 10),
            Expanded(child: _Metric(value: controller.favoritesCount, label: '收藏內容')),
          ],
        ),
        const SizedBox(height: 19),
        _SettingsSection(
          title: '我的英文程度',
          subtitle: '每日推薦會根據這個程度挑選內容。',
          child: Wrap(
            spacing: 9,
            children: ['A2', 'B1'].map((value) {
              return ChoiceChip(
                label: Text('$value  ${value == 'A2' ? '基礎' : '進階'}'),
                selected: controller.level == value,
                onSelected: (_) => controller.changeLevel(value),
                selectedColor: WordFlowDesign.plumWash,
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 13),
        _SettingsSection(
          title: '推薦主題',
          subtitle: '可以在首頁直接切換。',
          child: Wrap(
            spacing: 7,
            runSpacing: 4,
            children: categories.entries.map((entry) {
              return FilterChip(
                label: Text(entry.value),
                selected: controller.category == entry.key,
                onSelected: (_) => controller.changeCategory(entry.key),
                backgroundColor: WordFlowDesign.paper,
                selectedColor: WordFlowDesign.plumWash,
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 13),
        _LockScreenStudySection(controller: controller),
        const SizedBox(height: 12),
        _AppGroupSyncExperiment(controller: controller),
        const SizedBox(height: 13),
        _SettingsSection(
          title: '英文發音',
          subtitle: '使用裝置內建的英文語音，不需要網路或 AI API。',
          child: Column(
            children: [
              _VoicePicker(controller: controller),
              const SizedBox(height: 6),
              Slider(
                min: 0.3,
                max: 0.7,
                divisions: 8,
                value: controller.speechRate.clamp(0.3, 0.7).toDouble(),
                label: '${(controller.speechRate / 0.5 * 100).round()}%',
                onChanged: controller.changeSpeechRate,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('較慢', style: TextStyle(fontSize: 12, color: Color(0xFF6E7E8A))),
                    Text('較快', style: TextStyle(fontSize: 12, color: Color(0xFF6E7E8A))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Container(
          decoration: BoxDecoration(
            color: WordFlowDesign.sage,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(18),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phonelink_lock_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('本機儲存 · 不用登入',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '收藏和複習記錄目前只存在這台手機。解除安裝 App 或清除資料可能導致記錄遺失。之後可加入匯出備份和跨裝置同步。',
                style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF506773)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _WordFlowVersionFooter(),
      ],
    );
  }
}



class _AppGroupSyncExperiment extends StatefulWidget {
  const _AppGroupSyncExperiment({required this.controller});
  final AppController controller;

  @override
  State<_AppGroupSyncExperiment> createState() => _AppGroupSyncExperimentState();
}

class _AppGroupSyncExperimentState extends State<_AppGroupSyncExperiment> {
  WidgetWordSyncState? _status;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _perform(WidgetWordSyncService.status);
    });
  }

  Future<void> _perform(Future<WidgetWordSyncState> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      if (!mounted) return;
      setState(() => _status = result);
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _error =
          '找不到原生同步橋接，請確認已安裝 App Groups 實驗版。');
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message ?? error.code);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '同步測試失敗：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final selected = WidgetWordSyncService.selectedItem(
      widget.controller, status);
    final usable = status?.available == true;

    return _SettingsSection(
      title: '鎖定畫面單字同步測試',
      subtitle: 'SideStore + App Groups 實驗版，不會改動學習紀錄。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          Text(
            status == null
                ? '正在檢查 App Groups 權限…'
                : usable
                    ? 'App 端：共用容器可用（Widget 端仍須實測）。'
                    : 'App 端：共用容器不可用。',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: usable
                  ? WordFlowDesign.sageDeep
                  : WordFlowDesign.muted,
            ),
          ),
          if (status?.reason != null) ...[
            const SizedBox(height: 8),
            Text(status!.reason!, style: WordFlowDesign.label),
          ],
          if (status?.groupId != null) ...[
            const SizedBox(height: 6),
            Text('使用的 App Group：${status!.groupId}',
                style: WordFlowDesign.label),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(
              fontSize: 13, color: Color(0xFF9D4438))),
          ],
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: WordFlowDesign.panel(
                color: WordFlowDesign.plumWash),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected == null ? '目前為每日自動單字' : selected.english,
                  style: WordFlowDesign.english(size: 26),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 6),
                  Text(selected.chinese, style: WordFlowDesign.body),
                ],
                const SizedBox(height: 8),
                Text('同步序號：#${status?.revision ?? 0}', style: WordFlowDesign.label),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: usable && !_busy
                ? () => _perform(() =>
                    WidgetWordSyncService.nextWord(widget.controller))
                : null,
            icon: const Icon(Icons.refresh),
            label: const Text('從 App 換下一個單字'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 5),
          Row(children: [
            TextButton(
              onPressed: usable && !_busy
                  ? () => _perform(WidgetWordSyncService.showDailyWord)
                  : null,
              child: const Text('恢復每日自動'),
            ),
            const Spacer(),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _perform(WidgetWordSyncService.status),
              child: const Text('重新檢查'),
            ),
          ]),
          const SizedBox(height: 9),
          const Text(
            '實測：按換字後鎖定 iPhone。小工具必須顯示相同英文，'
            '並出現「App 同步 #數字」，才算 App 與 Widget 共用資料成功。'
            '只看到 App 端成功還不算通過。',
            style: WordFlowDesign.label,
          ),
        ],
      ),
    );
  }
}

class _LockScreenStudySection extends StatefulWidget {
  const _LockScreenStudySection({required this.controller});
  final AppController controller;

  @override
  State<_LockScreenStudySection> createState() => _LockScreenStudySectionState();
}

class _LockScreenStudySectionState extends State<_LockScreenStudySection> {
  bool _busy = false;
  String? _message;

  Future<void> _run({required bool start}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (start) {
        await WordFlowLockScreenService.start(widget.controller);
      } else {
        await WordFlowLockScreenService.stop();
      }
      if (!mounted) return;
      setState(() {
        _message = start
            ? '四格單字已啟動。鎖定 iPhone 即可查看（系統可能延遲顯示）。'
            : '已停止鎖定畫面的四格單字。';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message ?? error.code);
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _message = '這個功能需要安裝包含 Live Activity 的新版 iOS IPA。');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = '無法操作：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: '鎖定畫面四格單字',
      subtitle: '像四宮格單字卡一樣，在鎖定畫面顯示 4 個英文單字與繁體中文。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: WordFlowDesign.plumWash,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: const Text(
              '這是 iOS 即時動態（Live Activity），不是永久 Widget。'
              ' 每次手動開啟後最長運作 8 小時，系統可能額外顯示最多 4 小時。'
              ' 單字取自上方選擇的程度和主題。',
              style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF604982)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(start: true),
            icon: const Icon(Icons.lock_clock_outlined),
            label: const Text('開始今日四格單字'),
            style: FilledButton.styleFrom(
              backgroundColor: WordFlowDesign.plum,
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: _busy ? null : () => _run(start: false),
            child: const Text('停止鎖定畫面單字'),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF604982))),
            ),
        ],
      ),
    );
  }
}

/// Read the actual version from the installed iOS/Android app.
class _WordFlowVersionFooter extends StatefulWidget {
  const _WordFlowVersionFooter();

  @override
  State<_WordFlowVersionFooter> createState() => _WordFlowVersionFooterState();
}

class _WordFlowVersionFooterState extends State<_WordFlowVersionFooter> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final details = snapshot.hasData
            ? 'v' + snapshot.data!.version + '  ·  Build ' + snapshot.data!.buildNumber
            : snapshot.hasError
                ? '版本資訊暫時無法讀取'
                : '正在讀取版本資訊';
        return Column(
          children: [
            const Text(
              'WORDFLOW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Color(0xFF718493),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF516C7D),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'iOS / Android · 本機離線學習',
              style: TextStyle(fontSize: 10, color: Color(0xFF97A6AF)),
            ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: BoxDecoration(
          color: WordFlowDesign.card,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: WordFlowDesign.rule),
        ),
        child: Column(
          children: [
            Text('$value',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 26, color: Color(0xFF167F83))),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6E7E8A))),
          ],
        ),
      );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6E7E8A))),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

/// Lets the learner pick a natural-sounding English voice and preview it.
class _VoicePicker extends StatefulWidget {
  const _VoicePicker({required this.controller});

  final AppController controller;

  @override
  State<_VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends State<_VoicePicker> {
  late final Future<List<TtsVoice>> _voices =
      widget.controller.speech.englishVoices();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TtsVoice>>(
      future: _voices,
      builder: (context, snapshot) {
        final voices = snapshot.data ?? const <TtsVoice>[];
        final selected = voices.any((v) => v.name == widget.controller.voiceName)
            ? widget.controller.voiceName
            : null;
        final hasHighQuality = voices.any((v) => v.isHighQuality);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: selected,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(voices.isEmpty
                              ? '自動選擇'
                              : '自動（${voices.first.name}）'),
                        ),
                        for (final voice in voices)
                          DropdownMenuItem<String?>(
                            value: voice.name,
                            child: Text(voice.label,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (name) {
                        widget.controller.changeVoice(name);
                        widget.controller.speak('Nice to meet you.');
                      },
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '試聽',
                    onPressed: () => widget.controller.speak('Nice to meet you.'),
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ],
              ),
              if (snapshot.connectionState == ConnectionState.done &&
                  !hasHighQuality &&
                  defaultTargetPlatform == TargetPlatform.iOS)
                const Text(
                  '聲音太像機器人？到 iPhone「設定 › 輔助使用 › 朗讀內容 › 聲音 › 英文」'
                  '下載標示「增強」或「高品質」的語音（例如 Ava、Samantha），'
                  '回到 App 重新開啟後就會自動使用。',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF6E7E8A)),
                ),
            ],
          ),
        );
      },
    );
  }
}
