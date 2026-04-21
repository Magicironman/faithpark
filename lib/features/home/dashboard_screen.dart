import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/services/app_state.dart';
import '../spiritual/scripture_reference_formatter.dart';
import '../spiritual/spiritual_content.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final isCantonese = appState.isCantoneseMode;
    final bibleInEnglish = appState.showBibleEnglish;
    final dailyVerse = appState.dailyVerse;
    final featuredVerse = appState.featuredVerse;
    final weather = appState.localWeather;
    final forecastDays = appState.selectedWeatherForecasts;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDF8F0),
            Color(0xFFF8F1E3),
            Color(0xFFE7F3EE),
          ],
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<DateTime>(
          stream: Stream.periodic(
              const Duration(minutes: 1), (_) => DateTime.now()),
          initialData: DateTime.now(),
          builder: (context, snapshot) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              appState.ensureDailyVerseCurrent();
              appState.ensureLocalConditionsCurrent();
            });

            final now = snapshot.data ?? DateTime.now();
            final todayLabel = isCantonese
                ? DateFormat('yyyy-MM-dd（EEEE）', 'zh_HK').format(now)
                : DateFormat('yyyy-MM-dd (EEEE)').format(now);

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
              children: [
                _SectionHeader(
                  icon: '💛',
                  iconBg: const Color(0xFFFFF3E0),
                  title: isCantonese ? '心情選擇' : 'Mood Filters',
                ),
                const SizedBox(height: 12),
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
                          onSelected: (_) =>
                              appState.setSelectedCategory(category),
                          label: Text(
                            spiritualCategoryLabel(category, !bibleInEnglish),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF4A5540),
                            ),
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF2E7D52),
                          side: const BorderSide(
                              color: Color(0xFFE5DDD0), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (featuredVerse != null) ...[
                  const SizedBox(height: 12),
                  _SelectedVerseCard(
                    categoryLabel: spiritualCategoryLabel(
                      appState.selectedCategory,
                      !bibleInEnglish,
                    ),
                    reference: formatReferenceForDisplay(
                      featuredVerse.reference,
                      english: bibleInEnglish,
                    ),
                    text: bibleInEnglish
                        ? featuredVerse.textEn
                        : featuredVerse.textZhHant,
                    isCantonese: isCantonese,
                  ),
                ],
                const SizedBox(height: 20),
                _SectionHeader(
                  icon: '🌤️',
                  iconBg: const Color(0xFFE3F2FD),
                  title: isCantonese ? '附近天氣及交通' : 'Nearby Weather & Traffic',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ForecastToggle(
                      label: isCantonese ? '🕐 今天' : '🕐 Today',
                      selected: appState.weatherRangeDays == 1,
                      onTap: () => appState.setWeatherRangeDays(1),
                    ),
                    _ForecastToggle(
                      label: isCantonese ? '🕙 10 天' : '🕙 10 Days',
                      selected: appState.weatherRangeDays == 10,
                      onTap: () => appState.setWeatherRangeDays(10),
                    ),
                    _ForecastToggle(
                      label: isCantonese ? '🗓️ 20 天' : '🗓️ 20 Days',
                      selected: appState.weatherRangeDays == 20,
                      onTap: () => appState.setWeatherRangeDays(20),
                    ),
                  ],
                ),
                if (appState.weatherRangeDays == 20) ...[
                  const SizedBox(height: 8),
                  Text(
                    isCantonese
                        ? 'Open-Meteo 目前最多提供 16 天預報，所以 20 天模式會顯示 16 天。'
                        : 'Open-Meteo currently provides up to 16 forecast days, so 20-day mode shows 16 days.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B6B60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (weather != null)
                  _WeatherDashboard(
                    weather: weather,
                    forecasts: forecastDays,
                    isCantonese: isCantonese,
                    appState: appState,
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ForecastToggle(
                      label: isCantonese ? '5 英里' : '5 miles',
                      selected: appState.trafficRadiusMiles == 5,
                      onTap: () =>
                          appState.refreshLocalConditions(radiusMiles: 5),
                    ),
                    _ForecastToggle(
                      label: isCantonese ? '10 英里' : '10 miles',
                      selected: appState.trafficRadiusMiles == 10,
                      onTap: () =>
                          appState.refreshLocalConditions(radiusMiles: 10),
                    ),
                    _ForecastToggle(
                      label: isCantonese ? '20 英里' : '20 miles',
                      selected: appState.trafficRadiusMiles == 20,
                      onTap: () =>
                          appState.refreshLocalConditions(radiusMiles: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TrafficDashboard(
                  appState: appState,
                  isCantonese: isCantonese,
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  icon: '✝️',
                  iconBg: const Color(0xFFFFF8E1),
                  title: isCantonese ? '每日金句' : 'Daily Verse',
                ),
                const SizedBox(height: 12),
                if (dailyVerse != null)
                  _VerseSpotlight(
                    dateLabel: todayLabel,
                    reference: formatReferenceForDisplay(
                      dailyVerse.reference,
                      english: bibleInEnglish,
                    ),
                    text: bibleInEnglish
                        ? dailyVerse.textEn
                        : (dailyVerse.textZhHant.isNotEmpty
                            ? dailyVerse.textZhHant
                            : '今日中文經文暫未載入，請按重新載入。'),
                    commentary: bibleInEnglish
                        ? 'Daily reflection: stay steady, trust God, and keep moving one faithful step at a time.'
                        : '每日默想：當我們把重擔交託神，祂必賜力量與平安，叫我們可以繼續前行。',
                    isCantonese: isCantonese,
                    onPickAnother: appState.pickAnotherFeaturedVerse,
                    onReloadDailyVerse: () =>
                        appState.refreshDailyVerse(forceRefresh: true),
                  ),
                const SizedBox(height: 18),
                if (featuredVerse != null)
                  _PsalmCard(
                    reference: formatReferenceForDisplay(
                      featuredVerse.reference,
                      english: bibleInEnglish,
                    ),
                    text: bibleInEnglish
                        ? featuredVerse.textEn
                        : featuredVerse.textZhHant,
                    buttonLabel:
                        bibleInEnglish ? 'Read Full Passage' : '閱讀完整經文',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconBg,
    required this.title,
  });

  final String icon;
  final Color iconBg;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ForecastToggle extends StatelessWidget {
  const _ForecastToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF1476C8) : Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF1476C8) : const Color(0xFFE5DDD0),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : const Color(0xFF4A5540),
        ),
      ),
    );
  }
}

