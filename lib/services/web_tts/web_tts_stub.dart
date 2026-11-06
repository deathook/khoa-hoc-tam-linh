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

  Future<List<Map<String, String>>> getAvailableVoices(bool isEnglish) async => [];

  Future<void> speak(
    String text, {
    required bool isEnglish,
    required double rate,
    required double pitch,
    String? preferredVoiceName,
  }) async {}

  Future<void> stop() async {}
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> setRate(double rate) async {}
}
