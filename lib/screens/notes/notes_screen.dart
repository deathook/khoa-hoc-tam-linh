import 'package:flutter/material.dart';
import '../../models/user_note.dart';
import '../../routes/seo_router.dart';
import '../../services/book_repository.dart';
import '../../services/seo/seo_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../widgets/auth_dialog.dart';
import '../../theme/app_colors.dart';
import '../reader/reader_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final BookRepository _repo = BookRepository();
  final ScrollController _hlScrollController = ScrollController();
  final ScrollController _notesScrollController = ScrollController();
  final ScrollController _bmScrollController = ScrollController();

  late TabController _tabController;
  late bool _isEnglish;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isEnglish = _storage.isEnglish;
    _storage.isEnglishNotifier.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storage.isEnglishNotifier.removeListener(_onLangChanged);
    _hlScrollController.dispose();
    _notesScrollController.dispose();
    _bmScrollController.dispose();
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
      SeoRouter.getTabUrl(3, next),
      title: SeoRouter.getTabTitle(3, next),
      replace: false,
    );
  }

  void _openSection(String sectionId, int paragraphIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          sectionId: sectionId,
          initialParagraphIndex: paragraphIndex,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
        SeoService.updateUrl(
          SeoRouter.getTabUrl(3, _isEnglish),
          title: SeoRouter.getTabTitle(3, _isEnglish),
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

    final highlights = _storage.getHighlights();
    final notes = _storage.getNotes();
    final bookmarks = _storage.getBookmarks();

    if (isDesktopWeb) {
      return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnglish ? 'STUDY NOTEBOOK' : 'SỔ TAY CHIÊM NGHIỆM',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              _isEnglish ? 'Highlights & Personal Notes' : 'Đoạn Trích Tô Màu & Ghi Chú',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF0EBE0) : const Color(0xFF1B1E28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ListenableBuilder(
                            listenable: FirebaseSyncService(),
                            builder: (context, _) {
                              final sync = FirebaseSyncService();
                              final isLoggedIn = sync.isLoggedIn;
                              return OutlinedButton.icon(
                                onPressed: () => showAppAuthDialog(context, isDark: isDark, isEnglish: _isEnglish),
                                icon: Icon(
                                  isLoggedIn ? Icons.cloud_done : Icons.cloud_outlined,
                                  size: 16,
                                  color: isLoggedIn ? Colors.green : AppColors.primaryDark,
                                ),
                                label: Text(
                                  isLoggedIn
                                      ? (_isEnglish ? 'Cloud Synced' : 'Đã Đồng Bộ Đám Mây')
                                      : (_isEnglish ? 'Enable Cloud Sync' : 'Bật Đồng Bộ Đám Mây'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isLoggedIn ? Colors.green : AppColors.primaryDark,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: (isLoggedIn ? Colors.green : AppColors.primaryDark).withOpacity(0.4),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: AppColors.primary,
                        labelColor: isDark ? Colors.white : Colors.black87,
                        unselectedLabelColor: AppColors.textMuted,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: [
                          Tab(text: _isEnglish ? 'Highlights (${highlights.length})' : 'Tô Màu (${highlights.length})'),
                          Tab(text: _isEnglish ? 'Notes (${notes.length})' : 'Ghi Chú (${notes.length})'),
                          Tab(text: _isEnglish ? 'Bookmarks (${bookmarks.length})' : 'Dấu Trang (${bookmarks.length})'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHighlightsTab(highlights, isDark, isDesktopWeb: true),
                  _buildNotesTab(notes, isDark, isDesktopWeb: true),
                  _buildBookmarksTab(bookmarks, isDark, isDesktopWeb: true),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Phone Layout
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
                _isEnglish ? 'Notes & Highlights' : 'Ghi Chú & Đánh Dấu',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
                        isLoggedIn ? Icons.cloud_done : Icons.cloud_outlined,
                        size: 22,
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
                tooltip: _isEnglish ? 'Cloud Sync' : 'Đồng bộ đám mây',
                onPressed: () => showAppAuthDialog(context, isDark: isDark, isEnglish: _isEnglish),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: isDark ? Colors.white : Colors.black87,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: _isEnglish ? 'Highlights (${highlights.length})' : 'Tô Màu (${highlights.length})'),
            Tab(text: _isEnglish ? 'Notes (${notes.length})' : 'Ghi Chú (${notes.length})'),
            Tab(text: _isEnglish ? 'Bookmarks (${bookmarks.length})' : 'Dấu Trang (${bookmarks.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Highlights
          _buildHighlightsTab(highlights, isDark),

          // Tab 2: Notes
          _buildNotesTab(notes, isDark),

          // Tab 3: Bookmarks
          _buildBookmarksTab(bookmarks, isDark),
        ],
      ),
    );
  }

  Widget _buildHighlightsTab(List<UserHighlight> highlights, bool isDark, {bool isDesktopWeb = false}) {
    if (highlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.highlight, size: 54, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              _isEnglish ? 'No highlights yet.\nTap on any paragraph while reading to highlight it.' : 'Chưa có đoạn văn nào được tô màu.\nChạm vào đoạn văn khi đọc để chọn màu nổi bật.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      );
    }

    final listView = ListView.separated(
      controller: _hlScrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktopWeb ? 24 : 16,
        vertical: 16,
      ),
      itemCount: highlights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final h = highlights[idx];
        final col = Color(h.colorValue);
        final sec = _repo.getSectionById(h.sectionId);
        final paras = sec?.getParagraphs(_isEnglish);
        final displayText = (paras != null && h.paragraphIndex >= 0 && h.paragraphIndex < paras.length)
            ? paras[h.paragraphIndex]
            : h.text;

        final card = InkWell(
          onTap: () => _openSection(h.sectionId, h.paragraphIndex),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: col, width: 5),
                top: BorderSide(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.05)),
                right: BorderSide(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.05)),
                bottom: BorderSide(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.05)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sec?.getTitle(_isEnglish) ?? h.sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                      onPressed: () async {
                        await _storage.removeHighlight(h.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Text(
                  displayText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );

        if (isDesktopWeb) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: card,
            ),
          );
        }
        return card;
      },
    );

    if (isDesktopWeb) {
      return Scrollbar(
        controller: _hlScrollController,
        thumbVisibility: true,
        interactive: true,
        child: listView,
      );
    }
    return listView;
  }

  Widget _buildNotesTab(List<UserNote> notes, bool isDark, {bool isDesktopWeb = false}) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 54, color: AppColors.secondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              _isEnglish ? 'No notes yet.\nTap on any paragraph to write your personal reflection.' : 'Chưa có ghi chú nào.\nChạm vào đoạn văn khi đọc để ghi lại cảm ngộ của bạn.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      );
    }

    final listView = ListView.separated(
      controller: _notesScrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktopWeb ? 24 : 16,
        vertical: 16,
      ),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final n = notes[idx];
        final sec = _repo.getSectionById(n.sectionId);
        final paras = sec?.getParagraphs(_isEnglish);
        final targetText = (paras != null && n.paragraphIndex >= 0 && n.paragraphIndex < paras.length)
            ? paras[n.paragraphIndex]
            : n.targetText;

        final card = InkWell(
          onTap: () => _openSection(n.sectionId, n.paragraphIndex),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.cardDarkBorder : AppColors.secondary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sec?.getTitle(_isEnglish) ?? n.sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? const Color(0xFFE5B968) : AppColors.secondary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                      onPressed: () async {
                        await _storage.deleteNote(n.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    n.noteContent,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEnglish ? 'Target text: "$targetText"' : 'Đoạn văn gốc: "$targetText"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );

        if (isDesktopWeb) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: card,
            ),
          );
        }
        return card;
      },
    );

    if (isDesktopWeb) {
      return Scrollbar(
        controller: _notesScrollController,
        thumbVisibility: true,
        interactive: true,
        child: listView,
      );
    }
    return listView;
  }

  Widget _buildBookmarksTab(List<String> bookmarks, bool isDark, {bool isDesktopWeb = false}) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 54, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              _isEnglish ? 'No bookmarks yet.\nTap the bookmark icon in any chapter to save it.' : 'Chưa có dấu trang nào.\nBấm biểu tượng dấu trang khi đọc để lưu chương yêu thích.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      );
    }

    final listView = ListView.separated(
      controller: _bmScrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktopWeb ? 24 : 16,
        vertical: 16,
      ),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final id = bookmarks[idx];
        final item = _repo.getTocById(id);
        final title = item != null ? item.getTitle(_isEnglish) : id;

        final card = InkWell(
          onTap: () => _openSection(id, 0),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: isDark ? const Color(0xFFE5B968) : AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: isDark ? AppColors.textLightMuted : AppColors.textMuted),
                  onPressed: () async {
                    await _storage.toggleBookmark(id);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        );

        if (isDesktopWeb) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: card,
            ),
          );
        }
        return card;
      },
    );

    if (isDesktopWeb) {
      return Scrollbar(
        controller: _bmScrollController,
        thumbVisibility: true,
        interactive: true,
        child: listView,
      );
    }
    return listView;
  }
}
