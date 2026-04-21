class ParkingSession {
  ParkingSession({
    required this.id,
    required this.savedAt,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.notes,
    required this.durationMinutes,
    required this.alertLeadMinutes,
    List<int>? alertLeadMinutesList,
    this.photoBase64,
  }) : alertLeadMinutesList = (alertLeadMinutesList == null || alertLeadMinutesList.isEmpty)
           ? [alertLeadMinutes]
           : alertLeadMinutesList.toSet().toList()..sort((a, b) => a.compareTo(b));

  final String id;
  final DateTime savedAt;
  final double latitude;
  final double longitude;
  final String label;
  final String notes;
  final int durationMinutes;
  final int alertLeadMinutes;
  final List<int> alertLeadMinutesList;
  final String? photoBase64;

  DateTime get expiresAt => savedAt.add(Duration(minutes: durationMinutes));

  ParkingSession copyWith({
    String? id,
    DateTime? savedAt,
    double? latitude,
    double? longitude,
    String? label,
    String? notes,
    int? durationMinutes,
    int? alertLeadMinutes,
    List<int>? alertLeadMinutesList,
    String? photoBase64,
  }) {
    return ParkingSession(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      alertLeadMinutes: alertLeadMinutes ?? this.alertLeadMinutes,
      alertLeadMinutesList: alertLeadMinutesList ?? this.alertLeadMinutesList,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
        'notes': notes,
        'durationMinutes': durationMinutes,
        'alertLeadMinutes': alertLeadMinutes,
        'alertLeadMinutesList': alertLeadMinutesList,
        'photoBase64': photoBase64,
      };

  factory ParkingSession.fromJson(Map<String, dynamic> json) => ParkingSession(
        id: json['id'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        label: json['label'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        durationMinutes: json['durationMinutes'] as int? ?? 120,
        alertLeadMinutes: json['alertLeadMinutes'] as int? ?? 10,
        alertLeadMinutesList:
            (json['alertLeadMinutesList'] as List<dynamic>?)
                ?.map((item) => item as int)
                .toList(),
        photoBase64: json['photoBase64'] as String?,
      );
}

class ParkingHistoryEntry {
  ParkingHistoryEntry({
    required this.id,
    required this.savedAt,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.notes,
    required this.durationMinutes,
    required this.alertLeadMinutesList,
    this.photoBase64,
  });

  final String id;
  final DateTime savedAt;
  final double latitude;
  final double longitude;
  final String label;
  final String notes;
  final int durationMinutes;
  final List<int> alertLeadMinutesList;
  final String? photoBase64;

  String get monthKey =>
      '${savedAt.year.toString().padLeft(4, '0')}-${savedAt.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
        'notes': notes,
        'durationMinutes': durationMinutes,
        'alertLeadMinutesList': alertLeadMinutesList,
        'photoBase64': photoBase64,
      };

  ParkingHistoryEntry copyWith({
    String? id,
    DateTime? savedAt,
    double? latitude,
    double? longitude,
    String? label,
    String? notes,
    int? durationMinutes,
    List<int>? alertLeadMinutesList,
    String? photoBase64,
  }) {
    return ParkingHistoryEntry(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      alertLeadMinutesList: alertLeadMinutesList ?? this.alertLeadMinutesList,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  factory ParkingHistoryEntry.fromJson(Map<String, dynamic> json) => ParkingHistoryEntry(
        id: json['id'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        label: json['label'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        durationMinutes: json['durationMinutes'] as int? ?? 120,
        alertLeadMinutesList: (json['alertLeadMinutesList'] as List<dynamic>? ?? const [])
            .map((item) => item as int)
            .toList(),
        photoBase64: json['photoBase64'] as String?,
      );
}

class ReminderItem {
  ReminderItem({
    required this.id,
    required this.title,
    required this.when,
    required this.isDaily,
  });

  final String id;
  final String title;
  final DateTime when;
  final bool isDaily;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'when': when.toIso8601String(),
        'isDaily': isDaily,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'] as String,
        title: json['title'] as String,
        when: DateTime.parse(json['when'] as String),
        isDaily: json['isDaily'] as bool? ?? false,
      );
}

class NewsItem {
  NewsItem({
    required this.title,
    required this.source,
    required this.category,
    required this.link,
    required this.publishedAt,
    required this.summary,
  });

  final String title;
  final String source;
  final String category;
  final String link;
  final DateTime publishedAt;
  final String summary;
}

class VerseEntry {
  const VerseEntry({
    required this.id,
    required this.reference,
    required this.category,
    required this.textZhHant,
    required this.textEn,
    required this.isFamous,
    required this.priorityScore,
    required this.moodTags,
    required this.shortCantoneseReflection,
  });

  final String id;
  final String reference;
  final String category;
  final String textZhHant;
  final String textEn;
  final bool isFamous;
  final int priorityScore;
  final List<String> moodTags;
  final String shortCantoneseReflection;

  factory VerseEntry.fromJson(Map<String, dynamic> json) => VerseEntry(
        id: json['id'] as String,
        reference: json['reference'] as String,
        category: json['category'] as String,
        textZhHant: json['textZhHant'] as String,
        textEn: json['textEn'] as String,
        isFamous: json['isFamous'] as bool? ?? true,
        priorityScore: json['priorityScore'] as int? ?? 0,
        moodTags: (json['moodTags'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        shortCantoneseReflection: json['shortCantoneseReflection'] as String? ?? '',
      );
}

class DailyVerse {
  const DailyVerse({
    required this.reference,
    required this.textZhHant,
    required this.textEn,
    required this.version,
    required this.sourceName,
    required this.fetchedOn,
  });

  final String reference;
  final String textZhHant;
  final String textEn;
  final String version;
  final String sourceName;
  final DateTime fetchedOn;

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'textZhHant': textZhHant,
        'textEn': textEn,
        'version': version,
        'sourceName': sourceName,
        'fetchedOn': fetchedOn.toIso8601String(),
      };

  factory DailyVerse.fromJson(Map<String, dynamic> json) => DailyVerse(
        reference: json['reference'] as String,
        textZhHant: json['textZhHant'] as String? ?? '',
        textEn: json['textEn'] as String? ?? '',
        version: json['version'] as String? ?? '',
        sourceName: json['sourceName'] as String? ?? '',
        fetchedOn: DateTime.parse(json['fetchedOn'] as String),
      );
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.relativeHumidity,
    required this.windSpeedKph,
    required this.precipitationMm,
    required this.weatherCode,
    required this.isDay,
    required this.temperatureMinC,
    required this.temperatureMaxC,
    required this.regionLabel,
    required this.forecasts,
    required this.fetchedAt,
  });

  final double temperatureC;
  final double apparentTemperatureC;
  final double relativeHumidity;
  final double windSpeedKph;
  final double precipitationMm;
  final int weatherCode;
  final bool isDay;
  final double temperatureMinC;
  final double temperatureMaxC;
  final String regionLabel;
  final List<DailyWeatherForecast> forecasts;
  final DateTime fetchedAt;
}

class DailyWeatherForecast {
  const DailyWeatherForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMaxC,
    required this.tempMinC,
    required this.precipitationProbability,
  });

  final DateTime date;
  final int weatherCode;
  final double tempMaxC;
  final double tempMinC;
  final int precipitationProbability;
}

class TrafficIncident {
  const TrafficIncident({
    required this.title,
    required this.category,
    required this.delayMinutes,
  });

  final String title;
  final String category;
  final int delayMinutes;
}

class TrafficSnapshot {
  const TrafficSnapshot({
    required this.radiusMiles,
    required this.incidents,
    required this.fetchedAt,
    required this.isAvailable,
    this.errorMessage,
  });

  final int radiusMiles;
  final List<TrafficIncident> incidents;
  final DateTime fetchedAt;
  final bool isAvailable;
  final String? errorMessage;
}
