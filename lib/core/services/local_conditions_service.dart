import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class LocalConditionsService {
  static const String _trafficApiBaseUrl = String.fromEnvironment(
    'TRAFFIC_API_BASE_URL',
    defaultValue: 'http://localhost:3002',
  );

  Future<WeatherSnapshot> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final regionFuture = fetchRegionLabel(
      latitude: latitude,
      longitude: longitude,
    );

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,is_day,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '16',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather API returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>? ?? const {};
    final daily = json['daily'] as Map<String, dynamic>? ?? const {};

    final times = (daily['time'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    final codes = (daily['weather_code'] as List<dynamic>? ?? const []).map(_asInt).toList();
    final maxTemps =
        (daily['temperature_2m_max'] as List<dynamic>? ?? const []).map(_asDouble).toList();
    final minTemps =
        (daily['temperature_2m_min'] as List<dynamic>? ?? const []).map(_asDouble).toList();
    final precipitationProbabilities =
        (daily['precipitation_probability_max'] as List<dynamic>? ?? const []).map(_asInt).toList();

    final forecasts = <DailyWeatherForecast>[];
    for (var i = 0; i < times.length; i++) {
      forecasts.add(
        DailyWeatherForecast(
          date: DateTime.tryParse(times[i]) ?? DateTime.now().add(Duration(days: i)),
          weatherCode: i < codes.length ? codes[i] : 0,
          tempMaxC: i < maxTemps.length ? maxTemps[i] : 0,
          tempMinC: i < minTemps.length ? minTemps[i] : 0,
          precipitationProbability:
              i < precipitationProbabilities.length ? precipitationProbabilities[i] : 0,
        ),
      );
    }

    final regionLabel = await regionFuture;

    return WeatherSnapshot(
      temperatureC: _asDouble(current['temperature_2m']),
      apparentTemperatureC: _asDouble(current['apparent_temperature']),
      relativeHumidity: _asDouble(current['relative_humidity_2m']),
      windSpeedKph: _asDouble(current['wind_speed_10m']),
      precipitationMm: _asDouble(current['precipitation']),
      weatherCode: _asInt(current['weather_code']),
      isDay: _asInt(current['is_day']) == 1,
      temperatureMinC: forecasts.isNotEmpty ? forecasts.first.tempMinC : 0,
      temperatureMaxC: forecasts.isNotEmpty ? forecasts.first.tempMaxC : 0,
      regionLabel: regionLabel,
      forecasts: forecasts,
      fetchedAt: DateTime.tryParse(current['time']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<String> fetchRegionLabel({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'zoom': '10',
      'addressdetails': '1',
    });

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'TorontoAiParkingAgent/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return '';
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final address = decoded['address'] as Map<String, dynamic>? ?? const {};
      final city = (address['city'] ??
              address['town'] ??
              address['borough'] ??
              address['municipality'] ??
              address['suburb'])
          ?.toString();
      final state = (address['state'] ?? address['province'] ?? address['region'])?.toString();
      final country = address['country']?.toString();

      final parts = [city, state, country]
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }

  Future<TrafficSnapshot> fetchTraffic({
    required double latitude,
    required double longitude,
    required int radiusMiles,
  }) async {
    final baseUri = Uri.parse(_trafficApiBaseUrl);
    final uri = baseUri.replace(
      path: _joinPath(baseUri.path, '/api/traffic'),
      queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radiusMiles.toString(),
      },
    );

    try {
      final response = await http.get(uri);
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return TrafficSnapshot(
          radiusMiles: radiusMiles,
          incidents: const [],
          fetchedAt: DateTime.now(),
          isAvailable: false,
          errorMessage: json['error']?.toString() ??
              'Traffic API returned ${response.statusCode}',
        );
      }

      final incidentsJson = json['incidents'] as List<dynamic>? ?? const [];
      final incidents = incidentsJson
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => TrafficIncident(
              title: item['title']?.toString() ?? 'Traffic incident nearby',
              category: item['category']?.toString() ?? 'Traffic',
              delayMinutes: _asInt(item['delayMinutes']),
            ),
          )
          .toList()
        ..sort((a, b) => b.delayMinutes.compareTo(a.delayMinutes));

      return TrafficSnapshot(
        radiusMiles: _asInt(json['radiusMiles']) == 0 ? radiusMiles : _asInt(json['radiusMiles']),
        incidents: incidents,
        fetchedAt: DateTime.tryParse(json['fetchedAt']?.toString() ?? '') ?? DateTime.now(),
        isAvailable: json['isAvailable'] as bool? ?? false,
        errorMessage: json['error']?.toString(),
      );
    } catch (_) {
      return TrafficSnapshot(
        radiusMiles: radiusMiles,
        incidents: const [],
        fetchedAt: DateTime.now(),
        isAvailable: false,
        errorMessage:
            'Unable to reach the traffic backend. Check adb reverse or TRAFFIC_API_BASE_URL.',
      );
    }
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

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
