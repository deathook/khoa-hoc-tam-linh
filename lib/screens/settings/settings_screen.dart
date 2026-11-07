import 'package:flutter/material.dart';
import '../../routes/seo_router.dart';
import '../../services/book_repository.dart';
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
                          'assets/images/image1.jpg',
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
        title: Text(
          _isEnglish ? 'Settings & About' : 'Cài Đặt & Giới Thiệu',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
}
