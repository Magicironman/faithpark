import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/services/app_state.dart';
import '../parking/parking_screen.dart';
import '../settings/settings_screen.dart';
import '../spiritual/spiritual_screen.dart';
import '../voice/voice_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    ParkingScreen(),
    SpiritualScreen(),
    VoiceScreen(),
    SettingsScreen(),
  ];

  static const _zhLabels = ['主頁', '泊車', '聖經', '助理', '設定'];
  static const _enLabels = ['Home', 'Parking', 'Bible', 'Agent', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final isCantonese = appState.isCantoneseMode;
    final labels = isCantonese ? _zhLabels : _enLabels;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A3D2B),
                    Color(0xFF2A5C40),
                    Color(0xFF1E4D32),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      _LanguageChip(
                        label: '廣東話',
                        selected: isCantonese,
                        onTap: () => appState.setLanguage(
                          code: 'zh',
                          cantoneseVoice: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _LanguageChip(
                        label: 'English',
                        selected: !isCantonese,
                        onTap: () => appState.setLanguage(
                          code: 'en',
                          cantoneseVoice: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _HeaderQuickButton(
                      label: isCantonese ? '停泊汽車' : 'Parked Car',
                      icon: Icons.directions_car_filled_rounded,
                      colors: const [Color(0xFF74B9FF), Color(0xFF2563EB)],
                      onTap: () {
                        setState(() => _index = 1);
                        _openParkedCarSheet(appState, isCantonese);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD8A487)
                                  .withValues(alpha: 0.24),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/images/faithpark_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FAITHPARK',
                              style: theme.textTheme.labelMedium?.copyWith(
                                letterSpacing: 2.2,
                                color: const Color(0xFFE8C97A),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[_index],
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitleForIndex(_index, isCantonese),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF8FB89A),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F4),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3D2B).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(_screens.length, (index) {
                    final selected = _index == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _index = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1A3D2B)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1A3D2B)
                                          .withValues(alpha: 0.20),
                                      blurRadius: 16,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TabBadge(index: index, selected: selected),
                              const SizedBox(height: 6),
                              Text(
                                labels[index],
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF8A9E8F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: _screens[_index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleForIndex(int index, bool isCantonese) {
    if (!isCantonese) {
      return switch (index) {
        0 => 'Overview, parking reminder, devotional summary',
        1 => 'Save parking info, parked car card, parking countdown',
        2 => 'Daily verse, category verses, language switch',
        3 => 'Voice commands, weather, traffic, scripture reading',
        4 => 'Language, default parking time, preferences',
        _ => '',
      };
    }

    return switch (index) {
      0 => '首頁總覽、泊車提醒、靈修摘要',
      1 => '輸入泊車資料、停泊汽車卡、泊車倒數',
      2 => '今日金句、分類經文、中英切換',
      3 => '廣東話指令、天氣交通查詢、經文朗讀',
      4 => '語言、預設泊車時間、偏好設定',
      _ => '',
    };
  }

  void _openParkedCarSheet(AppState appState, bool isCantonese) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F0E8),
      builder: (context) {
        final photoEntries = <_ParkedCarPhotoItemData>[];
        final activeParking = appState.activeParking;
        final seenParkingIds = <String>{};

        if (activeParking?.photoBase64 != null &&
            activeParking!.photoBase64!.isNotEmpty) {
          seenParkingIds.add(activeParking.id);
          photoEntries.add(
            _ParkedCarPhotoItemData(
              id: activeParking.id,
              title: isCantonese ? '目前停泊汽車' : 'Current parked car',
              subtitle: activeParking.label.isEmpty
                  ? (isCantonese ? '已儲存位置' : 'Saved location')
                  : activeParking.label,
              photoBase64: activeParking.photoBase64!,
              latitude: activeParking.latitude,
              longitude: activeParking.longitude,
              parkedAt: activeParking.savedAt,
              expiresAt: activeParking.expiresAt,
              alertLeadMinutesList: activeParking.alertLeadMinutesList,
              reminderCount: activeParking.alertLeadMinutesList.length >= 2 ? 2 : 1,
              isActive: true,
            ),
          );
        }

        for (final item in appState.parkingHistory) {
          if (item.photoBase64 == null || item.photoBase64!.isEmpty) {
            continue;
          }
          if (seenParkingIds.contains(item.id)) {
            continue;
          }
          seenParkingIds.add(item.id);
          photoEntries.add(
            _ParkedCarPhotoItemData(
              id: item.id,
              title: item.label.isEmpty
                  ? (isCantonese ? '停泊相片紀錄' : 'Saved parking photo')
                  : item.label,
              subtitle:
                  '${item.savedAt.year}-${item.savedAt.month.toString().padLeft(2, '0')}-${item.savedAt.day.toString().padLeft(2, '0')} ${item.savedAt.hour.toString().padLeft(2, '0')}:${item.savedAt.minute.toString().padLeft(2, '0')}',
              photoBase64: item.photoBase64!,
              latitude: item.latitude,
              longitude: item.longitude,
              parkedAt: item.savedAt,
              expiresAt:
                  item.savedAt.add(Duration(minutes: item.durationMinutes)),
              alertLeadMinutesList: item.alertLeadMinutesList,
              reminderCount: item.alertLeadMinutesList.length >= 2 ? 2 : 1,
              isActive: activeParking?.id == item.id,
            ),
          );
        }

        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            maxChildSize: 0.95,
            minChildSize: 0.45,
            builder: (context, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF74B9FF), Color(0xFF2563EB)],
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isCantonese ? '停泊汽車' : 'Parked Car',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1C2B20),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCantonese
                        ? '這裡會顯示目前相片及已儲存相片。'
                        : 'Current and saved parking photos appear here.',
                    style: const TextStyle(
                      color: Color(0xFF6D8077),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (photoEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        isCantonese
                            ? '而家未有已儲存相片。'
                            : 'There are no saved photos yet.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF66756E),
                        ),
                      ),
                    )
                  else
                    ...photoEntries.map(
                      (item) => _ParkedCarPhotoItem(
                        data: item,
                        isCantonese: isCantonese,
                        onDeletePhoto: () async {
                          await appState.deleteParkingHistoryPhoto(item.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isCantonese
                                      ? 'Deleted the saved parking photo.'
                                      : 'Deleted the saved parking photo.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({
    required this.index,
    required this.selected,
  });

  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = switch (index) {
      0 => Icons.home_rounded,
      1 => Icons.local_parking_rounded,
      2 => Icons.menu_book_rounded,
      3 => Icons.mic_rounded,
      _ => Icons.settings_rounded,
    };
    final colors = switch (index) {
      0 => const [Color(0xFFFFB36B), Color(0xFFE85D3F)],
      1 => const [Color(0xFF74B9FF), Color(0xFF2563EB)],
      2 => const [Color(0xFFA78BFA), Color(0xFF6D28D9)],
      3 => const [Color(0xFFFF8AAE), Color(0xFFE11D48)],
      _ => const [Color(0xFFC4B5FD), Color(0xFF7C3AED)],
    };

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? colors
              : [
                  colors.first.withValues(alpha: 0.22),
                  colors.last.withValues(alpha: 0.22),
                ],
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : colors.last,
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 84),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          softWrap: false,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF14342B) : const Color(0xFF34584D),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFDCEFE7),
        side: BorderSide(
          color: selected ? const Color(0xFFDCEFE7) : const Color(0xFFBFD6CB),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _HeaderQuickButton extends StatelessWidget {
  const _HeaderQuickButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF081C14).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF234537),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParkedCarPhotoItemData {
  const _ParkedCarPhotoItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.photoBase64,
    required this.latitude,
    required this.longitude,
    required this.parkedAt,
    required this.expiresAt,
    required this.alertLeadMinutesList,
    required this.reminderCount,
    required this.isActive,
  });

  final String id;
  final String title;
  final String subtitle;
  final String photoBase64;
  final double latitude;
  final double longitude;
  final DateTime parkedAt;
  final DateTime expiresAt;
  final List<int> alertLeadMinutesList;
  final int reminderCount;
  final bool isActive;
}

