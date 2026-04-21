import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get languageCode => _prefs.getString('languageCode') ?? 'en';

  bool get speakInCantonese => _prefs.getBool('speakInCantonese') ?? true;

  int get defaultParkingMinutes => _prefs.getInt('defaultParkingMinutes') ?? 60;

  Future<void> setLanguageCode(String value) async {
    await _prefs.setString('languageCode', value);
  }

  Future<void> setSpeakInCantonese(bool value) async {
    await _prefs.setBool('speakInCantonese', value);
  }

  Future<void> setDefaultParkingMinutes(int value) async {
    await _prefs.setInt('defaultParkingMinutes', value);
  }
}
