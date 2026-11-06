import 'package:flutter/material.dart';
import '../../services/book_repository.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../reader/reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final BookRepository _repo = BookRepository();
  final StorageService _storage = StorageService();
  final TextEditingController _searchController = TextEditingController();

  List<SearchResult> _results = [];
  bool _isSearching = false;
  late bool _isEnglish;

  @override
  void initState() {
    super.initState();
    _isEnglish = _storage.isEnglish;
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _results = _repo.search(query, _isEnglish);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _isEnglish ? 'Search chapters, concepts, keywords...' : 'Tìm kiếm chương, khái niệm, từ khóa...',
            border: InputBorder.none,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (!_isSearching && _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              _isEnglish ? 'Type any keyword to search whole book' : 'Nhập từ khóa để tra cứu toàn bộ cuốn sách',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickTag(_isEnglish ? 'Middle Way' : 'Trung đạo'),
                _buildQuickTag(_isEnglish ? 'Oneness' : 'Nhất nguyên'),
                _buildQuickTag(_isEnglish ? 'Soul' : 'Linh hồn'),
                _buildQuickTag('Vipassana'),
                _buildQuickTag('Ho\'oponopono'),
                _buildQuickTag(_isEnglish ? 'Quantum' : 'Lượng tử'),
              ],
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          _isEnglish ? 'No matches found' : 'Không tìm thấy kết quả nào phù hợp',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            _isEnglish ? 'Found ${_results.length} results:' : 'Tìm thấy ${_results.length} kết quả:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final r = _results[idx];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(
                        sectionId: r.section.id,
                        initialParagraphIndex: r.paragraphIndex,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.section.getCategoryLabel(_isEnglish),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.section.getTitle(_isEnglish),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.snippet,
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTag(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _searchController.text = label;
        _onSearchChanged(label);
      },
    );
  }
}
