import 'package:flutter/material.dart';
import 'package:y2notes2/features/stickers/data/sticker_packs.dart';
import 'package:y2notes2/features/stickers/domain/entities/sticker_element.dart';

typedef OnStickerSelected = void Function(StickerElement template);

class StickerPickerPanel extends StatefulWidget {
  const StickerPickerPanel({
    super.key,
    required this.onSelected,
  });

  final OnStickerSelected onSelected;

  @override
  State<StickerPickerPanel> createState() => _StickerPickerPanelState();
}

class _StickerPickerPanelState extends State<StickerPickerPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search stickers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Emoji'),
                Tab(text: 'Stamps'),
                Tab(text: 'Washi'),
              ],
            ),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EmojiTab(
                    query: _searchQuery,
                    onSelected: widget.onSelected,
                  ),
                  _StampsTab(
                    query: _searchQuery,
                    onSelected: widget.onSelected,
                  ),
                  _WashiTab(
                    query: _searchQuery,
                    onSelected: widget.onSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Emoji tab ──────────────────────────────────────────────────────────────

class _EmojiTab extends StatelessWidget {
  const _EmojiTab({required this.query, required this.onSelected});

  final String query;
  final OnStickerSelected onSelected;

  @override
  Widget build(BuildContext context) {
    final allEmojis = StickerPacks.emojiPacks.entries
        .expand((entry) =>
            entry.value.map((e) => (category: entry.key, emoji: e)))
        .toList();

    final filtered = query.isEmpty
        ? allEmojis
        : allEmojis
            .where((e) =>
                e.emoji.contains(query) ||
                e.category.toLowerCase().contains(query))
            .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final item = filtered[i];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            final template = StickerElement(
              type: StickerType.emoji,
              assetKey: item.emoji,
              position: Offset.zero,
            );
            onSelected(template);
          },
          child: Center(
            child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
          ),
        );
      },
    );
  }
}

// ─── Stamps tab ─────────────────────────────────────────────────────────────

class _StampsTab extends StatelessWidget {
  const _StampsTab({required this.query, required this.onSelected});

  final String query;
  final OnStickerSelected onSelected;

  @override
  Widget build(BuildContext context) {
    final stamps = StickerPacks.allStamps;
    final filtered = query.isEmpty
        ? stamps
        : stamps
            .where((s) =>
                s.name.toLowerCase().contains(query) ||
                s.category.toLowerCase().contains(query))
            .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final stamp = filtered[i];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            final template = StickerElement(
              type: StickerType.stamp,
              assetKey: stamp.id,
              position: Offset.zero,
            );
            onSelected(template);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, color: Colors.deepPurple.shade400),
                const SizedBox(height: 4),
                Text(
                  stamp.name,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Washi tab ───────────────────────────────────────────────────────────────

class _WashiTab extends StatelessWidget {
  const _WashiTab({required this.query, required this.onSelected});

  final String query;
  final OnStickerSelected onSelected;

  @override
  Widget build(BuildContext context) {
    final patterns = StickerPacks.washiPatterns;
    final filtered = query.isEmpty
        ? patterns
        : patterns
            .where((p) => p.name.toLowerCase().contains(query))
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final pattern = filtered[i];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            final template = StickerElement(
              type: StickerType.washi,
              assetKey: pattern.id,
              position: Offset.zero,
              washiLength: 200.0,
              washiWidth: 40.0,
            );
            onSelected(template);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            height: 48,
            decoration: BoxDecoration(
              color: pattern.color.withOpacity(pattern.opacity),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: pattern.color.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                pattern.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
      },
    );
  }
}
