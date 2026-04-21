import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/models.dart';
import '../../core/services/app_state.dart';
import 'scripture_reference_formatter.dart';
import 'spiritual_content.dart';

class SpiritualScreen extends StatelessWidget {
  const SpiritualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final verses = appState.selectedCategoryVerses;
    final featuredVerse = appState.featuredVerse;
    final showEnglish = appState.showBibleEnglish;

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now()),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.ensureDailyVerseCurrent();
        });

        final now = snapshot.data ?? DateTime.now();
        final dateLabel = showEnglish
            ? DateFormat('yyyy-MM-dd EEEE').format(now)
            : DateFormat('yyyy-MM-dd EEEE', 'zh_HK').format(now);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: spiritualCategories.map((category) {
                  final selected = appState.selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      onSelected: (_) => appState.setSelectedCategory(category),
                      label: Text(spiritualCategoryLabel(category, !showEnglish)),
                      avatar: Icon(
                        _iconForCategory(category),
                        size: 16,
                        color: selected ? Colors.white : const Color(0xFF8A9E8F),
                      ),
                      selectedColor: const Color(0xFF1A3D2B),
                      backgroundColor: const Color(0xFFFAF8F4),
                      side: const BorderSide(color: Color(0xFFE0DDD6)),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF4A5E50),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (featuredVerse != null) ...[
              const SizedBox(height: 14),
              _FeaturedCategoryVerseCard(
                verse: featuredVerse,
                showEnglish: showEnglish,
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A3D2B),
                    Color(0xFF2A5C40),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A3D2B).withValues(alpha: 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      showEnglish ? 'Daily Verse' : '今日金句',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFE8C97A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8FB89A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (appState.isLoadingDailyVerse)
                    const LinearProgressIndicator()
                  else if (appState.dailyVerse != null) ...[
                    Text(
                      '“${showEnglish ? appState.dailyVerse!.textEn : (appState.dailyVerse!.textZhHant.isNotEmpty ? appState.dailyVerse!.textZhHant : '今日中文經文暫未載入，請按重新載入。')}”',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatReferenceForDisplay(
                        appState.dailyVerse!.reference,
                        english: showEnglish,
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8FB89A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: appState.speakDailyVerse,
                          icon: const Icon(Icons.volume_up_rounded),
                          label: Text(showEnglish ? 'Play' : '播放'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await appState.refreshDailyVerse();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  showEnglish ? 'Daily verse reloaded.' : '今日金句已重新載入。',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            showEnglish ? 'Refresh' : '重新載入',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      appState.dailyVerseError ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  showEnglish ? 'Curated Verses' : '精選經文',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C2B20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Divider(
                    color: const Color(0xFF8FB89A).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              showEnglish
                  ? '${spiritualCategoryLabel(appState.selectedCategory, false)} • ${verses.length} verses'
                  : '分類 ${spiritualCategoryLabel(appState.selectedCategory, true)} 共 ${verses.length} 節',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8A9E8F),
              ),
            ),
            const SizedBox(height: 16),
            ...verses.map(
              (verse) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CuratedVerseCard(
                  verse: verse,
                  showEnglish: showEnglish,
                  onPlay: () => appState.speakCuratedVerse(verse),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'peace' => Icons.favorite_rounded,
      'anxiety' => Icons.self_improvement_rounded,
      'wisdom' => Icons.lightbulb_rounded,
      'encouragement' => Icons.emoji_emotions_rounded,
      'faith' => Icons.auto_awesome_rounded,
      'hope' => Icons.wb_sunny_rounded,
      'walk_with_god' => Icons.directions_walk_rounded,
      'proverbs' => Icons.menu_book_rounded,
      'psalms' => Icons.music_note_rounded,
      _ => Icons.book_rounded,
    };
  }
}

class _CuratedVerseCard extends StatelessWidget {
  const _CuratedVerseCard({
    required this.verse,
    required this.showEnglish,
    required this.onPlay,
  });

  final VerseEntry verse;
  final bool showEnglish;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3D2B).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6E6DE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“${showEnglish ? verse.textEn : verse.textZhHant}”',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF1C2B20),
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            formatReferenceForDisplay(verse.reference, english: showEnglish),
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFFC9A84C),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEDE6D8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(showEnglish ? 'Play' : '播放'),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(showEnglish ? 'Copy' : '複製'),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(showEnglish ? 'Share' : '分享'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedCategoryVerseCard extends StatelessWidget {
  const _FeaturedCategoryVerseCard({
    required this.verse,
    required this.showEnglish,
  });

  final VerseEntry verse;
  final bool showEnglish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3D2B).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFDCE7DF), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showEnglish ? 'Selected Verse' : '即時經文',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFFB07D2A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatReferenceForDisplay(verse.reference, english: showEnglish),
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1C2B20),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showEnglish ? verse.textEn : verse.textZhHant,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.55,
              color: const Color(0xFF31413A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
