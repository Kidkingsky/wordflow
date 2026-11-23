import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// An English system voice the learner can pick.
class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
    required this.quality,
    required this.score,
  });

  final String name;
  final String locale;

  /// iOS: "default" / "enhanced" / "premium". Empty when the platform does
  /// not report it.
  final String quality;
  final int score;

  bool get isHighQuality => quality == 'enhanced' || quality == 'premium';

  String get label {
    final accent = switch (locale.toLowerCase().replaceAll('_', '-')) {
      final l when l.startsWith('en-us') => '美式',
      final l when l.startsWith('en-gb') => '英式',
      final l when l.startsWith('en-au') => '澳洲',
      _ => locale,
    };
    final tag = isHighQuality ? ' · 高品質' : '';
    return '$name（$accent$tag）';
  }
}

/// Ranks English voices so the app does not fall back to the robotic
/// "compact" or novelty voices that iOS sometimes picks for `en-US`.
@visibleForTesting
int scoreVoice({
  required String name,
  required String locale,
  String quality = '',
}) {
  final loc = locale.toLowerCase().replaceAll('_', '-');
  final lowerName = name.toLowerCase();
  var score = 0;

  if (quality == 'premium') score += 300;
  if (quality == 'enhanced') score += 200;

  if (loc.startsWith('en-us')) {
    score += 50;
  } else if (loc.startsWith('en-gb')) {
    score += 30;
  } else {
    score += 10;
  }

  // Natural-sounding iOS voices.
  const preferred = {
    'samantha', 'ava', 'zoe', 'allison', 'susan', 'tom', 'evan', 'nathan',
    'nicky', 'joelle', 'noelle', 'daniel', 'serena', 'kate', 'karen',
  };
  if (preferred.any(lowerName.contains)) score += 40;

  // Android: local voices work offline; network voices need internet.
  if (lowerName.contains('local')) score += 5;
  if (lowerName.contains('network')) score -= 5;

  // iOS novelty / Eloquence voices sound odd for language learning.
  const novelty = {
    'albert', 'bad news', 'bahh', 'bells', 'boing', 'bubbles', 'cellos',
    'good news', 'jester', 'organ', 'superstar', 'trinoids', 'whisper',
    'wobble', 'zarvox', 'fred', 'junior', 'kathy', 'ralph', 'eddy', 'flo',
    'grandma', 'grandpa', 'reed', 'rocko', 'sandy', 'shelley',
  };
  if (novelty.contains(lowerName) ||
      novelty.any((n) => lowerName.startsWith('$n ('))) {
    score -= 500;
  }
  return score;
}

class SpeechService {
  final FlutterTts _tts = FlutterTts();
  Future<void>? _setup;
  Future<List<TtsVoice>>? _voices;
  String? _appliedVoice;

  Future<void> _ensureSetup() => _setup ??= _configure();

  Future<void> _configure() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        // "playback" keeps speech audible when the ring/silent switch is on
        // silent; the default ambient category mutes it.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.duckOthers],
        );
      } catch (error) {
        debugPrint('Could not set iOS audio category: $error');
      }
    }
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  /// English voices installed on this device, best first.
  Future<List<TtsVoice>> englishVoices() => _voices ??= _loadVoices();

  Future<List<TtsVoice>> _loadVoices() async {
    await _ensureSetup();
    final voices = <TtsVoice>[];
    try {
      final raw = await _tts.getVoices;
      if (raw is List) {
        for (final value in raw) {
          if (value is! Map) continue;
          final name = value['name']?.toString();
          final locale = value['locale']?.toString();
          if (name == null || locale == null) continue;
          if (!locale.toLowerCase().startsWith('en')) continue;
          final quality = value['quality']?.toString().toLowerCase() ?? '';
          voices.add(TtsVoice(
            name: name,
            locale: locale,
            quality: quality,
            score: scoreVoice(name: name, locale: locale, quality: quality),
          ));
        }
      }
    } catch (error) {
      debugPrint('Could not list voices: $error');
    }
    voices.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.name.compareTo(b.name);
    });
    // setVoice selects by name, so keep only the best voice per name (iOS can
    // list a default and an enhanced voice under the same name).
    final seen = <String>{};
    return voices.where((v) => seen.add(v.name)).toList(growable: false);
  }

  /// [rate] is 0.0–1.0 with 0.5 as natural speed. flutter_tts uses this scale
  /// on both iOS and Android.
  Future<void> speak(String text, {double rate = 0.5, String? voiceName}) async {
    await _ensureSetup();
    await _tts.stop();
    try {
      final voices = await englishVoices();
      final voice = voices
              .where((v) => v.name == voiceName)
              .firstOrNull ??
          voices.firstOrNull;
      if (voice != null && voice.name != _appliedVoice) {
        await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
        _appliedVoice = voice.name;
      }
    } catch (error) {
      // Fall back to the system default English voice.
      debugPrint('Could not set voice: $error');
    }
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }
}
