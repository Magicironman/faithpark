import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> configure({required bool cantonese}) async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    if (cantonese) {
      await _tts.setLanguage('zh-HK');
    } else {
      await _tts.setLanguage('en-CA');
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
