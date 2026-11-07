import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/quote_item.dart';
import '../../routes/seo_router.dart';
import '../../services/book_repository.dart';
import '../../services/seo/seo_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/web_download.dart';
import '../reader/reader_screen.dart';
import '../search/search_screen.dart';
import '../../services/firebase_sync_service.dart';
import '../../widgets/auth_dialog.dart';
import '../../widgets/quote_card_dialog.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenAudio;
  final Function(String sectionId)? onOpenSection;

  const HomeScreen({
    Key? key,
    required this.onOpenLibrary,
    required this.onOpenAudio,
    this.onOpenSection,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookRepository _repo = BookRepository();
  final StorageService _storage = StorageService();
  final ScrollController _scrollController = ScrollController();

  late bool _isEnglish;
  QuoteItem? _currentQuote;

  @override
  void initState() {
    super.initState();
    _isEnglish = _storage.isEnglish;
    _storage.isEnglishNotifier.addListener(_onLangChanged);
    _setDailyQuote();
  }

  @override
  void dispose() {
    _storage.isEnglishNotifier.removeListener(_onLangChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) {
      setState(() {
        _isEnglish = _storage.isEnglish;
      });
    }
  }

  void _setDailyQuote({bool randomize = false}) {
    if (_repo.quotes.isEmpty) return;
    if (randomize) {
      final rand = Random();
      setState(() {
        _currentQuote = _repo.quotes[rand.nextInt(_repo.quotes.length)];
      });
    } else {
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final dailyIndex = (dayOfYear + now.year) % _repo.quotes.length;
      setState(() {
        _currentQuote = _repo.quotes[dailyIndex];
      });
    }
  }

  void _toggleLanguage() async {
    final next = !_isEnglish;
    await _storage.setIsEnglish(next);
    await TtsService().setLanguage(next);
    setState(() {
      _isEnglish = next;
    });
    SeoService.updateUrl(
      SeoRouter.getTabUrl(0, next),
      title: SeoRouter.getTabTitle(0, next),
      replace: false,
    );
  }

  void _openSection(String sectionId) {
    if (widget.onOpenSection != null) {
      widget.onOpenSection!(sectionId);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(sectionId: sectionId),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
        SeoService.updateUrl(
          SeoRouter.getTabUrl(0, _isEnglish),
          title: SeoRouter.getTabTitle(0, _isEnglish),
          replace: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;

    final lastReadId = _storage.lastReadSectionId ?? 'preface';
    final lastReadTitle = _storage.lastReadSectionTitle ?? (_isEnglish ? 'Preface' : 'Lời Mở Đầu');

    return Scaffold(
      appBar: isDesktopWeb
          ? null
          : AppBar(
              titleSpacing: 12,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
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
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/app_logo_circle.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isEnglish ? 'The Science of Spirituality' : 'Khoa Học Tâm Linh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isEnglish ? 'Hoang Nhat Minh' : 'Hoàng Nhật Minh',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Language Switcher
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: _isEnglish ? 'Search book' : 'Tìm kiếm trong sách',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),
                ListenableBuilder(
                  listenable: FirebaseSyncService(),
                  builder: (context, _) {
                    final sync = FirebaseSyncService();
                    final isLoggedIn = sync.isLoggedIn;
                    final photoUrl = sync.currentUser?.photoURL;
                    return IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (isLoggedIn && photoUrl != null && photoUrl.isNotEmpty)
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(photoUrl),
                            )
                          else
                            Icon(
                              isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                              size: 24,
                              color: isLoggedIn ? AppColors.primaryDark : null,
                            ),
                          if (isLoggedIn)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1B1E28) : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      tooltip: _isEnglish ? 'Cloud Sync & Account' : 'Tài khoản & Đồng bộ đám mây',
                      onPressed: () => showAppAuthDialog(context, isDark: isDark, isEnglish: _isEnglish),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          _setDailyQuote(randomize: true);
          setState(() {});
        },
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktopWeb ? 24 : 16,
              vertical: isDesktopWeb ? 24 : 12,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktopWeb ? 1180 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Desktop Web Hero Banner OR Mobile Daily Quote
                      if (isDesktopWeb) ...[
                        _buildDesktopHero(isDark),
                        const SizedBox(height: 16),
                      ] else if (_currentQuote != null) ...[
                        _buildDailyQuoteCard(isDark),
                        const SizedBox(height: 16),
                      ],

                      // Continue Reading Banner
                      _buildContinueReadingCard(lastReadId, lastReadTitle, isDark),

                      const SizedBox(height: 28),

                      // Main Book Categorized Sections
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEnglish ? 'Explore Book Categories' : 'Khám Phá Các Tầng Bậc Cuốn Sách',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.onOpenLibrary,
                            icon: const Icon(Icons.menu_book, size: 16),
                            label: Text(_isEnglish ? 'Full Table of Contents (173)' : 'Toàn Bộ Mục Lục (173)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Category Grid (4 columns on desktop, 2 on mobile)
                      _buildCategoryGrid(isDesktopWeb),

                      const SizedBox(height: 32),

                      // Featured Healing Podcasts / Audio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEnglish ? 'Featured Audio & Healing Podcasts' : 'Sách Nói & Podcast Chữa Lành Nổi Bật',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.onOpenAudio,
                            icon: const Icon(Icons.podcasts, size: 16),
                            label: Text(_isEnglish ? 'Listen All (12)' : 'Nghe Tất Cả (12)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildPodcastRow(isDesktopWeb),

                      // Website Footer on Web
                      if (isDesktopWeb) _buildWebFooter(isDark),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHero(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2432), const Color(0xFF11141C)]
              : [const Color(0xFFFFFDF8), const Color(0xFFF7EEDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFFE5B968).withOpacity(0.4) : AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Column: Hero Text & CTAs
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        _isEnglish
                            ? 'SPIRITUAL SCIENCE & CONSCIOUSNESS • HOANG NHAT MINH'
                            : 'KHOA HỌC TÂM LINH & Ý THỨC • HOÀNG NHẬT MINH',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isEnglish ? 'The Science of Spirituality' : 'Khoa Học & Tâm Linh',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    height: 1.2,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isEnglish
                      ? 'Two Languages of One Ultimate Truth'
                      : 'Hai ngôn ngữ của cùng một chân lý duy nhất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isEnglish
                      ? 'An inspiring journey bridging modern quantum mechanics, consciousness research, and ancient enlightenment. Discover the profound unity of mind, soul, and universe.'
                      : 'Cuộc gặp gỡ giản dị giữa hai nửa con người: Nửa vật chất muốn hiểu thế giới, và nửa tinh thần muốn tìm lại chính mình. Tác phẩm đúc kết 19 chương sách chuyên sâu kết hợp cùng 55 khai thị giải ngộ và 44 tầng chuyển hóa nội tâm.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openSection('ch_01'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFE5B968) : AppColors.primary,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: Text(
                        _isEnglish ? 'Start Reading Chapter 1' : 'Bắt Đầu Đọc Chương 1',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onOpenAudio,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        side: BorderSide(color: isDark ? const Color(0xFFE5B968) : AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(Icons.podcasts, size: 18, color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark),
                      label: Text(
                        _isEnglish ? 'Healing Podcasts' : 'Nghe Podcasts Chữa Lành',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => downloadFile('https://khoahoctamlinh.vn/app/KhoaHocTamLinh.apk'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        side: BorderSide(color: isDark ? AppColors.cardDarkBorder : Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.android, size: 18, color: Colors.green),
                      label: Text(
                        _isEnglish ? 'Download Android App' : 'Tải App Android (.APK)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 32),

          // Right Column: Daily Awakening Quote Card
          if (_currentQuote != null)
            Expanded(
              flex: 5,
              child: _buildDailyQuoteCard(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyQuoteCard(bool isDark) {
    final quoteText = _currentQuote!.getText(_isEnglish);
    final sourceText = _currentQuote!.getSource(_isEnglish);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2330), const Color(0xFF141822)]
              : [const Color(0xFFFFFDF8), const Color(0xFFF7EEDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.primary.withOpacity(0.5) : AppColors.primary.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _isEnglish ? 'DAILY AWAKENING INSIGHT' : 'THÔNG ĐIỆP TỈNH THỨC HÔM NAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                tooltip: _isEnglish ? 'Next quote' : 'Đổi thông điệp khác',
                onPressed: () => _setDailyQuote(randomize: true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quoteText,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.55,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "— $sourceText",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => QuoteCardDialog(quote: _currentQuote!, isEnglish: _isEnglish),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share, size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        _isEnglish ? 'Share' : 'Tạo Thẻ',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard(String sectionId, String sectionTitle, bool isDark) {
    String displayTitle = sectionTitle;
    final sec = _repo.getSectionById(sectionId);
    if (sec != null) {
      displayTitle = sec.getTitle(_isEnglish);
    }

    return InkWell(
      onTap: () => _openSection(sectionId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_book, color: AppColors.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnglish ? 'CONTINUE READING' : 'TIẾP TỤC ĐỌC DỞ',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDesktopWeb) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      {
        'title': _isEnglish ? '19 Foundations' : '19 Nền Tảng',
        'sub': _isEnglish ? '19 Core Chapters of Transformation' : '19 Chương cốt lõi & chuyển hóa',
        'icon': Icons.auto_stories,
        'color': const Color(0xFFD66D57),
        'filter': 'part',
        'firstId': 'ch_01',
      },
      {
        'title': _isEnglish ? '55 Realisations' : '55 Giải Ngộ',
        'sub': _isEnglish ? 'Social, Soul & Universe' : 'Xã hội, Thân phận & Đạo',
        'icon': Icons.lightbulb_outline,
        'color': const Color(0xFFC5A059),
        'filter': 'realisation',
        'firstId': 'gn_01',
      },
      {
        'title': _isEnglish ? '44 Reflections' : '44 Suy Ngẫm',
        'sub': _isEnglish ? '5 Levels of Awareness' : '5 Tầng chuyển hóa nội tâm',
        'icon': Icons.self_improvement,
        'color': const Color(0xFF3F6352),
        'filter': 'reflection',
        'firstId': 'sn_01',
      },
      {
        'title': _isEnglish ? '30 Practices' : '30 Thực Hành',
        'sub': _isEnglish ? 'Body, Heart, Mind & Soul' : 'Thân - Tâm - Trí - Tỉnh thức',
        'icon': Icons.spa_outlined,
        'color': const Color(0xFF8E5EA2),
        'filter': 'practice',
        'firstId': 'th_01',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktopWeb ? 4 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isDesktopWeb ? 1.55 : 1.35,
      ),
      itemBuilder: (context, idx) {
        final c = categories[idx];
        final col = c['color'] as Color;
        return InkWell(
          onTap: () => _openSection(c['firstId'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? col.withOpacity(0.14) : col.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: col.withOpacity(isDark ? 0.35 : 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(c['icon'] as IconData, color: col, size: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c['sub'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodcastRow(bool isDesktopWeb) {
    final allPods = _repo.podcasts;
    if (allPods.isEmpty) return const SizedBox.shrink();
    final pods = allPods.where((p) => p.language == (_isEnglish ? 'en' : 'vi')).toList();
    final displayPods = pods.isNotEmpty ? pods : allPods;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktopWeb) {
      // Desktop Grid of Podcasts
      final gridCount = displayPods.length > 4 ? 4 : displayPods.length;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (context, idx) {
          final pod = displayPods[idx];
          return InkWell(
            onTap: widget.onOpenAudio,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          pod.image ?? 'assets/images/image1.webp',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pod.getCategory(_isEnglish).toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pod.duration,
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    pod.getTitle(_isEnglish),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_filled, color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _isEnglish ? 'Listen Now' : 'Nghe ngay',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Mobile Horizontal Scrolling List
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayPods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
          final pod = displayPods[idx];
          return InkWell(
            onTap: widget.onOpenAudio,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      pod.image ?? 'assets/images/image1.webp',
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pod.getCategory(_isEnglish).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pod.getTitle(_isEnglish),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              pod.duration,
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebFooter(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090B0F) : const Color(0xFFF0ECE1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left brand info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEnglish ? 'THE SCIENCE OF SPIRITUALITY' : 'KHOA HỌC TÂM LINH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEnglish
                          ? 'Author: Hoang Nhat Minh\nA profound synthesis bridging quantum mechanics, neuroscience, and ancient spiritual awakening.'
                          : 'Tác giả: Hoàng Nhật Minh\nCầu nối giữa cơ học lượng tử hiện đại, khoa học ý thức và tuệ giác tâm linh phương Đông ngàn năm.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Quick links
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEnglish ? 'EXPLORE' : 'MỤC LỤC SÁCH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                        color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildFooterLink(_isEnglish ? '19 Chapters' : '19 Chương Sách', widget.onOpenLibrary, isDark),
                    _buildFooterLink(_isEnglish ? '55 Realisations' : '55 Khai Thị Giải Ngộ', () => _openSection('gn_01'), isDark),
                    _buildFooterLink(_isEnglish ? '44 Reflections' : '44 Tầng Suy Ngẫm', () => _openSection('sn_01'), isDark),
                    _buildFooterLink(_isEnglish ? '30 Practices' : '30 Bài Tập Thực Hành', () => _openSection('th_01'), isDark),
                  ],
                ),
              ),
              // Podcast & App links
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEnglish ? 'MEDIA & DOWNLOAD' : 'ÂM THANH & ỨNG DỤNG',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                        color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildFooterLink(_isEnglish ? 'Healing Podcasts (5)' : 'Podcast Chữa Lành (7)', widget.onOpenAudio, isDark),
                    _buildFooterLink(_isEnglish ? 'Download Android App' : 'Tải Cài Đặt Android (.APK)', () => downloadFile('https://khoahoctamlinh.vn/app/KhoaHocTamLinh.apk'), isDark),
                    _buildFooterLink('khoahoctamlinh.vn', () {}, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Divider(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.08)),
          const SizedBox(height: 14),
          Text(
            _isEnglish
                ? '© 2026 The Science of Spirituality • Author Hoang Nhat Minh. All rights reserved.'
                : '© 2026 Khoa Học Tâm Linh • Tác giả Hoàng Nhật Minh. Bản quyền thuộc về tác giả.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
