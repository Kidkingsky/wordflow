import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, {double rate = 0.48}) async {
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

}
