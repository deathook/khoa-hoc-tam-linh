import 'package:flutter/material.dart';
import '../../models/toc_item.dart';
import '../../routes/seo_router.dart';
import '../../services/book_repository.dart';
import '../../services/seo/seo_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import 'reader_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/app_cached_image.dart';

class TocScreen extends StatefulWidget {
  final Function(String sectionId)? onOpenSection;
  const TocScreen({Key? key, this.onOpenSection}) : super(key: key);

  @override
  State<TocScreen> createState() => _TocScreenState();
}

class _TocScreenState extends State<TocScreen> with SingleTickerProviderStateMixin {
  final BookRepository _repo = BookRepository();
  final StorageService _storage = StorageService();

  late bool _isEnglish;
  String _selectedFilter = 'all';
  String _searchFilter = '';

  final List<Map<String, String>> _filterOptions = [
    {'key': 'all', 'label_vi': 'Tất cả (173)', 'label_en': 'All (173)'},
    {'key': 'part', 'label_vi': 'Phần chính & Chương', 'label_en': 'Parts & Chapters'},
    {'key': 'realisation', 'label_vi': '55 Giải Ngộ', 'label_en': '55 Realisations'},
    {'key': 'attainment', 'label_vi': 'Chứng Ngộ & Giác Ngộ', 'label_en': 'Attainment & Awakening'},
    {'key': 'reflection', 'label_vi': '44 Suy Ngẫm', 'label_en': '44 Reflections'},
    {'key': 'practice', 'label_vi': '30 Thực Hành', 'label_en': '30 Practices'},
    {'key': 'appendix', 'label_vi': 'Phụ lục & Hành trang', 'label_en': 'Appendices & Provisions'},
  ];

  @override
  void initState() {
    super.initState();
    _isEnglish = _storage.isEnglish;
    _storage.isEnglishNotifier.addListener(_onLangChanged);
  }

  @override
  void dispose() {
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

  void _toggleLanguage() async {
    final next = !_isEnglish;
    await _storage.setIsEnglish(next);
    await TtsService().setLanguage(next);
    setState(() {
      _isEnglish = next;
    });
    SeoService.updateUrl(
      SeoRouter.getTabUrl(1, next),
      title: SeoRouter.getTabTitle(1, next),
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
          SeoRouter.getTabUrl(1, _isEnglish),
          title: SeoRouter.getTabTitle(1, _isEnglish),
          replace: false,
        );
      }
    });
  }

  List<TocItem> _getFilteredList() {
    var list = _repo.toc;

    if (_selectedFilter == 'part') {
      list = list.where((t) => t.category == 'part' || t.category == 'chapter' || t.category == 'intro' || t.category == 'poem').toList();
    } else if (_selectedFilter == 'realisation') {
      list = list.where((t) => t.category == 'realisation').toList();
    } else if (_selectedFilter == 'attainment') {
      list = list.where((t) => t.category == 'attainment' || t.id == 'part_8').toList();
    } else if (_selectedFilter == 'reflection') {
      list = list.where((t) => t.category == 'reflection').toList();
    } else if (_selectedFilter == 'practice') {
      list = list.where((t) => t.category == 'practice').toList();
    } else if (_selectedFilter == 'appendix') {
      list = list.where((t) => t.category == 'appendix' || t.category == 'outro' || t.id == 'hanh_trang').toList();
    }

    if (_searchFilter.isNotEmpty) {
      list = list.where((t) {
        final title = t.getTitle(_isEnglish).toLowerCase();
        return title.contains(_searchFilter.toLowerCase());
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;
    final filteredList = _getFilteredList();

    if (isDesktopWeb) {
      return Scaffold(
        body: Scrollbar(
          thumbVisibility: true,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                _isEnglish ? 'BOOK CONTENTS' : 'MỤC LỤC TÁC PHẨM',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isEnglish ? 'The Science of Spirituality' : 'Khoa Học Tâm Linh',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF0EBE0) : const Color(0xFF1B1E28),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isEnglish
                                    ? '173 sections & chapters • Quantum physics meets ancient Eastern wisdom'
                                    : 'Toàn bộ 173 chương & chủ đề • Giao thoa khoa học lượng tử & trí tuệ Đông phương',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SearchScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.search, size: 20),
                            label: Text(
                              _isEnglish ? 'Search Chapters' : 'Tìm kiếm trong sách',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Horizontal Filter Chips
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filterOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final f = _filterOptions[idx];
                            final isSelected = _selectedFilter == f['key'];
                            final label = _isEnglish ? f['label_en']! : f['label_vi']!;

                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedFilter = f['key']!;
                                  });
                                }
                              },
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Responsive 2-column grid of chapters
                      if (filteredList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              _isEnglish ? 'No sections found' : 'Không tìm thấy mục nào',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, idx) {
                            return _buildChapterCard(filteredList[idx], isDark);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile Phone Layout
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEnglish ? 'Table of Contents' : 'Mục Lục Cuốn Sách',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final f = _filterOptions[idx];
                final isSelected = _selectedFilter == f['key'];
                final label = _isEnglish ? f['label_en']! : f['label_vi']!;

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedFilter = f['key']!;
                      });
                    }
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: filteredList.isEmpty
          ? Center(
              child: Text(
                _isEnglish ? 'No sections found' : 'Không tìm thấy mục nào',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                return _buildChapterCard(filteredList[idx], isDark);
              },
            ),
    );
  }

  Widget _buildChapterCard(TocItem item, bool isDark) {
    final isBookmarked = _storage.isBookmarked(item.id);
    final isPartHeader = item.category == 'part';

    return InkWell(
      onTap: () => _openSection(item.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPartHeader
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPartHeader
                ? (isDark ? const Color(0xFFE5B968).withOpacity(0.6) : AppColors.primary.withOpacity(0.4))
                : (isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail or Number Circle
            if (item.getImageVertical(_isEnglish) != null)
              AppCachedImage(
                imageUrlOrAsset: item.getImageVertical(_isEnglish)!,
                width: 44,
                height: 56,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPartHeader
                      ? (isDark ? const Color(0xFFE5B968) : AppColors.primary)
                      : (isDark ? const Color(0xFF252B3A) : AppColors.secondary.withOpacity(0.1)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  item.num.isNotEmpty ? item.num : '${item.order}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPartHeader ? Colors.black : (isDark ? const Color(0xFF76D79E) : AppColors.secondary),
                  ),
                ),
              ),
            const SizedBox(width: 14),

            // Title & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.getTitle(_isEnglish),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isPartHeader ? FontWeight.bold : FontWeight.w600,
                      fontSize: isPartHeader ? 15 : 13.5,
                      color: isPartHeader
                          ? (isDark ? const Color(0xFFE5B968) : AppColors.primaryDark)
                          : (isDark ? AppColors.textLight : null),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.getCategoryLabel(_isEnglish),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (item.image != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.image, size: 14, color: isDark ? const Color(0xFFE5B968) : AppColors.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Bookmark icon
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? (isDark ? const Color(0xFFE5B968) : AppColors.primary) : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
                size: 20,
              ),
              onPressed: () async {
                await _storage.toggleBookmark(item.id);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
