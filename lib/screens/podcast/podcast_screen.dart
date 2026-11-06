import 'package:flutter/material.dart';
import '../../models/podcast_item.dart';
import '../../routes/seo_router.dart';
import '../../services/book_repository.dart';
import '../../services/audio_player_service.dart';
import '../../services/seo/seo_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';

class PodcastScreen extends StatefulWidget {
  const PodcastScreen({Key? key}) : super(key: key);

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  final BookRepository _repo = BookRepository();
  final AudioPlayerService _player = AudioPlayerService();
  final StorageService _storage = StorageService();

  late bool _isEnglish;
  String _selectedFilter = 'all';

  List<PodcastItem> _getFilteredPods() {
    if (_selectedFilter == 'vi') return _repo.podcasts.where((p) => p.language == 'vi').toList();
    if (_selectedFilter == 'en') return _repo.podcasts.where((p) => p.language == 'en').toList();
    return _repo.podcasts;
  }

  @override
  void initState() {
    super.initState();
    _isEnglish = _storage.isEnglish;
    _player.addListener(_onPlayerStateChanged);
    _storage.isEnglishNotifier.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerStateChanged);
    _storage.isEnglishNotifier.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) {
      setState(() {
        _isEnglish = _storage.isEnglish;
      });
    }
  }

  void _onPlayerStateChanged() {
    if (mounted) setState(() {});
  }

  void _toggleLanguage() async {
    final next = !_isEnglish;
    await _storage.setIsEnglish(next);
    await TtsService().setLanguage(next);
    setState(() {
      _isEnglish = next;
    });
    SeoService.updateUrl(
      SeoRouter.getTabUrl(2, next),
      title: SeoRouter.getTabTitle(2, next),
      replace: false,
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;
    final pods = _getFilteredPods();
    final current = _player.currentPodcast;

    if (isDesktopWeb) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                // Desktop Web Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnglish ? 'HEALING AUDIO & PODCASTS' : 'SÁCH NÓI & PODCAST CHỮA LÀNH',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isEnglish ? 'Voices of Stillness' : 'Thanh Âm Tỉnh Thức',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF0EBE0) : const Color(0xFF1B1E28),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isEnglish
                              ? '12 mindful podcast episodes • High quality studio audio • Bilingual VI & EN'
                              : '12 tập podcast sâu sắc • Giọng đọc truyền cảm, âm nhạc thư giãn • Song ngữ Việt - Anh',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    // Language filters
                    Row(
                      children: [
                        _buildFilterChip('all', _isEnglish ? 'All (12)' : 'Tất cả (12)', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('vi', _isEnglish ? '🇻🇳 Vietnamese (7)' : '🇻🇳 Tiếng Việt (7)', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('en', _isEnglish ? '🇬🇧 English (5)' : '🇬🇧 English (5)', isDark),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Active player card
                if (current != null) ...[
                  _buildPlayerCard(current, isDark),
                  const SizedBox(height: 28),
                ],

                // Grid of tracks
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: pods.length,
                  itemBuilder: (context, idx) {
                    return _buildTrackCard(pods[idx], current, isDark);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile Phone Layout
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEnglish ? 'Podcasts & Healing Audio' : 'Sách Nói & Podcast Chữa Lành',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isEnglish ? '🇬🇧' : '🇻🇳',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEnglish ? 'EN' : 'VI',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (All / Vietnamese / English)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _buildFilterChip('all', _isEnglish ? 'All (12)' : 'Tất cả (12)', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('vi', _isEnglish ? '🇻🇳 Vietnamese (7)' : '🇻🇳 Tiếng Việt (7)', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('en', _isEnglish ? '🇬🇧 English (5)' : '🇬🇧 English (5)', isDark),
              ],
            ),
          ),

          // If a podcast is playing/active, show player card
          if (current != null) _buildPlayerCard(current, isDark),

          // List of tracks
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                return _buildTrackCard(pods[idx], current, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(PodcastItem p, PodcastItem? current, bool isDark) {
    final isSelected = current?.id == p.id;
    final isPlaying = isSelected && _player.state == AudioPlayState.playing;

    return InkWell(
      onTap: () => _player.playPodcast(p),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.06)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                p.image ?? 'assets/images/image1.jpg',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.getCategory(_isEnglish),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.getTitle(_isEnglish),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isSelected ? AppColors.primaryDark : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.author} • ${p.duration}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: AppColors.primary,
                size: 36,
              ),
              onPressed: () {
                if (isSelected) {
                  if (isPlaying) {
                    _player.pause();
                  } else {
                    _player.resume();
                  }
                } else {
                  _player.playPodcast(p);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(PodcastItem p, bool isDark) {
    final pos = _player.position;
    final dur = _player.duration;
    final maxSec = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
    final curSec = pos.inSeconds.toDouble().clamp(0.0, maxSec);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2E3444), const Color(0xFF1D212C)]
              : [const Color(0xFFFFFDF8), const Color(0xFFF6ECE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  p.image ?? 'assets/images/image1.jpg',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEnglish ? 'NOW PLAYING' : 'ĐANG PHÁT AUDIO',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.getTitle(_isEnglish),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      p.author,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.bedtime,
                  color: _player.sleepMinutesRemaining > 0 ? AppColors.primary : AppColors.textMuted,
                ),
                tooltip: _player.sleepMinutesRemaining > 0
                    ? (_isEnglish ? 'Timer: ${_player.sleepMinutesRemaining}m' : 'Hẹn giờ: ${_player.sleepMinutesRemaining}p')
                    : (_isEnglish ? 'Sleep timer' : 'Hẹn giờ tắt'),
                onPressed: _showSleepDialog,
              ),
            ],
          ),

          // Slider
          Slider(
            value: curSec,
            min: 0.0,
            max: maxSec,
            activeColor: isDark ? const Color(0xFFE5B968) : AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.2),
            onChanged: (val) {
              _player.seek(Duration(seconds: val.toInt()));
            },
          ),

          // Duration labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(pos), style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted)),
                Text(_formatDuration(dur), style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted)),
              ],
            ),
          ),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final newPos = (pos - const Duration(seconds: 10));
                  _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 48,
                color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                icon: Icon(
                  _player.state == AudioPlayState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                ),
                onPressed: () {
                  if (_player.state == AudioPlayState.playing) {
                    _player.pause();
                  } else {
                    _player.resume();
                  }
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_30),
                onPressed: () {
                  final newPos = pos + const Duration(seconds: 30);
                  if (newPos < dur) _player.seek(newPos);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSleepDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isEnglish ? 'Sleep Timer' : 'Hẹn Giờ Tắt Nhạc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(_isEnglish ? '15 minutes' : '15 phút'),
                onTap: () {
                  _player.setSleepTimer(15);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_isEnglish ? '30 minutes' : '30 phút'),
                onTap: () {
                  _player.setSleepTimer(30);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_isEnglish ? '60 minutes' : '60 phút'),
                onTap: () {
                  _player.setSleepTimer(60);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_isEnglish ? 'Turn off timer' : 'Tắt hẹn giờ'),
                onTap: () {
                  _player.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSel = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }
}
