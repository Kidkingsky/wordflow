import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../../services/lock_screen_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 36),
      children: [
        const Text('我的學習',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
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
                selectedColor: const Color(0xFFD5F1EA),
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
                backgroundColor: const Color(0xFFF3F6F7),
                selectedColor: const Color(0xFFD5F1EA),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 13),
        _LockScreenStudySection(controller: controller),
        const SizedBox(height: 13),
        _SettingsSection(
          title: '英文朗讀速度',
          subtitle: '使用裝置的英文語音朗讀，不需要 AI API。',
          child: Column(
            children: [
              Slider(
                min: 0.35,
                max: 0.65,
                divisions: 6,
                value: controller.speechRate,
                label: '${(controller.speechRate * 100).round()}%',
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
            color: const Color(0xFFEAF1F3),
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
        const Center(
          child: Text('WordFlow v0.1 · Flutter · iOS / Android',
              style: TextStyle(fontSize: 11, color: Color(0xFF97A6AF))),
        ),
      ],
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
              color: const Color(0xFFEDE4FA),
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
              backgroundColor: const Color(0xFF7652BB),
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

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
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
