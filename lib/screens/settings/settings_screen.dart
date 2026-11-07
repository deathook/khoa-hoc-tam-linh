import 'package:flutter/material.dart';
import '../../routes/seo_router.dart';
import '../../services/book_repository.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/seo/seo_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const SettingsScreen({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final TtsService _tts = TtsService();
  final ImageCacheService _imageCache = ImageCacheService();
  final BookRepository _repo = BookRepository();

  late bool _isEnglish;
  late double _ttsSpeedMult;
  late double _ttsPitch;
  late String _themeMode;
  late String _chapterMode;

  List<Map<String, String>> _availableVoices = [];
  bool _isLoadingVoices = false;

  int _cachedImagesCount = 0;
  double _cachedSizeMB = 0.0;
  bool _isDownloadingAll = false;
  int _downloadCompleted = 0;
  int _downloadTotal = 0;
  bool _isCancelRequested = false;

  @override
  void initState() {
    super.initState();
    _isEnglish = _storage.isEnglish;
    _ttsSpeedMult = _storage.ttsSpeedMultiplier;
    _ttsPitch = _storage.ttsPitch;
    _themeMode = _storage.themeMode;
    _chapterMode = _storage.autoNextChapterMode;
    _loadDeviceVoices();
    _refreshCacheInfo();
    FirebaseSyncService().addListener(_onSyncUpdated);
  }

  @override
  void dispose() {
    FirebaseSyncService().removeListener(_onSyncUpdated);
    super.dispose();
  }

  void _onSyncUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshCacheInfo() async {
    final count = await _imageCache.getCachedImageCount();
    final size = await _imageCache.getCachedSizeMB();
    if (mounted) {
      setState(() {
        _cachedImagesCount = count;
        _cachedSizeMB = size;
      });
    }
  }

  void _startDownloadAllImages() async {
    final sections = _repo.sections;
    final urls = sections
        .map((s) => s.getImageVertical(_isEnglish))
        .where((u) => u != null && u.isNotEmpty && u.startsWith('http'))
        .cast<String>()
        .toList();

    if (urls.isEmpty) return;

    setState(() {
      _isDownloadingAll = true;
      _downloadCompleted = 0;
      _downloadTotal = urls.length;
      _isCancelRequested = false;
    });

    await _imageCache.prefetchAllImages(
      urls: urls,
      onProgress: (completed, total) {
        if (mounted) {
          setState(() {
            _downloadCompleted = completed;
            _downloadTotal = total;
          });
        }
      },
      isCancelled: () => _isCancelRequested,
    );

    await _refreshCacheInfo();
    if (mounted) {
      setState(() {
        _isDownloadingAll = false;
        _isCancelRequested = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglish
              ? 'Images downloaded! Ready for full offline reading.'
              : 'Đã tải xong ảnh! Bạn có thể xem sách hoàn toàn offline.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _clearImageCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isEnglish ? 'Clear Image Cache?' : 'Xóa bộ nhớ đệm ảnh?'),
        content: Text(_isEnglish
            ? 'Downloaded illustrations will be removed. They will reload when you are online.'
            : 'Toàn bộ hình ảnh minh họa đã tải sẽ được dọn dẹp để giải phóng bộ nhớ. Khi mở lại chương có mạng ảnh sẽ tải lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text(_isEnglish ? 'Clear' : 'Xóa bộ nhớ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _imageCache.clearCache();
      await _refreshCacheInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEnglish ? 'Image cache cleared.' : 'Đã dọn dẹp bộ nhớ đệm hình ảnh.'),
          ),
        );
      }
    }
  }

  Future<void> _loadDeviceVoices() async {
    setState(() => _isLoadingVoices = true);
    final voices = await _tts.getAvailableVoices(_isEnglish);
    if (mounted) {
      setState(() {
        _availableVoices = voices;
        _isLoadingVoices = false;
      });
    }
  }

  void _testTtsVoice() async {
    final sampleText = _isEnglish
        ? 'When the mind is bright, all things are bright. This is a voice test.'
        : 'Khi tâm sáng, vạn vật sáng. Đây là giọng đọc thử nghiệm của máy.';
    await _tts.startReadingSection(
      sectionId: 'test',
      paragraphs: [sampleText],
      isEnglish: _isEnglish,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;

    final content = Scrollbar(
      thumbVisibility: true,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: isDesktopWeb ? 24 : 16, vertical: isDesktopWeb ? 32 : 16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktopWeb ? 820 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDesktopWeb) ...[
                    Text(
                      _isEnglish ? 'SYSTEM & PREFERENCES' : 'CÀI ĐẶT & HỆ THỐNG',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEnglish ? 'Preferences & Offline Storage' : 'Tùy Chọn Đọc Sách & Dữ Liệu',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF0EBE0) : const Color(0xFF1B1E28),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

        // Section: Language
        _buildSectionHeader(_isEnglish ? 'LANGUAGE / NGÔN NGỮ' : 'NGÔN NGỮ / LANGUAGE'),
          Row(
            children: [
              // Vietnamese Card
              Expanded(
                child: InkWell(
                  onTap: () async {
                    if (_isEnglish) {
                      await _storage.setIsEnglish(false);
                      await _tts.setLanguage(false);
                      setState(() => _isEnglish = false);
                      _loadDeviceVoices();
                      SeoService.updateUrl(
                        SeoRouter.getTabUrl(4, false),
                        title: SeoRouter.getTabTitle(4, false),
                        replace: false,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: !_isEnglish
                          ? AppColors.primary.withOpacity(0.12)
                          : (isDark ? AppColors.cardDark : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !_isEnglish ? AppColors.primary : Colors.grey.withOpacity(0.2),
                        width: !_isEnglish ? 2 : 1,
                      ),
                      boxShadow: [
                        if (!_isEnglish)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🇻🇳',
                          style: TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Tiếng Việt',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (!_isEnglish) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, size: 16, color: AppColors.primaryDark),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEnglish ? 'Original Edition' : 'Bản gốc tác giả',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // English Card
              Expanded(
                child: InkWell(
                  onTap: () async {
                    if (!_isEnglish) {
                      await _storage.setIsEnglish(true);
                      await _tts.setLanguage(true);
                      setState(() => _isEnglish = true);
                      _loadDeviceVoices();
                      SeoService.updateUrl(
                        SeoRouter.getTabUrl(4, true),
                        title: SeoRouter.getTabTitle(4, true),
                        replace: false,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _isEnglish
                          ? AppColors.primary.withOpacity(0.12)
                          : (isDark ? AppColors.cardDark : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isEnglish ? AppColors.primary : Colors.grey.withOpacity(0.2),
                        width: _isEnglish ? 2 : 1,
                      ),
                      boxShadow: [
                        if (_isEnglish)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🇬🇧',
                          style: TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'English',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (_isEnglish) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, size: 16, color: AppColors.primaryDark),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEnglish ? 'UK Edition' : 'Bản tiếng Anh',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Section: Reading Theme
          _buildSectionHeader(_isEnglish ? 'READING THEME' : 'GIAO DIỆN ĐỌC SÁCH'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnglish ? 'Color Mode' : 'Chế độ màu nền',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeOption('light', _isEnglish ? 'Light' : 'Sáng', Colors.white, Colors.black87),
                      _buildThemeOption('sepia', _isEnglish ? 'Sepia' : 'Vàng Ấm', AppColors.sepiaBg, AppColors.textSepia),
                      _buildThemeOption('dark', _isEnglish ? 'Dark' : 'Đêm', AppColors.darkBg, AppColors.textLight),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: Firebase Cloud Sync
          _buildCloudSyncSection(isDark),

          const SizedBox(height: 16),

          // Section: TTS Settings
          _buildSectionHeader(_isEnglish ? 'VOICE READING (TTS)' : 'SÁCH NÓI / GIỌNG ĐỌC MÁY (TTS)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test Voice button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEnglish ? 'Playback Speed:' : 'Tốc độ đọc sách nói:',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.volume_up, size: 16, color: AppColors.primary),
                        label: Text(
                          _isEnglish ? 'Test Voice' : 'Nghe Thử Giọng',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _testTtsVoice,
                      ),
                    ],
                  ),

                  // Speed Choice Chips (0.5x, 0.75x, 1x, 1.25x, 1.5x, 1.75x, 2x)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TtsService.availableSpeeds.map((s) {
                      final isSel = _ttsSpeedMult == s;
                      return ChoiceChip(
                        label: Text('${s}x'),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) async {
                          if (val) {
                            setState(() => _ttsSpeedMult = s);
                            await _tts.setSpeedMultiplier(s);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const Divider(height: 28),

                  // End of Chapter Behaviour
                  Text(
                    _isEnglish ? 'When chapter reading finishes:' : 'Khi đọc hết một chương:',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _chapterMode,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'next',
                        child: Text(_isEnglish ? 'Auto-play next chapter (Default)' : 'Tự động chuyển chương tiếp theo (Mặc định)'),
                      ),
                      DropdownMenuItem(
                        value: 'repeat',
                        child: Text(_isEnglish ? 'Repeat this chapter' : 'Lặp lại chương này'),
                      ),
                      DropdownMenuItem(
                        value: 'stop',
                        child: Text(_isEnglish ? 'Stop at end of chapter' : 'Dừng khi hết chương'),
                      ),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _chapterMode = val);
                        await _storage.setAutoNextChapterMode(val);
                      }
                    },
                  ),

                  const Divider(height: 28),

                  // Voice Pitch (Nam / Nữ / Tùy chỉnh)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEnglish ? 'Tone / Voice Pitch:' : 'Tông giọng (Nam / Nữ):',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      Text(
                        _ttsPitch < 0.95
                            ? (_isEnglish ? 'Deep Warm (Male)' : 'Trầm ấm (Nam)')
                            : (_ttsPitch > 1.05
                                ? (_isEnglish ? 'Soft High (Female)' : 'Cao thanh (Nữ)')
                                : (_isEnglish ? 'Natural Balanced' : 'Cân bằng')),
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPitchOption(
                          pitch: 0.85,
                          label: _isEnglish ? 'Male (0.85)' : 'Giọng Nam (0.85)',
                          isSelected: (_ttsPitch - 0.85).abs() < 0.05,
                          onTap: () async {
                            setState(() => _ttsPitch = 0.85);
                            await _tts.setPitch(0.85);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPitchOption(
                          pitch: 1.0,
                          label: _isEnglish ? 'Standard (1.0)' : 'Chuẩn (1.0)',
                          isSelected: (_ttsPitch - 1.0).abs() < 0.05,
                          onTap: () async {
                            setState(() => _ttsPitch = 1.0);
                            await _tts.setPitch(1.0);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPitchOption(
                          pitch: 1.15,
                          label: _isEnglish ? 'Female (1.15)' : 'Giọng Nữ (1.15)',
                          isSelected: (_ttsPitch - 1.15).abs() < 0.05,
                          onTap: () async {
                            setState(() => _ttsPitch = 1.15);
                            await _tts.setPitch(1.15);
                          },
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _ttsPitch,
                    min: 0.7,
                    max: 1.4,
                    divisions: 7,
                    activeColor: AppColors.secondary,
                    onChanged: (val) {
                      setState(() => _ttsPitch = val);
                    },
                    onChangeEnd: (val) async {
                      await _tts.setPitch(val);
                    },
                  ),

                  // Available voices list on Android device
                  if (_availableVoices.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      _isEnglish ? 'Select Voice Engine on Device:' : 'Chọn Giọng máy đã cài trên điện thoại:',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _storage.getVoiceName(_isEnglish) ?? (_availableVoices.isNotEmpty ? _availableVoices.first['name'] : null),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _availableVoices.map((v) {
                        return DropdownMenuItem<String>(
                          value: v['name'],
                          child: Text(
                            v['displayName'] ?? v['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          final v = _availableVoices.firstWhere((item) => item['name'] == val);
                          await _tts.setVoice(v);
                          setState(() {});
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 10),
                  Text(
                    _isEnglish
                        ? 'TTS runs directly using your device engine. 100% offline, free forever.'
                        : 'Sách nói sử dụng trực tiếp bộ đọc có sẵn của máy Android, hoàn toàn miễn phí và không tốn 3G/4G.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: Offline Image Cache
          _buildSectionHeader(_isEnglish ? 'OFFLINE IMAGES & STORAGE' : 'BỘ NHỚ & TẢI ẢNH ĐỌC OFFLINE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_download, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnglish ? 'Cached Illustrations' : 'Hình ảnh minh họa đã lưu',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEnglish
                                  ? '$_cachedImagesCount images (${_cachedSizeMB.toStringAsFixed(1)} MB)'
                                  : 'Đã lưu: $_cachedImagesCount ảnh (${_cachedSizeMB.toStringAsFixed(1)} MB)',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isEnglish
                        ? 'Images are automatically downloaded and cached when you open chapters. You can also download all 158 illustrations at once to read offline without internet.'
                        : 'Khi bạn đọc từng chương, ứng dụng sẽ tự động tải và lưu ảnh vào bộ nhớ máy để lần sau mở lại không cần internet. Bạn cũng có thể tải sẵn toàn bộ 158 ảnh minh họa tại đây.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  if (_isDownloadingAll) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _downloadTotal > 0 ? _downloadCompleted / _downloadTotal : null,
                        minHeight: 8,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEnglish
                              ? 'Downloading: $_downloadCompleted / $_downloadTotal'
                              : 'Đang tải: $_downloadCompleted / $_downloadTotal ảnh...',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _isCancelRequested = true);
                          },
                          child: Text(
                            _isEnglish ? 'Cancel' : 'Dừng lại',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startDownloadAllImages,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(_isEnglish ? 'Download All (Offline)' : 'Tải toàn bộ 158 ảnh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        if (_cachedImagesCount > 0) ...[
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: _clearImageCache,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: Text(_isEnglish ? 'Clear' : 'Xóa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: About Book & Author
          _buildSectionHeader(_isEnglish ? 'ABOUT THE BOOK & AUTHOR' : 'THÔNG TIN TÁC PHẨM & TÁC GIẢ'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/image1.webp',
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Khoa Học Tâm Linh',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'The Science of Spirituality',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isEnglish ? 'Author: Hoang Nhat Minh' : 'Tác giả: Hoàng Nhật Minh',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primaryDark),
                            ),
                            Text(
                              _isEnglish ? 'Da Lat 10/2025' : 'Đà Lạt 10/2025',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    _isEnglish
                        ? '“When the mind is bright, all things are bright.”\nThis book is a simple encounter between the two halves of the human being: the material half that longs to understand the world, and the spiritual half that longs to understand itself.'
                        : '“Khi tâm sáng, vạn vật sáng.”\nCuốn sách là cuộc gặp gỡ giản dị giữa hai nửa của con người: nửa vật chất - muốn hiểu thế giới, và nửa tinh thần - muốn hiểu chính mình.',
                    style: const TextStyle(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.public, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'Website: https://khoahoctamlinh.vn',
                        style: TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'Email: khoahoctamlinh.vn@gmail.com',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _isEnglish ? 'Version 1.0.0 (Android Native App)' : 'Phiên bản 1.0.0 (Android Native App)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktopWeb) {
      return Scaffold(
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/app_logo_circle.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isEnglish ? 'Settings & About' : 'Cài Đặt & Giới Thiệu',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildThemeOption(String mode, String label, Color bg, Color textCol) {
    final isSelected = _themeMode == mode;
    return InkWell(
      onTap: () async {
        await _storage.setThemeMode(mode);
        setState(() => _themeMode = mode);
        widget.onThemeChanged();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(color: textCol, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildPitchOption({
    required double pitch,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.15) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primaryDark : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatItem(IconData icon, String value, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCloudSyncSection(bool isDark) {
    final sync = FirebaseSyncService();
    final isLoggedIn = sync.isLoggedIn;
    final user = sync.currentUser;
    final hlCount = _storage.getHighlights().length;
    final notesCount = _storage.getNotes().length;
    final bmCount = _storage.getBookmarks().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_isEnglish ? 'FIREBASE CLOUD SYNC' : 'ĐỒNG BỘ ĐÁM MÂY (FIREBASE)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isLoggedIn
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.blueGrey.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLoggedIn ? Icons.cloud_done : Icons.cloud_queue,
                        color: isLoggedIn ? AppColors.primaryDark : Colors.blueGrey,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isLoggedIn
                                    ? (_isEnglish ? 'Cloud Connected' : 'Đã kết nối đám mây')
                                    : (_isEnglish ? 'Offline / Local Storage' : 'Lưu trữ trên thiết bị'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLoggedIn ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isLoggedIn
                                      ? (_isEnglish ? 'ONLINE' : 'ĐÃ ĐỒNG BỘ')
                                      : (_isEnglish ? 'LOCAL' : 'CỤC BỘ'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isLoggedIn ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isLoggedIn
                                ? (user?.email ?? (_isEnglish ? 'Anonymous User' : 'Tài khoản khách'))
                                : (_isEnglish
                                    ? 'Highlights & notes are stored locally'
                                    : 'Dữ liệu tô màu, ghi chú đang lưu trên máy này'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Data stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSyncStatItem(
                        Icons.brush,
                        '$hlCount',
                        _isEnglish ? 'Highlights' : 'Tô màu',
                        isDark,
                      ),
                      Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.2)),
                      _buildSyncStatItem(
                        Icons.edit_note,
                        '$notesCount',
                        _isEnglish ? 'Notes' : 'Ghi chú',
                        isDark,
                      ),
                      Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.2)),
                      _buildSyncStatItem(
                        Icons.bookmark_border,
                        '$bmCount',
                        _isEnglish ? 'Bookmarks' : 'Dấu trang',
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle / explanation
                Text(
                  _isEnglish
                      ? 'Syncs highlights, personal notes, bookmarks, and reading progress across Web & Android App (Package: com.khtl.app).'
                      : 'Tự động đồng bộ các đoạn tô màu, ghi chú, đánh dấu chương và vị trí đang đọc dở giữa Web và ứng dụng Android (Mã app: com.khtl.app).',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 14),

                // Action buttons
                if (isLoggedIn)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await sync.syncLocalToCloud();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isEnglish
                                        ? 'Data synced with Cloud Firestore!'
                                        : 'Đã đồng bộ dữ liệu lên Firebase Cloud Firestore thành công!'),
                                    backgroundColor: AppColors.primaryDark,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi đồng bộ: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.sync, size: 18),
                          label: Text(_isEnglish ? 'Sync Now' : 'Đồng Bộ Ngay'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await sync.signOut();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isEnglish ? 'Signed out' : 'Đã đăng xuất tài khoản đám mây'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(_isEnglish ? 'Sign Out' : 'Đăng xuất'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAuthDialog(isDark),
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(_isEnglish
                          ? 'Sign In / Register Cloud Account'
                          : 'Đăng Nhập / Tạo Tài Khoản Đồng Bộ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAuthDialog(bool isDark) {
    final messenger = ScaffoldMessenger.of(context);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool isRegister = false;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final sync = FirebaseSyncService();
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E2230) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.cloud_sync, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRegister
                        ? (_isEnglish ? 'Create Cloud Account' : 'Tạo Tài Khoản Mới')
                        : (_isEnglish ? 'Sign In Cloud' : 'Đăng Nhập Đám Mây'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEnglish
                        ? 'Keep your highlights, bookmarks, and notes in sync across web and mobile.'
                        : 'Lưu và đồng bộ dữ liệu tô màu, ghi chú, đánh dấu giữa điện thoại và máy tính.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                  if (isRegister) ...[
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: _isEnglish ? 'Display Name' : 'Họ và tên',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isEnglish ? 'Password' : 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            final pass = passwordController.text;
                            if (email.isEmpty || pass.isEmpty) {
                              setDialogState(() {
                                errorMessage = _isEnglish
                                    ? 'Please enter email and password'
                                    : 'Vui lòng nhập đầy đủ email và mật khẩu';
                              });
                              return;
                            }
                            setDialogState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            try {
                              if (isRegister) {
                                await sync.registerWithEmail(
                                  email,
                                  pass,
                                  displayName: nameController.text.trim(),
                                );
                              } else {
                                await sync.signInWithEmail(email, pass);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(_isEnglish
                                        ? 'Successfully connected to Cloud Sync!'
                                        : 'Đã kết nối tài khoản đám mây thành công!'),
                                    backgroundColor: AppColors.primaryDark,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() {
                                isLoading = false;
                                errorMessage = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : Text(
                            isRegister
                                ? (_isEnglish ? 'Register Account' : 'Tạo Tài Khoản Mới')
                                : (_isEnglish ? 'Sign In' : 'Đăng Nhập'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setDialogState(() {
                              isRegister = !isRegister;
                              errorMessage = null;
                            });
                          },
                    child: Text(
                      isRegister
                          ? (_isEnglish ? 'Already have an account? Sign in' : 'Đã có tài khoản? Bấm để Đăng nhập')
                          : (_isEnglish ? 'Need an account? Register here' : 'Chưa có tài khoản? Bấm để Tạo mới'),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  const Divider(height: 24),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setDialogState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            try {
                              await sync.signInAnonymously();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(_isEnglish
                                        ? 'Signed in as Guest. Data is syncing!'
                                        : 'Đã đăng nhập tài khoản Khách. Dữ liệu đang được đồng bộ!'),
                                    backgroundColor: AppColors.primaryDark,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() {
                                isLoading = false;
                                errorMessage = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: Text(_isEnglish
                        ? 'Quick Guest Sync (No password)'
                        : 'Đăng nhập Nhanh / Khách (Không cần mật khẩu)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_isEnglish ? 'Close' : 'Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }
}
