import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class SpiritualService {
  static const _dailyVerseCacheKey = 'dailyVerseCacheV3';
  static const _dailyVerseCacheDateKey = 'dailyVerseCacheDateV3';
  static const String _backendApiBaseUrl = String.fromEnvironment(
    'TRAFFIC_API_BASE_URL',
    defaultValue: 'http://localhost:3002',
  );

  static const Map<String, String> _dailyVerseZhFallbacks = {
    'Isaiah 40:28': '你豈不曾知道嗎？你豈不曾聽見嗎？永在的神耶和華，創造地極的主，並不疲乏，也不困倦；他的智慧無法測度。',
    'Philippians 4:6-7': '應當一無掛慮，只要凡事藉著禱告、祈求，和感謝，將你們所要的告訴神。神所賜出人意外的平安，必在基督耶穌裡保守你們的心懷意念。',
    'John 14:27': '我留下平安給你們；我將我的平安賜給你們。我所賜的，不像世人所賜的。你們心裡不要憂愁，也不要膽怯。',
    'Psalm 23:1': '耶和華是我的牧者，我必不致缺乏。',
    'Psalm 121:1-2': '我要向山舉目；我的幫助從何而來？我的幫助從造天地的耶和華而來。',
    'Proverbs 3:5-6': '你要專心仰賴耶和華，不可倚靠自己的聰明，在你一切所行的事上都要認定他，他必指引你的路。',
    'Matthew 11:28': '凡勞苦擔重擔的人可以到我這裡來，我就使你們得安息。',
    'Isaiah 41:10': '你不要害怕，因為我與你同在；不要驚惶，因為我是你的神。我必堅固你，我必幫助你；我必用我公義的右手扶持你。',
    'Romans 15:13': '但願使人有盼望的神，因信將諸般的喜樂平安充滿你們的心，使你們藉著聖靈的能力大有盼望。',
    'Joshua 1:9': '我豈沒有吩咐你嗎？你當剛強壯膽，不要懼怕，也不要驚惶；因為你無論往哪裡去，耶和華你的神必與你同在。',
    'Psalm 46:10': '你們要休息，要知道我是神；我必在外邦中被尊崇，在遍地上也被尊崇。',
    'Romans 8:28': '我們曉得萬事都互相效力，叫愛神的人得益處，就是按他旨意被召的人。',
    '2 Timothy 1:7': '因為神賜給我們，不是膽怯的心，乃是剛強、仁愛、謹守的心。',
    'Hebrews 11:1': '信就是所望之事的實底，是未見之事的確據。',
    'Psalm 37:5': '當將你的事交託耶和華，並倚靠他，他就必成全。',
    '1 Peter 5:7': '你們要將一切的憂慮卸給神，因為他顧念你們。',
    'Psalm 16:8': '我將耶和華常擺在我面前，因他在我右邊，我便不致搖動。',
    'Psalm 55:22': '你要把你的重擔卸給耶和華，他必撫養你；他永不叫義人動搖。',
    'Lamentations 3:22-23': '我們不致消滅，是出於耶和華諸般的慈愛；是因他的憐憫不致斷絕。每早晨這都是新的；你的誠實極其廣大。',
    'Romans 12:12': '在指望中要喜樂，在患難中要忍耐，禱告要恆切。',
  };

  Map<String, VerseEntry> _verseById = const {};
  Map<String, List<String>> _categoryMap = const {};
  Map<String, VerseEntry> _verseByReference = const {};

  Future<void> init() async {
    if (_verseById.isNotEmpty && _categoryMap.isNotEmpty) {
      return;
    }

    final raw = await rootBundle.loadString('assets/data/curated_verses.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final verses = (decoded['verses'] as List<dynamic>)
        .map((item) => VerseEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    _verseById = {for (final verse in verses) verse.id: verse};
    _verseByReference = {
      for (final verse in verses) _normalizeReference(verse.reference): verse,
    };

    final categoryMap = decoded['categoryMap'] as Map<String, dynamic>;
    _categoryMap = {
      for (final entry in categoryMap.entries)
        entry.key: (entry.value as List<dynamic>).map((item) => item.toString()).toList(),
    };
  }

  List<VerseEntry> getCategoryVerses(String category) {
    final ids = _categoryMap[category] ?? const [];
    return ids.map((id) => _verseById[id]).whereType<VerseEntry>().toList();
  }

  VerseEntry? getPrimaryVerse(String category) {
    final verses = getCategoryVerses(category);
    if (verses.isEmpty) {
      return _verseById.values.isEmpty ? null : _verseById.values.first;
    }
    return verses.first;
  }

  Future<DailyVerse> fetchDailyVerse({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _cacheDateKey(DateTime.now());
    final cachedDate = prefs.getString(_dailyVerseCacheDateKey);
    final cachedValue = prefs.getString(_dailyVerseCacheKey);

    if (!forceRefresh &&
        cachedDate == todayKey &&
        cachedValue != null &&
        cachedValue.isNotEmpty) {
      final cachedVerse = DailyVerse.fromJson(jsonDecode(cachedValue) as Map<String, dynamic>);
      if (cachedVerse.textZhHant.isNotEmpty) {
        return cachedVerse;
      }
    }

    final response = await http.get(
      Uri.parse('https://beta.ourmanna.com/api/v1/get?format=json&order=daily'),
      headers: const {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load daily verse.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final verse = decoded['verse'] as Map<String, dynamic>? ?? const {};
    final details = verse['details'] as Map<String, dynamic>? ?? const {};
    final reference = (details['reference'] as String? ?? '').trim();
    final englishText = (details['text'] as String? ?? '').trim();
    final version = (details['version'] as String? ?? 'VOTD').trim();

    final chineseText = reference.isEmpty
        ? ''
        : await _fetchChineseDailyText(
            reference: reference,
            englishText: englishText,
          );

    final dailyVerse = DailyVerse(
      reference: reference,
      textZhHant: chineseText,
      textEn: englishText,
      version: version,
      sourceName: 'OurManna Verse of the Day',
      fetchedOn: DateTime.now(),
    );

    await prefs.setString(_dailyVerseCacheDateKey, todayKey);
    await prefs.setString(_dailyVerseCacheKey, jsonEncode(dailyVerse.toJson()));

    return dailyVerse;
  }

  Future<String> fetchVerseLookup({
    required String reference,
    String translation = 'web',
  }) {
    return _fetchBibleApiText(reference: reference, translation: translation);
  }

  Future<String> fetchRandomVerseText({String translation = 'web'}) async {
    final response = await http.get(
      Uri.parse('https://bible-api.com/data/$translation/random'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load random verse.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final verse = decoded['random_verse'] as Map<String, dynamic>? ?? decoded;
    final text = verse['text'] as String? ?? '';
    return text.replaceAll('\n', ' ').trim();
  }

  Future<String> _fetchChineseDailyText({
    required String reference,
    required String englishText,
  }) async {
    final attempts = [
      () => _fetchBackendChineseLookup(reference: reference),
      () => _fetchBibleApiText(reference: reference, translation: 'cuv'),
      () async => _lookupLocalChineseFallback(reference: reference, englishText: englishText),
    ];

    for (final attempt in attempts) {
      final result = (await attempt()).trim();
      if (result.isNotEmpty) {
        return result;
      }
    }

    return '今日金句中文版本已切換到備用模式，請按重新載入或先收聽英文版本。';
  }

  Future<String> _fetchBackendChineseLookup({required String reference}) async {
    final baseUri = Uri.parse(_backendApiBaseUrl);
    final uri = baseUri.replace(
      path: _joinPath(baseUri.path, '/api/scripture/lookup'),
      queryParameters: {'reference': reference},
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return '';
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['textZhHant'] as String? ?? '').replaceAll('\n', ' ').trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _fetchBibleApiText({
    required String reference,
    required String translation,
  }) async {
    final uri = Uri.https('bible-api.com', '/$reference', {'translation': translation});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return '';
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = decoded['text'] as String? ?? '';
    return text.replaceAll('\n', ' ').trim();
  }

  Future<String> _lookupLocalChineseFallback({
    required String reference,
    required String englishText,
  }) async {
    await init();
    final normalizedReference = _normalizeReference(reference);
    final curated = _verseByReference[normalizedReference];
    if (curated != null && curated.textZhHant.trim().isNotEmpty) {
      return curated.textZhHant.trim();
    }

    return _dailyVerseZhFallbacks[normalizedReference] ?? '';
  }

  String _normalizeReference(String reference) {
    return reference.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _joinPath(String basePath, String nextPath) {
    if (basePath.isEmpty || basePath == '/') {
      return nextPath;
    }
    final normalizedBase =
        basePath.endsWith('/') ? basePath.substring(0, basePath.length - 1) : basePath;
    final normalizedNext = nextPath.startsWith('/') ? nextPath : '/$nextPath';
    return '$normalizedBase$normalizedNext';
  }

  String _cacheDateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