class _WeatherDashboard extends StatelessWidget {
  const _WeatherDashboard({
    required this.weather,
    required this.forecasts,
    required this.isCantonese,
    required this.appState,
  });

  final WeatherSnapshot weather;
  final List<DailyWeatherForecast> forecasts;
  final bool isCantonese;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final weatherEmoji = _weatherEmoji(weather.weatherCode);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1476C8), Color(0xFF0D5299)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.regionLabel.isEmpty
                            ? (isCantonese ? '定位中...' : 'Resolving location...')
                            : '📍 ${weather.regionLabel}',
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${weather.temperatureC.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${weatherEmoji} ${appState.weatherCodeLabel(weather.weatherCode, cantonese: isCantonese)}',
                        style: const TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  weatherEmoji,
                  style: const TextStyle(fontSize: 38),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    _WeatherStat(
                      icon: '💧',
                      value: '${weather.relativeHumidity.toStringAsFixed(0)}%',
                      label: isCantonese ? '濕度' : 'Humidity',
                    ),
                    _WeatherStat(
                      icon: '💨',
                      value: '${weather.windSpeedKph.toStringAsFixed(0)} km/h',
                      label: isCantonese ? '風速' : 'Wind',
                    ),
                    _WeatherStat(
                      icon: '🌡️',
                      value: '${weather.temperatureMinC.toStringAsFixed(0)}°C',
                      label: isCantonese ? '最低' : 'Low',
                    ),
                    _WeatherStat(
                      icon: '☀️',
                      value: '${weather.temperatureMaxC.toStringAsFixed(0)}°C',
                      label: isCantonese ? '最高' : 'High',
                    ),
                  ],
                ),
                if (forecasts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: forecasts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = forecasts[index];
                        final cantoneseWeekdays = const [
                          '\u661f\u671f\u65e5',
                          '\u661f\u671f\u4e00',
                          '\u661f\u671f\u4e8c',
                          '\u661f\u671f\u4e09',
                          '\u661f\u671f\u56db',
                          '\u661f\u671f\u4e94',
                          '\u661f\u671f\u516d',
                        ];
                        final dayLabelDisplay = index == 0
                            ? (isCantonese ? '\u4eca\u5929' : 'Today')
                            : (isCantonese
                                ? cantoneseWeekdays[item.date.weekday % 7]
                                : DateFormat('EEE', 'en').format(item.date));
                        final dateLabel = DateFormat('M/d').format(item.date);
                        return Container(
                          width: 60,
                          padding: const EdgeInsets.fromLTRB(4, 5, 4, 5),
                          decoration: BoxDecoration(
                            color: _forecastBackground(item.weatherCode),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFDCE8F4), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dayLabelDisplay,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3C4A45),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF72807A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _weatherEmoji(item.weatherCode),
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${item.tempMaxC.toStringAsFixed(0)}° / ${item.tempMinC.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                isCantonese
                                    ? '雨量 ${item.precipitationProbability}%'
                                    : 'Rain ${item.precipitationProbability}%',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF6C7A75),
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weatherEmoji(int code) {
    return switch (code) {
      0 => '☀️',
      1 || 2 => '⛅',
      3 => '☁️',
      45 || 48 => '🌫️',
      51 || 53 || 55 || 61 || 63 || 65 || 80 || 81 || 82 => '🌧️',
      71 || 73 || 75 || 77 || 85 || 86 => '❄️',
      95 || 96 || 99 => '⛈️',
      _ => '🌤️',
    };
  }

  Color _forecastBackground(int code) {
    return switch (code) {
      0 => const Color(0xFFFFF8DB),
      1 || 2 => const Color(0xFFF3F8FF),
      3 || 45 || 48 => const Color(0xFFF0F4F8),
      51 ||
      53 ||
      55 ||
      61 ||
      63 ||
      65 ||
      80 ||
      81 ||
      82 =>
        const Color(0xFFEAF4FF),
      71 || 73 || 75 || 77 || 85 || 86 => const Color(0xFFF3F7FF),
      95 || 96 || 99 => const Color(0xFFF9EDF3),
      _ => const Color(0xFFF8FBFF),
    };
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B6B60),
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SelectedVerseCard extends StatelessWidget {
  const _SelectedVerseCard({
    required this.categoryLabel,
    required this.reference,
    required this.text,
    required this.isCantonese,
  });

  final String categoryLabel;
  final String reference;
  final String text;
  final bool isCantonese;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE7E0D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCantonese
                ? '🎯 即時經文 · $categoryLabel'
                : '🎯 Selected Verse · $categoryLabel',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB87312),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reference,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A2018),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D4A45),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficDashboard extends StatelessWidget {
  const _TrafficDashboard({
    required this.appState,
    required this.isCantonese,
  });

  final AppState appState;
  final bool isCantonese;

  @override
  Widget build(BuildContext context) {
    final traffic = appState.localTraffic;
    final incidents = traffic?.incidents.take(3).toList() ?? const [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: '🚗',
            iconBg: const Color(0xFFFCE4EC),
            title: isCantonese ? '附近交通狀況' : 'Nearby Traffic',
          ),
          const SizedBox(height: 8),
          if (traffic != null && traffic.isAvailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                isCantonese
                    ? '${traffic.radiusMiles} 英里內找到 ${traffic.incidents.length} 宗即時交通事件'
                    : '${traffic.incidents.length} live traffic incidents found within ${traffic.radiusMiles} miles',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A5540),
                ),
              ),
            ),
          if (traffic != null &&
              !traffic.isAvailable &&
              (traffic.errorMessage?.isNotEmpty ?? false))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF2C9C2)),
              ),
              child: Text(
                isCantonese
                    ? '交通資料未能載入：${traffic.errorMessage}'
                    : 'Traffic could not be loaded: ${traffic.errorMessage}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A3C2D),
                ),
              ),
            )
          else if (incidents.isEmpty)
            Text(
              isCantonese
                  ? '暫時未見明顯交通事件。'
                  : 'No major traffic incidents nearby.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            )
          else
            ...incidents.map((incident) {
              final color = appState.trafficSeverityColor(incident);
              final subtitle = incident.delayMinutes >= 10
                  ? (isCantonese
                      ? '嚴重擠塞 ❗ — 延誤約 ${incident.delayMinutes} 分鐘'
                      : 'Heavy congestion — about ${incident.delayMinutes} minutes delay')
                  : incident.delayMinutes >= 4
                      ? (isCantonese
                          ? '輕微慢行 ⚠️ — 延誤約 ${incident.delayMinutes} 分鐘'
                          : 'Slow traffic — about ${incident.delayMinutes} minutes delay')
                      : (isCantonese ? '交通暢順 ✅' : 'Traffic moving well');
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5DDD0)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.28),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_trafficEmoji(incident.category)} ${incident.title}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A2018),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A5540),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _openTrafficMap(incident),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              side: const BorderSide(
                                  color: Color(0xFFBFD6CB), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: Color(0xFF1A5C35),
                            ),
                            label: Text(
                              isCantonese
                                  ? '在 Google Maps 查看'
                                  : 'Open in Google Maps',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A5C35),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

