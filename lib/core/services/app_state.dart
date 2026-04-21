import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../../features/spiritual/spiritual_content.dart';
import '../models/models.dart';
import 'local_conditions_service.dart';
import 'location_service.dart';
import 'news_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'speech_service.dart';
import 'spiritual_service.dart';
import 'tts_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.settingsService,
    required this.notificationService,
  });

  final SettingsService settingsService;
  final NotificationService notificationService;

  final TtsService ttsService = TtsService();
  final SpeechService speechService = SpeechService();
  final LocationService locationService = LocationService();
  final NewsService newsService = NewsService();
  final SpiritualService spiritualService = SpiritualService();
  final LocalConditionsService localConditionsService =
      LocalConditionsService();

  final List<ParkingSession> activeParkingSessions = [];
  String? selectedParkingSessionId;
  final List<ParkingHistoryEntry> parkingHistory = [];
  final List<ReminderItem> reminders = [];
  final List<NewsItem> newsItems = [];
  final Set<String> _firedForegroundParkingAlerts = <String>{};
  Timer? _parkingAlertTicker;
  bool _isHandlingForegroundParkingAlerts = false;

  String selectedCategory = spiritualCategories.first;
  String lastAgentHeard = '';
  String lastAgentReply = '';
  bool showBibleEnglish = false;
  int currentCategoryVerseIndex = 0;
  DailyVerse? dailyVerse;
  bool isLoadingDailyVerse = false;
  String? dailyVerseError;

  WeatherSnapshot? localWeather;
  TrafficSnapshot? localTraffic;
  String localRegionLabel = '';
  bool isLoadingConditions = false;
  String? localConditionsError;
  int trafficRadiusMiles = 10;
  int weatherRangeDays = 10;

  bool get isCantoneseMode => settingsService.speakInCantonese;

  ParkingSession? get activeParking {
    if (activeParkingSessions.isEmpty) {
      return null;
    }
    if (selectedParkingSessionId == null) {
      return activeParkingSessions.first;
    }
    return activeParkingSessions.firstWhere(
      (item) => item.id == selectedParkingSessionId,
      orElse: () => activeParkingSessions.first,
    );
  }

  Future<void> init() async {
    await ttsService.configure(cantonese: isCantoneseMode);
    await spiritualService.init();
    await _loadLocalData();
    _primeForegroundParkingAlerts();
    _startParkingAlertTicker();
    showBibleEnglish = !isCantoneseMode;
    _seedAgentReply();
    await refreshDailyVerse();
    await refreshLocalConditions();
  }

  List<VerseEntry> get selectedCategoryVerses {
    return spiritualService.getCategoryVerses(selectedCategory);
  }

  List<ParkingSession> get sortedActiveParkingSessions {
    final items = [...activeParkingSessions];
    items.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    return items;
  }

  VerseEntry? get featuredVerse {
    final verses = selectedCategoryVerses;
    if (verses.isEmpty) {
      return spiritualService.getPrimaryVerse(spiritualCategories.first);
    }
    return verses[currentCategoryVerseIndex % verses.length];
  }

  Duration? get parkingTimeLeft {
    if (activeParking == null) {
      return null;
    }
    return activeParking!.expiresAt.difference(DateTime.now());
  }

  double get parkingProgress {
    if (activeParking == null) {
      return 0;
    }
    final totalSeconds = activeParking!.durationMinutes * 60;
    if (totalSeconds <= 0) {
      return 1;
    }
    final elapsedSeconds =
        DateTime.now().difference(activeParking!.savedAt).inSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0, 1).toDouble();
  }

  String get parkingStatusLabel {
    final left = parkingTimeLeft;
    if (left == null) {
      return isCantoneseMode ? '未有進行中的泊車計時' : 'No active parking session';
    }
    if (left.isNegative) {
      return isCantoneseMode
          ? '已經超時 ${_formatDuration(left.abs())}'
          : 'Expired ${_formatDuration(left.abs())} ago';
    }
    return isCantoneseMode
        ? '仲有 ${_formatDuration(left)}'
        : '${_formatDuration(left)} remaining';
  }

  Duration? parkingTimeLeftFor(ParkingSession session) {
    return session.expiresAt.difference(DateTime.now());
  }

  double parkingProgressFor(ParkingSession session) {
    final totalSeconds = session.durationMinutes * 60;
    if (totalSeconds <= 0) {
      return 1;
    }
    final elapsedSeconds = DateTime.now().difference(session.savedAt).inSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0, 1).toDouble();
  }

  String parkingStatusLabelFor(ParkingSession session) {
    final left = parkingTimeLeftFor(session);
    if (left == null) {
      return isCantoneseMode ? '未有進行中的泊車計時' : 'No active parking session';
    }
    if (left.isNegative) {
      return isCantoneseMode
          ? '已經超時 ${_formatDuration(left.abs())}'
          : 'Expired ${_formatDuration(left.abs())} ago';
    }
    return isCantoneseMode
        ? '仲有 ${_formatDuration(left)}'
        : '${_formatDuration(left)} remaining';
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final activeParkingJson =
        prefs.getStringList('activeParkingSessions') ?? [];
    activeParkingSessions
      ..clear()
      ..addAll(
        activeParkingJson.map(
          (item) =>
              ParkingSession.fromJson(jsonDecode(item) as Map<String, dynamic>),
        ),
      );
    activeParkingSessions.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    selectedParkingSessionId = prefs.getString('selectedParkingSessionId');
    if (selectedParkingSessionId == null && activeParkingSessions.isNotEmpty) {
      selectedParkingSessionId = activeParkingSessions.first.id;
    }

    final parkingHistoryJson = prefs.getStringList('parkingHistory') ?? [];
    parkingHistory
      ..clear()
      ..addAll(
        parkingHistoryJson.map(
          (item) => ParkingHistoryEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>),
        ),
      );
    parkingHistory.sort((a, b) => b.savedAt.compareTo(a.savedAt));

    selectedCategory = prefs.getString('selectedSpiritualCategory') ??
        spiritualCategories.first;
    showBibleEnglish = prefs.getBool('showBibleEnglish') ?? false;
    trafficRadiusMiles = prefs.getInt('trafficRadiusMiles') ?? 10;

    final reminderList = prefs.getStringList('reminders') ?? [];
    reminders
      ..clear()
      ..addAll(
        reminderList.map(
          (item) =>
              ReminderItem.fromJson(jsonDecode(item) as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'activeParkingSessions',
      activeParkingSessions.map((item) => jsonEncode(item.toJson())).toList(),
    );
    if (selectedParkingSessionId != null) {
      await prefs.setString(
          'selectedParkingSessionId', selectedParkingSessionId!);
    } else {
      await prefs.remove('selectedParkingSessionId');
    }
    await prefs.setString('selectedSpiritualCategory', selectedCategory);
    await prefs.setBool('showBibleEnglish', showBibleEnglish);
    await prefs.setInt('trafficRadiusMiles', trafficRadiusMiles);
    await prefs.setStringList(
      'parkingHistory',
      parkingHistory.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'reminders',
      reminders.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  void _seedAgentReply() {
    lastAgentReply = isCantoneseMode
        ? '你可以問我：我架車喺邊、仲有幾多時間、今日天氣、附近交通，或者讀今日金句。'
        : 'Ask me where your car is, how much time is left, today’s weather, nearby traffic, or today’s verse.';
  }

  Future<void> refreshDailyVerse({bool forceRefresh = false}) async {
    isLoadingDailyVerse = true;
    dailyVerseError = null;
    notifyListeners();
    try {
      dailyVerse =
          await spiritualService.fetchDailyVerse(forceRefresh: forceRefresh);
    } catch (_) {
      dailyVerseError = isCantoneseMode
          ? '今日金句暫時未能載入。'
          : 'The daily verse could not be loaded right now.';
    } finally {
      isLoadingDailyVerse = false;
      notifyListeners();
    }
  }

  Future<void> ensureDailyVerseCurrent() async {
    if (isLoadingDailyVerse) {
      return;
    }

    final now = DateTime.now();
    if (dailyVerse == null ||
        dailyVerse!.fetchedOn.year != now.year ||
        dailyVerse!.fetchedOn.month != now.month ||
        dailyVerse!.fetchedOn.day != now.day) {
      await refreshDailyVerse();
    }
  }

  Future<void> refreshLocalConditions({int? radiusMiles}) async {
    isLoadingConditions = true;
    localConditionsError = null;
    if (radiusMiles != null) {
      trafficRadiusMiles = radiusMiles;
    }
    notifyListeners();

    try {
      final position = await locationService.getCurrentPosition();
      final weatherFuture = localConditionsService.fetchWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final regionFuture = localConditionsService.fetchRegionLabel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final trafficFuture = localConditionsService.fetchTraffic(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMiles: trafficRadiusMiles,
      );

      localWeather = await weatherFuture;
      localRegionLabel = await regionFuture;
      localTraffic = await trafficFuture;
      await _saveLocalData();
    } catch (_) {
      localConditionsError = isCantoneseMode
          ? '未能取得附近天氣或交通資料，請檢查定位與網絡。'
          : 'Unable to load nearby weather or traffic right now.';
    } finally {
      isLoadingConditions = false;
      notifyListeners();
    }
  }

  Future<void> ensureLocalConditionsCurrent() async {
    if (isLoadingConditions) {
      return;
    }
    final fetchedAt = localWeather?.fetchedAt;
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt).inMinutes >= 15) {
      await refreshLocalConditions();
    }
  }

  Future<void> saveParking({
    String? editingId,
    required String label,
    required String notes,
    required int durationMinutes,
    required int alertLeadMinutes,
    List<int>? alertLeadMinutesList,
    String? photoBase64,
  }) async {
    final normalizedAlerts = ((alertLeadMinutesList ?? [alertLeadMinutes])
        .where((item) => item > 0)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b)));
    final existing = editingId == null
        ? null
        : activeParkingSessions.cast<ParkingSession?>().firstWhere(
              (item) => item?.id == editingId,
              orElse: () => null,
            );
    final position = await locationService.getCurrentPosition();
    final session = ParkingSession(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      savedAt: existing?.savedAt ?? DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      label: label,
      notes: notes,
      durationMinutes: durationMinutes,
      alertLeadMinutes:
          normalizedAlerts.isEmpty ? alertLeadMinutes : normalizedAlerts.first,
      alertLeadMinutesList:
          normalizedAlerts.isEmpty ? [alertLeadMinutes] : normalizedAlerts,
      photoBase64: photoBase64,
    );
    activeParkingSessions.removeWhere((item) => item.id == session.id);
    activeParkingSessions.insert(0, session);
    selectedParkingSessionId = session.id;
    parkingHistory.removeWhere((item) => item.id == session.id);
    parkingHistory.insert(
      0,
      ParkingHistoryEntry(
        id: session.id,
        savedAt: session.savedAt,
        latitude: session.latitude,
        longitude: session.longitude,
        label: session.label,
        notes: session.notes,
        durationMinutes: session.durationMinutes,
        alertLeadMinutesList: session.alertLeadMinutesList,
        photoBase64: session.photoBase64,
      ),
    );
    await _saveLocalData();
    notifyListeners();

    await notificationService.scheduleParkingAlerts(
      sessionId: session.id,
      parkingExpiresAt: session.expiresAt,
      leadMinutesList: session.alertLeadMinutesList,
      label: label.trim(),
    );
    _primeForegroundParkingAlerts();

    await notificationService.showNow(
      id: 1001,
      title: isCantoneseMode ? '已儲存泊車位置' : 'Parking saved',
      body: isCantoneseMode
          ? '已記低你而家嘅泊車位置同計時。'
          : 'Your car location and timer were saved.',
    );

    lastAgentReply = isCantoneseMode
        ? '已經幫你記低泊車位置，計時器亦都開始咗。'
        : 'Your parking spot is saved and the timer has started.';
    notifyListeners();
    await ttsService.speak(lastAgentReply);
  }

  Future<void> clearParking({String? id}) async {
    final target = id == null
        ? activeParking
        : activeParkingSessions.cast<ParkingSession?>().firstWhere(
              (item) => item?.id == id,
              orElse: () => null,
            );
    if (target == null) {
      return;
    }
    await notificationService.cancelParkingAlert(sessionId: target.id);
    activeParkingSessions.removeWhere((item) => item.id == target.id);
    _firedForegroundParkingAlerts.removeWhere(
      (item) => item.startsWith('${target.id}:'),
    );
    if (selectedParkingSessionId == target.id) {
      selectedParkingSessionId =
          activeParkingSessions.isEmpty ? null : activeParkingSessions.first.id;
    }
    await _saveLocalData();
    notifyListeners();
  }

  void selectParkingSession(String id) {
    if (activeParkingSessions.any((item) => item.id == id)) {
      selectedParkingSessionId = id;
      notifyListeners();
      _saveLocalData();
    }
  }

  Map<String, List<ParkingHistoryEntry>> get parkingHistoryByMonth {
    final map = <String, List<ParkingHistoryEntry>>{};
    for (final item in parkingHistory) {
      map.putIfAbsent(item.monthKey, () => []).add(item);
    }
    return map;
  }

  Future<void> deleteParkingHistoryEntry(String id) async {
    parkingHistory.removeWhere((item) => item.id == id);
    await _saveLocalData();
    notifyListeners();
  }

  Future<void> deleteParkingHistoryPhoto(String id) async {
    final index = parkingHistory.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    final current = parkingHistory[index];
    parkingHistory[index] = ParkingHistoryEntry(
      id: current.id,
      savedAt: current.savedAt,
      latitude: current.latitude,
      longitude: current.longitude,
      label: current.label,
      notes: current.notes,
      durationMinutes: current.durationMinutes,
      alertLeadMinutesList: current.alertLeadMinutesList,
      photoBase64: null,
    );

    final activeIndex =
        activeParkingSessions.indexWhere((item) => item.id == id);
    if (activeIndex != -1) {
      activeParkingSessions[activeIndex] =
          activeParkingSessions[activeIndex].copyWith(
        photoBase64: null,
      );
    }

    await _saveLocalData();
    notifyListeners();
  }

  Future<void> addReminder(String title, DateTime when) async {
    reminders.add(
      ReminderItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        when: when,
        isDaily: false,
      ),
    );
    reminders.sort((a, b) => a.when.compareTo(b.when));
    await _saveLocalData();
    notifyListeners();
    await notificationService.showNow(
      id: Random().nextInt(999999),
      title: isCantoneseMode ? '已加入提醒' : 'Reminder added',
      body: title,
    );
  }

  Future<void> refreshNews() async {
    newsItems
      ..clear()
      ..addAll(await newsService.fetchHeadlines());
    notifyListeners();
  }

  Future<void> speakNewsBriefing() async {
    if (newsItems.isEmpty) {
      await refreshNews();
    }
    await ttsService.configure(cantonese: isCantoneseMode);
    final script = newsService.buildSpokenBriefing(
      newsItems,
      cantonese: isCantoneseMode,
    );
    await ttsService.speak(script);
  }

  Future<void> setLanguage({
    required String code,
    required bool cantoneseVoice,
  }) async {
    await settingsService.setLanguageCode(code);
    await settingsService.setSpeakInCantonese(cantoneseVoice);
    await ttsService.configure(cantonese: cantoneseVoice);
    showBibleEnglish = !cantoneseVoice;
    await _saveLocalData();
    _seedAgentReply();
    notifyListeners();
  }

  void _startParkingAlertTicker() {
    _parkingAlertTicker?.cancel();
    _parkingAlertTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _handleForegroundParkingAlerts(),
    );
  }

  void _primeForegroundParkingAlerts() {
    _firedForegroundParkingAlerts.clear();
    final now = DateTime.now();
    for (final session in activeParkingSessions) {
      for (final leadMinutes in session.alertLeadMinutesList) {
        final scheduledAt = session.expiresAt.subtract(
          Duration(minutes: leadMinutes),
        );
        if (!scheduledAt.isAfter(now)) {
          _firedForegroundParkingAlerts.add(
            _parkingAlertKey(session.id, 'lead-$leadMinutes'),
          );
        }
      }
      if (!session.expiresAt.isAfter(now)) {
        _firedForegroundParkingAlerts.add(_parkingAlertKey(session.id, 'due'));
      }
    }
  }

  Future<void> _handleForegroundParkingAlerts() async {
    if (_isHandlingForegroundParkingAlerts || activeParkingSessions.isEmpty) {
      return;
    }
    _isHandlingForegroundParkingAlerts = true;
    try {
      final now = DateTime.now();
      for (final session in activeParkingSessions) {
        for (final leadMinutes in session.alertLeadMinutesList) {
          final key = _parkingAlertKey(session.id, 'lead-$leadMinutes');
          final scheduledAt = session.expiresAt.subtract(
            Duration(minutes: leadMinutes),
          );
          if (_firedForegroundParkingAlerts.contains(key) ||
              scheduledAt.isAfter(now)) {
            continue;
          }
          _firedForegroundParkingAlerts.add(key);
          final body = isCantoneseMode
              ? '你仲有 $leadMinutes 分鐘就到鐘。'
              : 'You have $leadMinutes minutes left before parking expires.';
          await notificationService.showNow(
            id: 500000 + Random().nextInt(99999),
            title: isCantoneseMode ? '泊車提醒' : 'Parking Reminder',
            body: body,
          );
          await _runForegroundAlarm(body);
        }

        final dueKey = _parkingAlertKey(session.id, 'due');
        if (_firedForegroundParkingAlerts.contains(dueKey) ||
            session.expiresAt.isAfter(now)) {
          continue;
        }
        _firedForegroundParkingAlerts.add(dueKey);
        final body = isCantoneseMode
            ? '你嘅泊車時間已到，請盡快返去架車。'
            : 'Your parking time is due now. Please return to your car.';
        await notificationService.showNow(
          id: 600000 + Random().nextInt(99999),
          title: isCantoneseMode ? '泊車時間已到' : 'Parking Time Due',
          body: body,
        );
        await _runForegroundAlarm(body);
      }
    } finally {
      _isHandlingForegroundParkingAlerts = false;
    }
  }

  Future<void> _runForegroundAlarm(String spokenText) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: [0, 700, 250, 900, 250, 900],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      } else {
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }

    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    try {
      await ttsService.speak(spokenText);
    } catch (_) {}
  }

  String _parkingAlertKey(String sessionId, String suffix) =>
      '$sessionId:$suffix';

  Future<void> updateDefaultParkingMinutes(int value) async {
    await settingsService.setDefaultParkingMinutes(value);
    notifyListeners();
  }

  Future<void> setSelectedCategory(String category) async {
    selectedCategory = category;
    final verseCount = spiritualService.getCategoryVerses(category).length;
    currentCategoryVerseIndex =
        verseCount <= 1 ? 0 : Random().nextInt(verseCount);
    await _saveLocalData();
    notifyListeners();
  }

  Future<void> pickAnotherFeaturedVerse() async {
    final verses = selectedCategoryVerses;
    if (verses.isEmpty) {
      return;
    }
    if (verses.length == 1) {
      currentCategoryVerseIndex = 0;
    } else {
      final previousIndex = currentCategoryVerseIndex % verses.length;
      var nextIndex = previousIndex;
      while (nextIndex == previousIndex) {
        nextIndex = Random().nextInt(verses.length);
      }
      currentCategoryVerseIndex = nextIndex;
    }
    await _saveLocalData();
    notifyListeners();
  }

  Future<void> setBibleLanguageMode({required bool english}) async {
    showBibleEnglish = english;
    await _saveLocalData();
    notifyListeners();
  }

  String buildCuratedVerseScript(VerseEntry verse) {
    if (!showBibleEnglish) {
      return '${verse.reference}。${verse.textZhHant}。${verse.shortCantoneseReflection}';
    }
    return '${verse.reference}. ${verse.textEn}.';
  }

  String buildDailyVerseScript(DailyVerse verse) {
    if (!showBibleEnglish) {
      final chinese =
          verse.textZhHant.isEmpty ? '今日中文經文暫未載入。' : verse.textZhHant;
      return '今日金句，${verse.reference}。$chinese';
    }
    return 'Verse of the day, ${verse.reference}. ${verse.textEn}';
  }

  String buildWeatherSummary({bool? cantonese}) {
    final useCantonese = cantonese ?? isCantoneseMode;
    final weather = localWeather;
    if (weather == null) {
      return useCantonese ? '未有即時天氣資料。' : 'No live weather data yet.';
    }

    final condition =
        weatherCodeLabel(weather.weatherCode, cantonese: useCantonese);
    final regionPrefix = localRegionLabel.trim().isNotEmpty
        ? (useCantonese
            ? '地區：$localRegionLabel。'
            : 'Region: $localRegionLabel. ')
        : '';
    final rainHint = weather.precipitationMm > 0
        ? (useCantonese
            ? '而家有降雨或降雪跡象。'
            : 'Precipitation is being reported now.')
        : (useCantonese ? '暫時未見明顯降雨。' : 'No major precipitation right now.');

    if (useCantonese) {
      return '$regionPrefix附近而家 $condition，氣溫 ${weather.temperatureC.toStringAsFixed(1)}°C，體感 ${weather.apparentTemperatureC.toStringAsFixed(1)}°C，風速 ${weather.windSpeedKph.toStringAsFixed(0)} km/h。$rainHint';
    }

    return '${regionPrefix}Nearby conditions are $condition, ${weather.temperatureC.toStringAsFixed(1)}°C with a feels-like of ${weather.apparentTemperatureC.toStringAsFixed(1)}°C and wind at ${weather.windSpeedKph.toStringAsFixed(0)} km/h. $rainHint';
  }

  List<DailyWeatherForecast> get selectedWeatherForecasts {
    final weather = localWeather;
    if (weather == null || weather.forecasts.isEmpty) {
      return const [];
    }
    final limit = weatherRangeDays >= 20 ? 16 : weatherRangeDays;
    return weather.forecasts.take(limit).toList();
  }

  Future<void> setWeatherRangeDays(int value) async {
    weatherRangeDays = value;
    notifyListeners();
  }

  String buildTrafficSummary({bool? cantonese}) {
    final useCantonese = cantonese ?? isCantoneseMode;
    final traffic = localTraffic;
    if (traffic == null) {
      return useCantonese ? '未有附近交通資料。' : 'No nearby traffic data yet.';
    }
    if (!traffic.isAvailable) {
      return useCantonese
          ? '附近交通 API 未啟用；加入 TomTom API key 後可顯示 ${traffic.radiusMiles} 英里內交通。'
          : 'Traffic API is not enabled yet. Add a TomTom API key to show incidents within ${traffic.radiusMiles} miles.';
    }
    if (traffic.incidents.isEmpty) {
      return useCantonese
          ? '${traffic.radiusMiles} 英里內暫時未見明顯交通事故或擠塞。'
          : 'No major incidents were found within ${traffic.radiusMiles} miles.';
    }

    if (useCantonese) {
      final topIncidents = traffic.incidents.take(3).map((incident) {
        final delay =
            incident.delayMinutes > 0 ? '，延誤約 ${incident.delayMinutes} 分鐘' : '';
        return '${translateTrafficCategory(incident.category)}：${incident.title}$delay';
      }).join('；');
      return '${traffic.radiusMiles} 英里內有 ${traffic.incidents.length} 宗交通事件；較主要位置包括 $topIncidents。';
    }

    final topIncidents = traffic.incidents.take(3).map((incident) {
      final delay = incident.delayMinutes > 0
          ? ', about ${incident.delayMinutes} minutes delay'
          : '';
      return '${incident.category}: ${incident.title}$delay';
    }).join('; ');
    return '${traffic.incidents.length} incidents found within ${traffic.radiusMiles} miles. Key nearby locations include $topIncidents.';
  }

  String weatherCodeLabel(int code, {required bool cantonese}) {
    if (cantonese) {
      return switch (code) {
        0 => '天晴',
        1 || 2 => '局部多雲',
        3 => '密雲',
        45 || 48 => '有霧',
        51 || 53 || 55 => '毛毛雨',
        56 || 57 => '凍雨',
        61 || 63 || 65 => '落雨',
        66 || 67 => '凍雨較強',
        71 || 73 || 75 || 77 => '落雪',
        80 || 81 || 82 => '驟雨',
        85 || 86 => '陣雪',
        95 => '雷暴',
        96 || 99 => '冰雹雷暴',
        _ => '天氣變化中',
      };
    }

    return switch (code) {
      0 => 'clear',
      1 || 2 => 'partly cloudy',
      3 => 'overcast',
      45 || 48 => 'foggy',
      51 || 53 || 55 => 'drizzle',
      56 || 57 => 'freezing drizzle',
      61 || 63 || 65 => 'rainy',
      66 || 67 => 'freezing rain',
      71 || 73 || 75 || 77 => 'snowy',
      80 || 81 || 82 => 'showers',
      85 || 86 => 'snow showers',
      95 => 'thunderstorm',
      96 || 99 => 'thunderstorm with hail',
      _ => 'changing weather',
    };
  }

  String translateTrafficCategory(String category) {
    return switch (category) {
      'Jam' => '擠塞',
      'Road closed' => '封路',
      'Road works' => '道路工程',
      'Lane closed' => '封閉行車線',
      'Incident' => '交通事故',
      'Broken down vehicle' => '壞車',
      'Accident' => '撞車',
      'Weather' => '天氣影響',
      _ => '交通情況',
    };
  }

  Color trafficSeverityColor(TrafficIncident incident) {
    if (incident.delayMinutes >= 10) {
      return const Color(0xFFE74C3C);
    }
    if (incident.delayMinutes >= 4) {
      return const Color(0xFFE67E22);
    }
    return const Color(0xFF2ECC71);
  }

  Future<void> speakFeaturedVerse({String? category}) async {
    if (category != null && category != selectedCategory) {
      selectedCategory = category;
      await _saveLocalData();
      notifyListeners();
    }
    final verse = featuredVerse;
    if (verse == null) {
      return;
    }
    await ttsService.configure(cantonese: !showBibleEnglish);
    lastAgentReply = !showBibleEnglish
        ? '${verse.reference}，${verse.shortCantoneseReflection}'
        : '${verse.reference}, ${verse.textEn}';
    notifyListeners();
    await ttsService.speak(buildCuratedVerseScript(verse));
  }

  Future<void> speakCuratedVerse(VerseEntry verse) async {
    await ttsService.configure(cantonese: !showBibleEnglish);
    lastAgentReply = !showBibleEnglish
        ? '${verse.reference}，${verse.shortCantoneseReflection}'
        : '${verse.reference}, ${verse.textEn}';
    notifyListeners();
    await ttsService.speak(buildCuratedVerseScript(verse));
  }

  Future<void> speakDailyVerse() async {
    if (dailyVerse == null) {
      await refreshDailyVerse();
    }
    if (dailyVerse == null) {
      return;
    }
    await ttsService.configure(cantonese: !showBibleEnglish);
    lastAgentReply = !showBibleEnglish
        ? '今日金句係 ${dailyVerse!.reference}'
        : 'Today’s verse is ${dailyVerse!.reference}';
    notifyListeners();
    await ttsService.speak(buildDailyVerseScript(dailyVerse!));
  }

  Future<void> speakWeatherSummary() async {
    await ensureLocalConditionsCurrent();
    final summary = buildWeatherSummary(cantonese: isCantoneseMode);
    lastAgentReply = summary;
    notifyListeners();
    await ttsService.configure(cantonese: isCantoneseMode);
    await ttsService.speak(summary);
  }

  Future<void> speakTrafficSummary({int? radiusMiles}) async {
    await refreshLocalConditions(
        radiusMiles: radiusMiles ?? trafficRadiusMiles);
    final summary = buildTrafficSummary(cantonese: isCantoneseMode);
    lastAgentReply = summary;
    notifyListeners();
    await ttsService.configure(cantonese: isCantoneseMode);
    await ttsService.speak(summary);
  }

  Future<String> handleVoiceCommand(String text) async {
    lastAgentHeard = text;
    final lower = text.toLowerCase();

    if (_containsAny(
        lower, text, ['我架車喺邊', 'where is my car', 'find my car'])) {
      if (activeParking == null) {
        lastAgentReply = isCantoneseMode
            ? '你而家未有已保存嘅泊車位置。'
            : 'You do not have a saved parking spot yet.';
      } else {
        lastAgentReply = isCantoneseMode
            ? '你架車停咗喺 ${activeParking!.label.isEmpty ? '已保存位置' : activeParking!.label}，座標係 ${activeParking!.latitude.toStringAsFixed(5)}, ${activeParking!.longitude.toStringAsFixed(5)}。'
            : 'Your car is saved at ${activeParking!.label.isEmpty ? 'your stored parking spot' : activeParking!.label}.';
      }
      await ttsService.speak(lastAgentReply);
      notifyListeners();
      return lastAgentReply;
    }

    if (_containsAny(
        lower, text, ['仲有幾多時間', 'how much time left', 'time left'])) {
      lastAgentReply = activeParking == null
          ? (isCantoneseMode
              ? '而家未有進行中的泊車計時。'
              : 'There is no active parking timer right now.')
          : parkingStatusLabel;
      await ttsService.speak(lastAgentReply);
      notifyListeners();
      return lastAgentReply;
    }

    if (_containsAny(lower, text, [
      '今日天氣',
      '附近天氣',
      'weather today',
      'today weather',
      'weather around',
      'rainy',
      'snowy',
      'stormy'
    ])) {
      await speakWeatherSummary();
      return lastAgentReply;
    }

    if (_containsAny(lower, text, [
      '附近交通',
      '交通情況',
      'traffic around',
      'nearby traffic',
      'traffic report'
    ])) {
      await speakTrafficSummary(radiusMiles: _resolveRadiusFromText(lower));
      return lastAgentReply;
    }

    if (_containsAny(lower, text,
        ['今日金句', 'verse of the day', 'daily quote', 'daily verse'])) {
      await speakDailyVerse();
      return lastAgentReply;
    }

    if (_containsAny(lower, text, ['提醒我', 'remind me', 'add reminder'])) {
      final reminderTime = DateTime.now().add(const Duration(hours: 1));
      await addReminder(
        isCantoneseMode ? '一小時後提醒' : '1-hour reminder',
        reminderTime,
      );
      lastAgentReply = isCantoneseMode
          ? '已經加咗一個一小時後嘅提醒。'
          : 'I added a reminder for one hour from now.';
      await ttsService.speak(lastAgentReply);
      notifyListeners();
      return lastAgentReply;
    }

    final category = _resolveCategoryFromText(lower, text);
    if (category != null) {
      await speakFeaturedVerse(category: category);
      return lastAgentReply;
    }

    if (_containsAny(lower, text, ['verse', 'bible', '經文'])) {
      await speakFeaturedVerse();
      return lastAgentReply;
    }

    if (_containsAny(lower, text, ['英文', 'english'])) {
      await setLanguage(code: 'en', cantoneseVoice: false);
      lastAgentReply = 'I switched to English voice.';
      await ttsService.speak(lastAgentReply);
      notifyListeners();
      return lastAgentReply;
    }

    if (_containsAny(lower, text, ['廣東話', 'cantonese', '粵語'])) {
      await setLanguage(code: 'zh', cantoneseVoice: true);
      lastAgentReply = '我已經轉返做廣東話語音。';
      await ttsService.speak(lastAgentReply);
      notifyListeners();
      return lastAgentReply;
    }

    lastAgentReply = isCantoneseMode
        ? '你可以問我泊車位置、剩餘時間、今日天氣、附近交通、今日金句，或者叫我讀平安、焦慮、箴言同詩篇經文。'
        : 'Ask me about your parking spot, remaining time, today’s weather, nearby traffic, the daily verse, or a category like peace, anxiety, Proverbs, or Psalms.';
    await ttsService.speak(lastAgentReply);
    notifyListeners();
    return lastAgentReply;
  }

  bool _containsAny(String lower, String original, List<String> patterns) {
    return patterns.any(
      (pattern) =>
          lower.contains(pattern.toLowerCase()) || original.contains(pattern),
    );
  }

  String? _resolveCategoryFromText(String lower, String original) {
    final entries = <String, List<String>>{
      'peace': ['平安', 'peace'],
      'anxiety': ['焦慮', 'anxiety', 'worry'],
      'wisdom': ['智慧', 'wisdom'],
      'encouragement': ['鼓勵', 'encouragement'],
      'faith': ['信心', 'faith'],
      'hope': ['盼望', 'hope'],
      'walk_with_god': ['與主同行', 'walk with god'],
      'proverbs': ['箴言', 'proverbs'],
      'psalms': ['詩篇', 'psalms', 'psalm'],
    };

    for (final entry in entries.entries) {
      if (entry.value.any(
        (item) => lower.contains(item.toLowerCase()) || original.contains(item),
      )) {
        return entry.key;
      }
    }
    return null;
  }

  int _resolveRadiusFromText(String lower) {
    if (lower.contains('20')) {
      return 20;
    }
    if (lower.contains('5')) {
      return 5;
    }
    return 10;
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours <= 0) {
      return '${minutes}m';
    }
    return '${hours}h ${minutes}m';
  }

  @override
  void dispose() {
    _parkingAlertTicker?.cancel();
    ttsService.stop();
    super.dispose();
  }
}
