import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../routes/seo_router.dart';
import '../services/seo/seo_service.dart';
import 'home/home_screen.dart';
import 'reader/toc_screen.dart';
import 'reader/reader_screen.dart';
import 'podcast/podcast_screen.dart';
import 'notes/notes_screen.dart';
import 'settings/settings_screen.dart';
import 'search/search_screen.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/audio_player_service.dart';
import '../theme/app_colors.dart';
import '../utils/web_download.dart';

class MainNavScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final int initialTabIndex;
  final String? initialSectionId;

  const MainNavScreen({
    Key? key,
    required this.onThemeChanged,
    this.initialTabIndex = 0,
    this.initialSectionId,
  }) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  final StorageService _storage = StorageService();
  final TtsService _tts = TtsService();
  final AudioPlayerService _audioPlayer = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _tts.addListener(_onServiceUpdate);
    _audioPlayer.addListener(_onServiceUpdate);
    _storage.isEnglishNotifier.addListener(_onServiceUpdate);
    _storage.themeModeNotifier.addListener(_onServiceUpdate);

    SeoService.listenPopState(_handleBrowserPopState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSectionId != null && widget.initialSectionId!.isNotEmpty) {
        _openReader(widget.initialSectionId!);
      } else {
        _syncUrlWithCurrentState(replace: true);
      }
    });
  }

  void _handleBrowserPopState(String path) {
    if (!mounted) return;
    final parsed = SeoRouter.parsePath(path);
    if (parsed.isEnglish != _storage.isEnglish) {
      _storage.setIsEnglish(parsed.isEnglish);
      _tts.setLanguage(parsed.isEnglish);
    }
    if (parsed.type == SeoRouteType.reader && parsed.sectionId != null) {
      _openReader(parsed.sectionId!);
    } else {
      setState(() {
        _currentIndex = parsed.tabIndex;
      });
    }
  }

  void _syncUrlWithCurrentState({bool replace = false}) {
    final url = SeoRouter.getTabUrl(_currentIndex, _storage.isEnglish);
    final title = SeoRouter.getTabTitle(_currentIndex, _storage.isEnglish);
    SeoService.updateUrl(url, title: title, replace: replace);
  }

  @override
  void dispose() {
    _tts.removeListener(_onServiceUpdate);
    _audioPlayer.removeListener(_onServiceUpdate);
    _storage.isEnglishNotifier.removeListener(_onServiceUpdate);
    _storage.themeModeNotifier.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _setIndex(int idx) {
    setState(() => _currentIndex = idx);
    _syncUrlWithCurrentState(replace: false);
  }

  void _openReader(String sectionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(sectionId: sectionId),
      ),
    ).then((_) {
      if (mounted) {
        _syncUrlWithCurrentState(replace: false);
      }
    });
  }

  void _downloadAndroidApk() {
    downloadFile('KhoaHocTamLinh.apk');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_storage.isEnglish
            ? 'Downloading Android APK: KhoaHocTamLinh.apk'
            : 'Đang tải về bộ cài Android: KhoaHocTamLinh.apk'),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = _storage.isEnglish;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;

    final isTtsActive = _tts.state != TtsPlayState.stopped;
    final isAudioActive = _audioPlayer.state != AudioPlayState.stopped && _audioPlayer.currentPodcast != null;

    final screens = [
      HomeScreen(
        onOpenLibrary: () => _setIndex(1),
        onOpenAudio: () => _setIndex(2),
      ),
      const TocScreen(),
      const PodcastScreen(),
      const NotesScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    if (isDesktopWeb) {
      // Desktop / Web Layout with Top Header Navigation
      return Scaffold(
        body: Column(
          children: [
            // Top Website Navigation Header
            _buildWebHeader(isEnglish, isDark),

            // Active Screen Content
            Expanded(
              child: screens[_currentIndex],
            ),

            // Mini-player bar if TTS or Audio is active
            if (isTtsActive) _buildTtsMiniBar(isEnglish, isDark),
            if (!isTtsActive && isAudioActive) _buildAudioMiniBar(isEnglish, isDark),
          ],
        ),
      );
    }

    // Mobile Phone Layout with Bottom Navigation Bar
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini-player bar if TTS or Audio is active
          if (isTtsActive) _buildTtsMiniBar(isEnglish, isDark),
          if (!isTtsActive && isAudioActive) _buildAudioMiniBar(isEnglish, isDark),

          // Bottom Nav Bar
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _setIndex,
            indicatorColor: AppColors.primary.withOpacity(0.2),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.wb_sunny_outlined),
                selectedIcon: const Icon(Icons.wb_sunny, color: AppColors.primaryDark),
                label: isEnglish ? 'Today' : 'Hôm nay',
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book, color: AppColors.primaryDark),
                label: isEnglish ? 'Book' : 'Đọc Sách',
              ),
              NavigationDestination(
                icon: const Icon(Icons.podcasts_outlined),
                selectedIcon: const Icon(Icons.podcasts, color: AppColors.primaryDark),
                label: isEnglish ? 'Audio' : 'Sách Nói',
              ),
              NavigationDestination(
                icon: const Icon(Icons.edit_note_outlined),
                selectedIcon: const Icon(Icons.edit_note, color: AppColors.primaryDark),
                label: isEnglish ? 'Notes' : 'Ghi Chú',
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings, color: AppColors.primaryDark),
                label: isEnglish ? 'Settings' : 'Cài Đặt',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader(bool isEnglish, bool isDark) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Brand Logo & Title
          InkWell(
            onTap: () => _setIndex(0),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Image.asset(
                        'assets/images/image1.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'THE SCIENCE OF SPIRITUALITY' : 'KHOA HỌC TÂM LINH',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.2,
                          color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        isEnglish ? 'Hoang Nhat Minh • Two Languages, One Truth' : 'Hoàng Nhật Minh • Hai ngôn ngữ, một chân lý',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Desktop Nav Links
          _buildWebNavLink(0, Icons.wb_sunny_outlined, isEnglish ? 'Today' : 'Trang Chủ', isDark),
          const SizedBox(width: 4),
          _buildWebNavLink(1, Icons.menu_book_outlined, isEnglish ? 'Read Book' : 'Đọc Sách', isDark),
          const SizedBox(width: 4),
          _buildWebNavLink(2, Icons.podcasts_outlined, isEnglish ? 'Podcasts & Audio' : 'Sách Nói & Podcast', isDark),
          const SizedBox(width: 4),
          _buildWebNavLink(3, Icons.edit_note_outlined, isEnglish ? 'My Notes' : 'Ghi Chú', isDark),
          const SizedBox(width: 4),
          _buildWebNavLink(4, Icons.settings_outlined, isEnglish ? 'Settings' : 'Cài Đặt', isDark),

          const SizedBox(width: 14),
          Container(
            height: 24,
            width: 1,
            color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(width: 14),

          // Search button
          IconButton(
            icon: const Icon(Icons.search, size: 21),
            tooltip: isEnglish ? 'Search book' : 'Tìm kiếm sách',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ).then((_) {
                if (mounted) _syncUrlWithCurrentState(replace: false);
              });
            },
          ),

          // Language Switcher
          InkWell(
            onTap: () async {
              final next = !isEnglish;
              await _storage.setIsEnglish(next);
              await _tts.setLanguage(next);
              setState(() {});
              _syncUrlWithCurrentState(replace: false);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isEnglish ? '🇬🇧' : '🇻🇳', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    isEnglish ? 'EN' : 'VI',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Theme Toggle Button
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined, size: 20),
            tooltip: isDark
                ? (isEnglish ? 'Light Mode' : 'Chế độ Sáng')
                : (isEnglish ? 'Dark Mode' : 'Chế độ Đêm'),
            onPressed: widget.onThemeChanged,
          ),

          const SizedBox(width: 10),

          // Download Android APK Button
          ElevatedButton.icon(
            onPressed: _downloadAndroidApk,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFE5B968) : AppColors.primary,
              foregroundColor: Colors.black87,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.android, size: 18),
            label: Text(
              isEnglish ? 'Get APK' : 'Tải App APK',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebNavLink(int index, IconData icon, String title, bool isDark) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _setIndex(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFE5B968).withOpacity(0.16) : AppColors.primary.withOpacity(0.14))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: isDark ? const Color(0xFFE5B968) : AppColors.primary, width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? const Color(0xFFE5B968) : AppColors.primaryDark)
                  : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFFE5B968) : AppColors.primaryDark)
                    : (isDark ? AppColors.textLight : AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsMiniBar(bool isEnglish, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF232938) : const Color(0xFFFAF3E6),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.volume_up, color: AppColors.primaryDark, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () {
                if (_tts.currentSectionId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(sectionId: _tts.currentSectionId),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEnglish ? 'AUDIOBOOK (TTS)' : 'ĐANG ĐỌC SÁCH NÓI (TTS)',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  Text(
                    isEnglish ? 'Paragraph ${_tts.currentIndex + 1}' : 'Đoạn ${_tts.currentIndex + 1}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(_tts.state == TtsPlayState.playing ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (_tts.state == TtsPlayState.playing) {
                _tts.pause();
              } else {
                _tts.resume();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => _tts.stop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMiniBar(bool isEnglish, bool isDark) {
    final p = _audioPlayer.currentPodcast!;
    return Container(
      color: isDark ? const Color(0xFF232938) : const Color(0xFFFAF3E6),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: AppColors.primaryDark, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.getTitle(isEnglish),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  p.author,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_audioPlayer.state == AudioPlayState.playing ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (_audioPlayer.state == AudioPlayState.playing) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.resume();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => _audioPlayer.stop(),
          ),
        ],
      ),
    );
  }
}