class _ParkedCarPhotoItem extends StatelessWidget {
  const _ParkedCarPhotoItem({
    required this.data,
    required this.isCantonese,
    required this.onDeletePhoto,
  });

  final _ParkedCarPhotoItemData data;
  final bool isCantonese;
  final Future<void> Function() onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final imageBytes = base64Decode(data.photoBase64);
    final now = DateTime.now();
    final timeLeft = data.expiresAt.difference(now);
    final isExpired = timeLeft.isNegative;
    final countdownText = data.isActive
        ? (isExpired
            ? (isCantonese
                ? '已超時 ${_formatDuration(timeLeft.abs())}'
                : 'Expired ${_formatDuration(timeLeft.abs())} ago')
            : (isCantonese
                ? '仲有 ${_formatDuration(timeLeft)}'
                : '${_formatDuration(timeLeft)} remaining'))
        : (isExpired
            ? (isCantonese ? '已完結' : 'Completed')
            : (isCantonese ? '紀錄未到期' : 'Saved before expiry'));
    final reminderText = data.alertLeadMinutesList.isEmpty
        ? (isCantonese ? '未設定提醒' : 'No reminder set')
        : (isCantonese
            ? '提醒設定：完結前 ${data.alertLeadMinutesList.join('、')} 分鐘'
            : 'Reminder: ${data.alertLeadMinutesList.join(', ')} min before end');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3D2B).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C2B20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: const TextStyle(
                color: Color(0xFF6D8077),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              countdownText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C2B20),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reminderText,
              style: const TextStyle(
                color: Color(0xFF486157),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCantonese
                  ? '泊車時間：${DateFormat('M/d h:mm a').format(data.parkedAt)}'
                  : 'Parked: ${DateFormat('M/d h:mm a').format(data.parkedAt)}',
              style: const TextStyle(
                  color: Color(0xFF66756E), fontWeight: FontWeight.w700),
            ),
            Text(
              isCantonese
                  ? '到期時間：${DateFormat('M/d h:mm a').format(data.expiresAt)}'
                  : 'Expires: ${DateFormat('M/d h:mm a').format(data.expiresAt)}',
              style: const TextStyle(
                  color: Color(0xFF66756E), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${data.latitude.toStringAsFixed(5)}, ${data.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                color: Color(0xFF1D4F7A),
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                imageBytes,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                onDeletePhoto();
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete photo'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => _openMap(data.latitude, data.longitude),
              icon: const Icon(Icons.map_rounded),
              label: Text(
                  isCantonese ? '在 Google Maps 查看' : 'Open in Google Maps'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String _formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes.abs();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  }
  if (hours > 0) {
    return '${hours}h';
  }
  return '${minutes}m';
}
