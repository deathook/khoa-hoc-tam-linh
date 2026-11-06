// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:ui';

class WebTts {
  static final WebTts instance = WebTts._();
  WebTts._();

  VoidCallback? onStart;
  VoidCallback? onCompletion;
  VoidCallback? onPause;
  VoidCallback? onContinue;
  void Function(String msg)? onError;

  Future<void> init() async {}

  Future<List<Map<String, String>>> getAvailableVoices(bool isEnglish) async {
    try {
      final tts = js.context['KHTL_TTS'];
      if (tts != null) {
        final jsVoices = tts.callMethod('getVoices') as js.JsArray?;
        if (jsVoices != null) {
          final List<Map<String, String>> result = [];
          for (var i = 0; i < jsVoices.length; i++) {
            final v = jsVoices[i];
            final name = v['name']?.toString() ?? '';
            final lang = v['lang']?.toString() ?? '';
            final lowerName = name.toLowerCase();
            final lowerLang = lang.toLowerCase();

            bool isMatch = false;
            if (isEnglish) {
              isMatch = lowerLang.startsWith('en') || lowerName.contains('english');
            } else {
              isMatch = lowerLang.startsWith('vi') ||
                  lowerName.contains('vietnam') ||
                  lowerName.contains('tiếng việt') ||
                  lowerName.contains('tieng viet') ||
                  lowerName.contains('hoaimy') ||
                  lowerName.contains('namminh') ||
                  lowerName.contains('an');
            }

            if (isMatch) {
              String displayName;
              if (isEnglish) {
                displayName = '$name ($lang)';
              } else {
                final isFemale = lowerName.contains('female') ||
                    lowerName.contains('nữ') ||
                    lowerName.contains('hoaimy') ||
                    lowerName.contains('an');
                final gender = isFemale ? 'Nữ' : 'Nam';
                displayName = '$name (Tiếng Việt - $gender)';
              }

              result.add({
                'name': name,
                'locale': lang.isNotEmpty ? lang : (isEnglish ? 'en-US' : 'vi-VN'),
                'displayName': displayName,
              });
            }
          }

          if (!isEnglish && result.isEmpty) {
            result.add({
              'name': 'Google Tiếng Việt (Tự động)',
              'locale': 'vi-VN',
              'displayName': 'Giọng đọc Tiếng Việt (Google Chuẩn - Tự động)',
            });
          }
          return result;
        }
      }
    } catch (_) {}

    if (!isEnglish) {
      return [
        {
          'name': 'Google Tiếng Việt (Tự động)',
          'locale': 'vi-VN',
          'displayName': 'Giọng đọc Tiếng Việt (Google Chuẩn - Tự động)',
        }
      ];
    }
    return [];
  }

  Future<void> speak(
    String text, {
    required bool isEnglish,
    required double rate,
    required double pitch,
    String? preferredVoiceName,
  }) async {
    try {
      final tts = js.context['KHTL_TTS'];
      if (tts != null) {
        tts.callMethod('speak', [
          text,
          isEnglish,
          rate,
          pitch,
          preferredVoiceName,
          js.JsFunction.withThis((_) => onStart?.call()),
          js.JsFunction.withThis((_) => onCompletion?.call()),
          js.JsFunction.withThis((_, err) => onError?.call(err.toString())),
        ]);
      }
    } catch (e) {
      // ignore: avoid_print
      print('WebTts speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      final tts = js.context['KHTL_TTS'];
      tts?.callMethod('stop');
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      final tts = js.context['KHTL_TTS'];
      tts?.callMethod('pause');
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      final tts = js.context['KHTL_TTS'];
      tts?.callMethod('resume');
    } catch (_) {}
  }
}
