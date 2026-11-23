import 'package:flutter/material.dart';

import '../../models/learning_item.dart';
import '../../services/app_controller.dart';
import '../theme/wordflow_design.dart';
import '../widgets/learning_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({required this.controller, super.key});

  final AppController controller;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _kind = 'word';
  String _category = 'all';
  String _query = '';
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.controller.items.where((item) {
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          item.english.toLowerCase().contains(query) ||
          item.chinese.contains(query) ||
          item.example.toLowerCase().contains(query);
      return item.kind == _kind &&
          (_category == 'all' || item.category == _category) &&
          (!_favoritesOnly || widget.controller.isFavorite(item)) &&
          matchesQuery;
    }).toList()
      ..sort((a, b) => a.english.compareTo(b.english));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('探索英文', style: WordFlowDesign.title(size: 29)),
              const SizedBox(height: 4),
              const Text('收集那些你想在生活中用上的字。', style: WordFlowDesign.label),
              const SizedBox(height: 17),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: '搜尋英文、中文或例句',
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'word', label: Text('單字')),
                        ButtonSegment(value: 'phrase', label: Text('詞句')),
                      ],
                      showSelectedIcon: false,
                      selected: {_kind},
                      onSelectionChanged: (value) =>
                          setState(() => _kind = value.first),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _favoritesOnly ? '顯示全部' : '只看收藏',
                    icon: Icon(_favoritesOnly
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded),
                    onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: FilterChip(
                        label: Text(entry.value),
                        selected: _category == entry.key,
                        onSelected: (_) => setState(() => _category = entry.key),
                        side: BorderSide.none,
                        backgroundColor: Colors.white,
                        selectedColor: WordFlowDesign.plumWash,
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 7, bottom: 7),
                child: Text('共 ${filtered.length} 筆內容',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7C8C97))),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('沒有符合的內容，試試其他關鍵字或主題。'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: WordFlowDesign.rule),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return InkWell(
                      onTap: () => showLearningDetails(
                          context, item, widget.controller),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 15),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.english,
                                style: WordFlowDesign.english(size: 24)),
                              const SizedBox(height: 5),
                              Text(item.chinese, style: WordFlowDesign.body,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 5),
                              Text('${item.level}  /  ${categoryName(item.category)}',
                                style: WordFlowDesign.label),
                            ],
                          )),
                          IconButton(
                            tooltip: '朗讀英文',
                            onPressed: () => speakEnglish(
                                context, widget.controller, item.english),
                            icon: const Icon(Icons.volume_up_outlined),
                            color: WordFlowDesign.plum,
                          ),
                          const Icon(Icons.chevron_right,
                            color: WordFlowDesign.muted, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
