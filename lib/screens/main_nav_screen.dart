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
import '../services/book_repository.dart';
import '../services/tts_service.dart';
import '../services/audio_player_service.dart';
import '../services/firebase_sync_service.dart';
import '../theme/app_colors.dart';
import '../utils/web_download.dart';
import '../widgets/auth_dialog.dart';

class MainNavScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final int initialTabIndex;
  final String? initialSectionId;
  final int initialParagraphIndex;

  const MainNavScreen({
    Key? key,
    required this.onThemeChanged,
    this.initialTabIndex = 0,
    this.initialSectionId,
    this.initialParagraphIndex = -1,
  }) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  String? _readingSectionId;
  int _initialParagraphIndex = -1;
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
        _openReader(
          widget.initialSectionId!,
          paragraphIndex: widget.initialParagraphIndex,
          replace: true,
        );
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
      setState(() {
        _readingSectionId = parsed.sectionId;
        _initialParagraphIndex = parsed.paragraphIndex;
      });
    } else {
      setState(() {
        _readingSectionId = null;
        _initialParagraphIndex = -1;
        _currentIndex = parsed.tabIndex;
      });
    }
  }

  void _syncUrlWithCurrentState({bool replace = false}) {
    final url = SeoRouter.getTabUrl(_currentIndex, _storage.isEnglish);
    final title = SeoRouter.getTabTitle(_currentIndex, _storage.isEnglish);
    SeoService.updateUrl(url, title: title, replace: replace);
  }

  void _syncUrlForReader(String sectionId, {int paragraphIndex = -1, bool replace = false}) {
    final url = SeoRouter.getReaderUrl(
      sectionId,
      _storage.isEnglish,
      paragraphIndex: paragraphIndex >= 0 ? paragraphIndex : null,
    );
    final sec = BookRepository().getSectionById(sectionId);
    final title = SeoRouter.getReaderTitle(
      sec != null ? sec.getTitle(_storage.isEnglish) : sectionId,
      _storage.isEnglish,
    );
    final paras = sec?.getParagraphs(_storage.isEnglish) ?? [];
    final desc = (paragraphIndex >= 0 && paragraphIndex < paras.length)
        ? paras[paragraphIndex]
        : (paras.isNotEmpty ? paras.first : '');
    final img = sec?.image;
    SeoService.updateUrl(url, title: title, description: desc, image: img, replace: replace);
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
    setState(() {
      _readingSectionId = null;
      _initialParagraphIndex = -1;
      _currentIndex = idx;
    });
    _syncUrlWithCurrentState(replace: false);
  }

  void _openReader(String sectionId, {int paragraphIndex = -1, bool replace = false}) {
    setState(() {
      _readingSectionId = sectionId;
      _initialParagraphIndex = paragraphIndex;
    });
    _syncUrlForReader(sectionId, paragraphIndex: paragraphIndex, replace: replace);
  }

  void _downloadAndroidApk() {
    downloadFile('https://khoahoctamlinh.vn/app/KhoaHocTamLinh.apk');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_storage.isEnglish
            ? 'Downloading Android APK from khoahoctamlinh.vn/app/KhoaHocTamLinh.apk'
            : 'Đang tải về bộ cài Android từ khoahoctamlinh.vn/app/KhoaHocTamLinh.apk'),
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
        onOpenSection: _openReader,
      ),
      TocScreen(
        onOpenSection: _openReader,
      ),
      const PodcastScreen(),
      const NotesScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    final Widget currentBody = _readingSectionId != null
        ? ReaderScreen(
            sectionId: _readingSectionId!,
            initialParagraphIndex: _initialParagraphIndex,
            onBack: () {
              setState(() {
                _readingSectionId = null;
                _initialParagraphIndex = -1;
              });
              _syncUrlWithCurrentState(replace: false);
            },
          )
        : screens[_currentIndex];

    final bool showTtsMiniBar = isTtsActive && _readingSectionId == null;

    if (isDesktopWeb) {
      // Desktop / Web Layout with Top Header Navigation
      return Scaffold(
        body: Column(
          children: [
            // Top Website Navigation Header
            _buildWebHeader(isEnglish, isDark),

            // Active Screen Content
            Expanded(
              child: currentBody,
            ),

            // Mini-player bar if TTS or Audio is active
            if (showTtsMiniBar) _buildTtsMiniBar(isEnglish, isDark),
            if (!isTtsActive && isAudioActive) _buildAudioMiniBar(isEnglish, isDark),
          ],
        ),
      );
    }

    // Mobile Phone Layout with Bottom Navigation Bar
    return Scaffold(
      body: currentBody,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini-player bar if TTS or Audio is active
          if (showTtsMiniBar) _buildTtsMiniBar(isEnglish, isDark),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/app_logo_circle.webp',
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
                        isEnglish ? 'Journey to Rediscover Yourself' : 'Hành trình tìm lại chính mình',
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
            onPressed: () async {
              final newMode = isDark ? 'light' : 'dark';
              await _storage.setThemeMode(newMode);
              if (mounted) setState(() {});
              widget.onThemeChanged();
            },
          ),

          const SizedBox(width: 8),

          // Account / Cloud Sync Button
          ListenableBuilder(
            listenable: FirebaseSyncService(),
            builder: (context, _) {
              final sync = FirebaseSyncService();
              final isLoggedIn = sync.isLoggedIn;
              final user = sync.currentUser;
              final photoUrl = user?.photoURL;
              final displayName = user?.displayName;

              if (isLoggedIn) {
                return InkWell(
                  onTap: () => showAppAuthDialog(context, isDark: isDark, isEnglish: isEnglish),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF272C3E) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary,
                          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? const Icon(Icons.person, size: 14, color: Colors.black87)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            displayName ?? (isEnglish ? 'Synced' : 'Đã Đồng Bộ'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.cloud_done, size: 14, color: Colors.green),
                      ],
                    ),
                  ),
                );
              }

              return OutlinedButton.icon(
                onPressed: () => showAppAuthDialog(context, isDark: isDark, isEnglish: isEnglish),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryDark.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.account_circle_outlined, size: 18, color: AppColors.primaryDark),
                label: Text(
                  isEnglish ? 'Sign In' : 'Đăng Nhập',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primaryDark),
                ),
              );
            },
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
                  _openReader(_tts.currentSectionId);
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
                    _tts.currentIndex == -1
                        ? (isEnglish ? 'Chapter Title' : 'Tiêu đề chương')
                        : (isEnglish ? 'Paragraph ${_tts.currentIndex + 1}' : 'Đoạn ${_tts.currentIndex + 1}'),
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