String _trafficEmoji(String category) {
  return switch (category) {
    'Jam' => '🚦',
    'Road closed' => '⛔',
    'Road works' => '🚧',
    'Lane closed' => '🛑',
    'Incident' => '🚨',
    'Broken down vehicle' => '🛻',
    'Accident' => '💥',
    'Weather' => '🌧️',
    _ => '🛣️',
  };
}

Future<void> _openTrafficMap(TrafficIncident incident) async {
  final roadQuery = _trafficSearchQuery(incident);
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(roadQuery)}',
  );
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

String _trafficSearchQuery(TrafficIncident incident) {
  final normalized = incident.title
      .replaceAll('|', ' ')
      .replaceAll('/', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final withoutPrefix = normalized
      .replaceFirst(
          RegExp(
              r'^(Queueing traffic|Slow traffic|Stationary traffic|Heavy traffic)\s*',
              caseSensitive: false),
          '')
      .trim();

  final byCategory = switch (incident.category.toLowerCase()) {
    'jam' => 'traffic jam',
    'incident' => 'traffic incident',
    'road closed' => 'road closure',
    'road works' => 'road work',
    'lane closed' => 'lane closure',
    'accident' => 'car accident',
    _ => 'traffic',
  };

  return '$withoutPrefix $byCategory'.trim();
}

class _VerseSpotlight extends StatelessWidget {
  const _VerseSpotlight({
    required this.dateLabel,
    required this.reference,
    required this.text,
    required this.commentary,
    required this.isCantonese,
    required this.onPickAnother,
    required this.onReloadDailyVerse,
  });

  final String dateLabel;
  final String reference;
  final String text;
  final String commentary;
  final bool isCantonese;
  final VoidCallback onPickAnother;
  final VoidCallback onReloadDailyVerse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        border: const Border(
          left: BorderSide(color: Color(0xFFF5A623), width: 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 ${isCantonese ? '今日' : 'Today'} $dateLabel',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A5540)),
          ),
          const SizedBox(height: 6),
          Text(
            '📖 $reference',
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE07B00)),
          ),
          const SizedBox(height: 10),
          Text(
            '「$text」',
            style: const TextStyle(
              fontSize: 21,
              height: 1.75,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '💡 $commentary',
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF4A5540),
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: onPickAnother,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE07B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child:
                    Text(isCantonese ? '📤 選另一段金句' : '📤 Pick Another Verse'),
              ),
              FilledButton.tonal(
                onPressed: onReloadDailyVerse,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: Text(isCantonese ? '↻ 重新載入' : '↻ Reload'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PsalmCard extends StatelessWidget {
  const _PsalmCard({
    required this.reference,
    required this.text,
    required this.buttonLabel,
  });

  final String reference;
  final String text;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A1D96), Color(0xFF6A3D9A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              '🕊️ Psalm Highlight',
              style: TextStyle(
                color: Color(0xFFE9D5FF),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '📖 $reference',
            style: const TextStyle(
              color: Color(0xFFD8B4FE),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「$text」',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.7,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6A3D9A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
