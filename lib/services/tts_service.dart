import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'book_repository.dart';
import 'storage_service.dart';
import 'web_tts/web_tts.dart';
import 'audio_player_service.dart';

enum TtsPlayState { stopped, playing, paused }

class TtsService with ChangeNotifier {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final StorageService _storage = StorageService();

  static const List<double> availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  TtsPlayState _state = TtsPlayState.stopped;
  TtsPlayState get state => _state;

  List<String> _currentParagraphs = [];
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _ttsSessionId = 0;

  String _currentSectionId = '';
  String get currentSectionId => _currentSectionId;

  String _currentSectionTitle = '';
  String get currentSectionTitle => _currentSectionTitle;

  bool _currentIsEnglish = false;
  bool get currentIsEnglish => _currentIsEnglish;

  Timer? _sleepTimer;
  int _sleepMinutesRemaining = 0;
  int get sleepMinutesRemaining => _sleepMinutesRemaining;

  bool _isInitialized = false;

  // Callback when a whole section finishes playing
  VoidCallback? onSectionFinished;

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      WebTts.instance.onStart = () {
        _state = TtsPlayState.playing;
        notifyListeners();
      };
      WebTts.instance.onCompletion = () {
        _onParagraphComplete();
      };
      WebTts.instance.onPause = () {
        _state = TtsPlayState.paused;
        notifyListeners();
      };
      WebTts.instance.onContinue = () {
        _state = TtsPlayState.playing;
        notifyListeners();
      };
      WebTts.instance.onError = (msg) {
        _state = TtsPlayState.stopped;
        notifyListeners();
      };
      await WebTts.instance.init();
      _isInitialized = true;
      return;
    }

    // Apply speed and pitch on Android/Mobile
    await _applySpeedMultiplier(_storage.ttsSpeedMultiplier);
    await _flutterTts.setPitch(_storage.ttsPitch);

    _flutterTts.setStartHandler(() {
      _state = TtsPlayState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _onParagraphComplete();
    });

    _flutterTts.setPauseHandler(() {
      _state = TtsPlayState.paused;
      notifyListeners();
    });

    _flutterTts.setContinueHandler(() {
      _state = TtsPlayState.playing;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      // ignore: avoid_print
      print('TTS Error: $msg');
      _state = TtsPlayState.stopped;
      notifyListeners();
    });

    _isInitialized = true;
  }

  double _multiplierToAndroidRate(double multiplier) {
    // 0.45 is comfortable reading pace on Android TTS for 1.0x
    return (multiplier * 0.45).clamp(0.15, 1.0);
  }

  Future<void> _applySpeedMultiplier(double multiplier) async {
    final rate = _multiplierToAndroidRate(multiplier);
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setSpeedMultiplier(double multiplier) async {
    if (!kIsWeb) {
      await _applySpeedMultiplier(multiplier);
    } else {
      await WebTts.instance.setRate(multiplier);
    }
    await _storage.setTtsSpeedMultiplier(multiplier);
    notifyListeners();

    if (_state == TtsPlayState.playing) {
      if (!kIsWeb) {
        await stop();
        await _speakCurrentIndex();
      }
    }
  }

  double get currentSpeedMultiplier => _storage.ttsSpeedMultiplier;

  Future<void> setLanguage(bool isEnglish) async {
    _currentIsEnglish = isEnglish;

    if (kIsWeb) {
      await WebTts.instance.init();
      return;
    }

    final lang = isEnglish ? 'en-US' : 'vi-VN';
    await _flutterTts.setLanguage(lang);

    // Apply voice specifically configured for this language
    final voiceName = _storage.getVoiceName(isEnglish);
    final voiceLocale = _storage.getVoiceLocale(isEnglish);

    if (voiceName != null && voiceLocale != null) {
      try {
        await _flutterTts.setVoice({'name': voiceName, 'locale': voiceLocale});
        return;
      } catch (_) {}
    }

    // Auto-select first matching voice for this language if none is saved
    try {
      final voices = await getAvailableVoices(isEnglish);
      if (voices.isNotEmpty) {
        final first = voices.first;
        await _flutterTts.setVoice({'name': first['name']!, 'locale': first['locale']!});
        await _storage.setVoiceForLanguage(
          isEnglish: isEnglish,
          name: first['name'],
          locale: first['locale'],
        );
      }
    } catch (_) {}
  }

  static String formatVoiceDisplayName(String name, String locale, int index, bool isEnglish) {
    final lower = name.toLowerCase();

    // Check gender hints
    bool isFemale = lower.contains('female') ||
        lower.contains('vif') ||
        lower.contains('vic') ||
        lower.contains('sfg') ||
        lower.contains('woman') ||
        lower.contains('-f-') ||
        lower.contains('_f_');
    bool isMale = lower.contains('male') ||
        lower.contains('vid') ||
        lower.contains('vie') ||
        lower.contains('man') ||
        lower.contains('-m-') ||
        lower.contains('_m_');
    bool isNetwork = lower.contains('network') || lower.contains('neural') || lower.contains('wavenet');

    if (locale.toLowerCase().startsWith('vi')) {
      String gender;
      if (isFemale) {
        gender = 'Nữ';
      } else if (isMale) {
        gender = 'Nam';
      } else {
        gender = (index % 2 == 1) ? 'Nữ' : 'Nam';
      }
      String quality = isNetwork ? 'Truyền cảm' : 'Chuẩn máy';
      return isEnglish
          ? 'Vietnamese Voice ${index + 1} ($gender - $quality)'
          : 'Giọng đọc Tiếng Việt ${index + 1} ($gender - $quality)';
    } else {
      String region = 'US';
      if (locale.toLowerCase().contains('gb') || locale.toLowerCase().contains('uk')) {
        region = 'UK';
      } else if (locale.toLowerCase().contains('au')) {
        region = 'AU';
      }
      String gender = isFemale ? 'Female' : (isMale ? 'Male' : (index % 2 == 1 ? 'Female' : 'Male'));
      String quality = isNetwork ? 'Natural' : 'Standard';
      return isEnglish
          ? 'English Voice ${index + 1} ($region $gender - $quality)'
          : 'Giọng đọc Tiếng Anh ${index + 1} ($region $gender - $quality)';
    }
  }

  Future<List<Map<String, String>>> getAvailableVoices(bool isEnglish) async {
    await init();
    if (kIsWeb) {
      return await WebTts.instance.getAvailableVoices(isEnglish);
    }

    final targetPrefix = isEnglish ? 'en' : 'vi';
    try {
      final dynamic raw = await _flutterTts.getVoices;
      if (raw is List) {
        final List<Map<String, String>> result = [];
        int idx = 0;
        for (var item in raw) {
          if (item is Map) {
            final name = item['name']?.toString() ?? '';
            final locale = item['locale']?.toString() ?? '';
            if (locale.toLowerCase().startsWith(targetPrefix)) {
              final displayName = formatVoiceDisplayName(name, locale, idx, isEnglish);
              result.add({
                'name': name,
                'locale': locale,
                'displayName': displayName,
              });
              idx++;
            }
          }
        }
        return result;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting voices: $e');
    }
    return [];
  }

  Future<void> setVoice(Map<String, String> voice) async {
    final isEn = voice['locale']?.toLowerCase().startsWith('en') ?? _storage.isEnglish;
    _currentIsEnglish = isEn;
    await _storage.setVoiceForLanguage(
      isEnglish: isEn,
      name: voice['name'],
      locale: voice['locale'],
    );

    if (!kIsWeb) {
      await _flutterTts.setVoice(voice);
    }

    notifyListeners();

    // Immediate audio feedback
    if (_state == TtsPlayState.playing) {
      await stop();
      await _speakCurrentIndex();
    } else {
      final sample = isEn ? 'The Science of Spirituality.' : 'Khoa học và tâm linh.';
      if (kIsWeb) {
        await WebTts.instance.speak(
          sample,
          isEnglish: isEn,
          rate: _storage.ttsSpeedMultiplier,
          pitch: _storage.ttsPitch,
          preferredVoiceName: voice['name'],
        );
      } else {
        await _flutterTts.speak(sample);
      }
    }
  }

  Future<void> startReadingSection({
    required String sectionId,
    required List<String> paragraphs,
    required bool isEnglish,
    String? title,
    int startIndex = 0,
  }) async {
    // Stop any active Podcast playing
    try {
      AudioPlayerService().stop();
    } catch (_) {}

    await init();
    await stop();

    _currentSectionId = sectionId;
    _currentParagraphs = paragraphs;
    _currentSectionTitle = title ?? '';
    _currentIsEnglish = isEnglish;

    if (startIndex <= 0 && _currentSectionTitle.trim().isNotEmpty) {
      _currentIndex = -1; // -1 represents reading the Chapter Title
    } else {
      _currentIndex = startIndex.clamp(0, paragraphs.isEmpty ? 0 : paragraphs.length - 1);
    }

    await setLanguage(isEnglish);
    await _speakCurrentIndex();
  }

  Future<void> _speakCurrentIndex() async {
    if (_currentIndex < -1 || _currentIndex >= _currentParagraphs.length) {
      _state = TtsPlayState.stopped;
      notifyListeners();
      return;
    }

    final String rawText;
    if (_currentIndex == -1) {
      rawText = _currentSectionTitle.trim();
    } else {
      rawText = _currentParagraphs[_currentIndex].trim();
    }

    if (rawText.isEmpty) {
      _onParagraphComplete();
      return;
    }

    _ttsSessionId++;
    _state = TtsPlayState.playing;
    notifyListeners();

    final text = _formatParagraphForTts(rawText);

    if (kIsWeb) {
      await WebTts.instance.speak(
        text,
        isEnglish: _currentIsEnglish,
        rate: _storage.ttsSpeedMultiplier,
        pitch: _storage.ttsPitch,
        preferredVoiceName: _storage.getVoiceName(_currentIsEnglish),
      );
    } else {
      await _flutterTts.speak(text);
    }
  }

  String _formatParagraphForTts(String paragraph) {
    var s = paragraph.trim();
    // Replace colons with comma followed by space so TTS takes a natural breath pause without pronouncing the colon
    s = s.replaceAll(RegExp(r'\s*:\s*'), ', ');
    // Replace semicolons with comma followed by space
    s = s.replaceAll(RegExp(r'\s*;\s*'), ', ');
    // Replace punctuation dashes with comma followed by space
    s = s.replaceAll(RegExp(r'\s+[-–—]\s*'), ', ');
    // Clean up any double commas or extra spaces
    s = s.replaceAll(RegExp(r',\s*,'), ',');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  Future<void> _onParagraphComplete() async {
    if (_state != TtsPlayState.playing) return;
    final session = _ttsSessionId;

    // Pause between paragraphs (xuống dòng) as configured in user settings
    final pBreak = _storage.ttsBreakParagraph;
    if (pBreak > 0) {
      await Future.delayed(Duration(milliseconds: (pBreak * 1000).round()));
    }
    if (_state != TtsPlayState.playing || session != _ttsSessionId) return;

    if (_currentIndex == -1) {
      // Finished reading chapter title, start reading first paragraph (index 0)
      if (_currentParagraphs.isNotEmpty) {
        _currentIndex = 0;
        notifyListeners();
        _speakCurrentIndex();
      } else {
        _handleSectionFinished();
      }
      return;
    }

    if (_currentIndex < _currentParagraphs.length - 1) {
      _currentIndex++;
      notifyListeners();
      _speakCurrentIndex();
    } else {
      // End of section reached!
      _handleSectionFinished();
    }
  }

  Future<void> _handleSectionFinished() async {
    final mode = _storage.autoNextChapterMode; // 'next', 'repeat', 'stop'
    if (mode == 'repeat') {
      _currentIndex = _currentSectionTitle.trim().isNotEmpty ? -1 : 0;
      notifyListeners();
      await _speakCurrentIndex();
      return;
    }

    if (mode == 'next') {
      final repo = BookRepository();
      final nextSec = repo.getNextSection(_currentSectionId);
      if (nextSec != null) {
        final nextParas = nextSec.getParagraphs(_currentIsEnglish);
        final nextTitle = nextSec.getTitle(_currentIsEnglish);
        _currentSectionId = nextSec.id;
        _currentParagraphs = nextParas;
        _currentSectionTitle = nextTitle;
        _currentIndex = nextTitle.trim().isNotEmpty ? -1 : 0;
        _storage.saveLastRead(nextSec.id, nextTitle);
        notifyListeners();

        if (onSectionFinished != null) {
          try {
            onSectionFinished!();
          } catch (_) {}
        }

        // Brief natural pause between chapters (600ms)
        await Future.delayed(const Duration(milliseconds: 600));
        if (_state == TtsPlayState.playing || _state == TtsPlayState.paused) {
          _state = TtsPlayState.playing;
          notifyListeners();
          await _speakCurrentIndex();
        }
        return;
      }
    }

    // End of book or mode == 'stop'
    _state = TtsPlayState.stopped;
    notifyListeners();
    if (onSectionFinished != null) {
      try {
        onSectionFinished!();
      } catch (_) {}
    }
  }

  Future<void> pause() async {
    _ttsSessionId++;
    if (kIsWeb) {
      await WebTts.instance.pause();
    } else {
      await _flutterTts.pause();
    }
    _state = TtsPlayState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_state == TtsPlayState.paused) {
      try {
        AudioPlayerService().stop();
      } catch (_) {}

      _ttsSessionId++;
      _state = TtsPlayState.playing;
      notifyListeners();

      if (kIsWeb) {
        await WebTts.instance.resume();
      } else {
        await _speakCurrentIndex();
      }
    }
  }

  Future<void> stop() async {
    _ttsSessionId++;
    if (kIsWeb) {
      await WebTts.instance.stop();
    } else {
      await _flutterTts.stop();
    }
    _state = TtsPlayState.stopped;
    cancelSleepTimer();
    notifyListeners();
  }

  Future<void> nextParagraph() async {
    if (_currentIndex < _currentParagraphs.length - 1) {
      await stop();
      _currentIndex++;
      await _speakCurrentIndex();
    }
  }

  Future<void> prevParagraph() async {
    final minIndex = _currentSectionTitle.trim().isNotEmpty ? -1 : 0;
    if (_currentIndex > minIndex) {
      await stop();
      _currentIndex--;
      await _speakCurrentIndex();
    }
  }

  Future<void> setPitch(double pitch, {bool previewIfIdle = true}) async {
    if (!kIsWeb) {
      await _flutterTts.setPitch(pitch);
    }
    await _storage.setTtsPitch(pitch);
    notifyListeners();

    if (_state == TtsPlayState.playing) {
      await stop();
      await _speakCurrentIndex();
    } else if (previewIfIdle) {
      final isEn = _storage.isEnglish;
      final sample = isEn ? 'The Science of Spirituality.' : 'Khoa học và tâm linh.';
      if (kIsWeb) {
        await WebTts.instance.speak(
          sample,
          isEnglish: isEn,
          rate: _storage.ttsSpeedMultiplier,
          pitch: pitch,
          preferredVoiceName: _storage.getVoiceName(isEn),
        );
      } else {
        await _flutterTts.speak(sample);
      }
    }
  }

  // --- Sleep Timer ---
  void setSleepTimer(int minutes) {
    cancelSleepTimer();
    if (minutes <= 0) return;

    _sleepMinutesRemaining = minutes;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _sleepMinutesRemaining--;
      notifyListeners();
      if (_sleepMinutesRemaining <= 0) {
        stop();
        cancelSleepTimer();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMinutesRemaining = 0;
    notifyListeners();
  }
}
