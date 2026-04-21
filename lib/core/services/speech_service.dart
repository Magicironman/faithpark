import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> init() async {
    return _speech.initialize();
  }

  Future<void> listen({
    required void Function(String text) onResult,
    String localeId = 'yue-Hant-HK',
  }) async {
    await _speech.listen(
      localeId: localeId,
      onResult: (result) => onResult(result.recognizedWords),
      listenFor: const Duration(seconds: 8),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
