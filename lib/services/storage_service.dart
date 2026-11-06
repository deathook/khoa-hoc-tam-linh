import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_note.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  final ValueNotifier<bool> isEnglishNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> themeModeNotifier = ValueNotifier<String>('light');

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    isEnglishNotifier.value = isEnglish;
    themeModeNotifier.value = themeMode;
  }

  // --- Reading Preferences ---
  bool get isEnglish => _prefs?.getBool('pref_is_english') ?? false;
  Future<void> setIsEnglish(bool val) async {
    await _prefs?.setBool('pref_is_english', val);
    isEnglishNotifier.value = val;
  }

  String get themeMode => _prefs?.getString('pref_theme_mode') ?? 'light'; // light, sepia, dark
  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString('pref_theme_mode', mode);
    themeModeNotifier.value = mode;
  }

  double get fontSize => _prefs?.getDouble('pref_font_size') ?? 17.0;
  Future<void> setFontSize(double size) async => await _prefs?.setDouble('pref_font_size', size);

  String get fontFamily => _prefs?.getString('pref_font_family') ?? 'Default';
  Future<void> setFontFamily(String font) async => await _prefs?.setString('pref_font_family', font);

  // --- TTS Settings ---
  // Speed multiplier: 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
  double get ttsSpeedMultiplier => _prefs?.getDouble('pref_tts_speed_mult') ?? 1.0;
  Future<void> setTtsSpeedMultiplier(double mult) async => await _prefs?.setDouble('pref_tts_speed_mult', mult);

  double get ttsPitch => _prefs?.getDouble('pref_tts_pitch') ?? 1.0;
  Future<void> setTtsPitch(double pitch) async => await _prefs?.setDouble('pref_tts_pitch', pitch);

  // Auto-next chapter mode: 'next' (Chuyển chương tiếp), 'repeat' (Lặp lại), 'stop' (Dừng lại)
  String get autoNextChapterMode => _prefs?.getString('pref_tts_chapter_mode') ?? 'next';
  Future<void> setAutoNextChapterMode(String mode) async => await _prefs?.setString('pref_tts_chapter_mode', mode);

  // Voice selection per language (Vietnamese vs English)
  String? getVoiceName(bool isEnglish) {
    final key = isEnglish ? 'pref_tts_voice_name_en' : 'pref_tts_voice_name_vi';
    final saved = _prefs?.getString(key);
    if (saved != null) return saved;
    // Fallback to legacy key if locale matches
    final oldName = _prefs?.getString('pref_tts_voice_name');
    final oldLocale = _prefs?.getString('pref_tts_voice_locale');
    if (oldLocale != null && oldName != null) {
      final matches = isEnglish ? oldLocale.toLowerCase().startsWith('en') : oldLocale.toLowerCase().startsWith('vi');
      if (matches) return oldName;
    }
    return null;
  }

  String? getVoiceLocale(bool isEnglish) {
    final key = isEnglish ? 'pref_tts_voice_locale_en' : 'pref_tts_voice_locale_vi';
    final saved = _prefs?.getString(key);
    if (saved != null) return saved;
    final oldLocale = _prefs?.getString('pref_tts_voice_locale');
    if (oldLocale != null) {
      final matches = isEnglish ? oldLocale.toLowerCase().startsWith('en') : oldLocale.toLowerCase().startsWith('vi');
      if (matches) return oldLocale;
    }
    return null;
  }

  Future<void> setVoiceForLanguage({
    required bool isEnglish,
    required String? name,
    required String? locale,
  }) async {
    final nameKey = isEnglish ? 'pref_tts_voice_name_en' : 'pref_tts_voice_name_vi';
    final locKey = isEnglish ? 'pref_tts_voice_locale_en' : 'pref_tts_voice_locale_vi';
    if (name != null) {
      await _prefs?.setString(nameKey, name);
    } else {
      await _prefs?.remove(nameKey);
    }
    if (locale != null) {
      await _prefs?.setString(locKey, locale);
    } else {
      await _prefs?.remove(locKey);
    }
    // Also keep legacy for backwards compatibility
    if (name != null && locale != null) {
      await _prefs?.setString('pref_tts_voice_name', name);
      await _prefs?.setString('pref_tts_voice_locale', locale);
    }
  }

  // Voice selection (legacy compatibility)
  String? get ttsVoiceName => getVoiceName(isEnglish);
  String? get ttsVoiceLocale => getVoiceLocale(isEnglish);
  Future<void> setTtsVoice(String? name, String? locale) async =>
      setVoiceForLanguage(isEnglish: isEnglish, name: name, locale: locale);

  // --- Last Read Progress ---
  String? get lastReadSectionId => _prefs?.getString('last_read_section_id');
  String? get lastReadSectionTitle => _prefs?.getString('last_read_section_title');
  Future<void> saveLastRead(String sectionId, String sectionTitle) async {
    await _prefs?.setString('last_read_section_id', sectionId);
    await _prefs?.setString('last_read_section_title', sectionTitle);
  }

  // --- Bookmarks ---
  List<String> getBookmarks() => _prefs?.getStringList('bookmarks') ?? [];
  bool isBookmarked(String sectionId) => getBookmarks().contains(sectionId);
  Future<void> toggleBookmark(String sectionId) async {
    final list = getBookmarks();
    if (list.contains(sectionId)) {
      list.remove(sectionId);
    } else {
      list.add(sectionId);
    }
    await _prefs?.setStringList('bookmarks', list);
  }

  // --- Highlights ---
  List<UserHighlight> getHighlights() {
    final raw = _prefs?.getStringList('user_highlights') ?? [];
    return raw.map((str) {
      try {
        return UserHighlight.fromJson(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<UserHighlight>().toList();
  }

  Future<void> addHighlight(UserHighlight h) async {
    final list = getHighlights();
    list.removeWhere((item) => item.sectionId == h.sectionId && item.paragraphIndex == h.paragraphIndex);
    list.insert(0, h);
    final raw = list.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs?.setStringList('user_highlights', raw);
  }

  Future<void> removeHighlight(String id) async {
    final list = getHighlights();
    list.removeWhere((item) => item.id == id);
    final raw = list.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs?.setStringList('user_highlights', raw);
  }

  Future<void> removeHighlightBySectionAndIndex(String sectionId, int paragraphIndex) async {
    final list = getHighlights();
    list.removeWhere((item) => item.sectionId == sectionId && item.paragraphIndex == paragraphIndex);
    final raw = list.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs?.setStringList('user_highlights', raw);
  }

  // --- Notes ---
  List<UserNote> getNotes() {
    final raw = _prefs?.getStringList('user_notes') ?? [];
    return raw.map((str) {
      try {
        return UserNote.fromJson(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<UserNote>().toList();
  }

  Future<void> saveNote(UserNote note) async {
    final list = getNotes();
    list.removeWhere((item) => item.id == note.id);
    list.insert(0, note);
    final raw = list.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs?.setStringList('user_notes', raw);
  }

  Future<void> deleteNote(String id) async {
    final list = getNotes();
    list.removeWhere((item) => item.id == id);
    final raw = list.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs?.setStringList('user_notes', raw);
  }
}
