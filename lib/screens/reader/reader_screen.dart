import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/book_section.dart';
import '../../models/quote_item.dart';
import '../../models/user_note.dart';
import '../../routes/seo_router.dart';
import '../../services/book_repository.dart';
import '../../services/seo/seo_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/quote_card_dialog.dart';
import '../../widgets/interactive_image_viewer.dart';
import '../../widgets/app_cached_image.dart';

class ReaderScreen extends StatefulWidget {
  final String sectionId;
  final int initialParagraphIndex;
  final VoidCallback? onBack;

  const ReaderScreen({
    Key? key,
    required this.sectionId,
    this.initialParagraphIndex = 0,
    this.onBack,
  }) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final BookRepository _repo = BookRepository();
  final StorageService _storage = StorageService();
  final TtsService _tts = TtsService();

  late String _currentId;
  BookSection? _section;
  late bool _isEnglish;
  double _fontSize = 17.0;
  double _ttsPitch = 1.0;
  List<Map<String, String>> _availableVoices = [];

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _paragraphKeys = {};

  @override
  void initState() {
    super.initState();
    _currentId = widget.sectionId;
    _isEnglish = _storage.isEnglish;
    _fontSize = _storage.fontSize;
    _ttsPitch = _storage.ttsPitch;
    _loadSection();
    _loadVoices();

    _tts.addListener(_onTtsUpdate);
    _tts.onSectionFinished = _handleTtsSectionFinished;
    _storage.isEnglishNotifier.addListener(_onGlobalLanguageChanged);
    _storage.themeModeNotifier.addListener(_onThemeModeChanged);

    if (widget.initialParagraphIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            _scrollToParagraph(widget.initialParagraphIndex);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _tts.removeListener(_onTtsUpdate);
    _storage.isEnglishNotifier.removeListener(_onGlobalLanguageChanged);
    _storage.themeModeNotifier.removeListener(_onThemeModeChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onThemeModeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onGlobalLanguageChanged() {
    if (mounted) {
      setState(() {
        _isEnglish = _storage.isEnglish;
        _loadSection();
        _loadVoices();
      });
    }
  }

  Future<void> _loadVoices() async {
    final v = await _tts.getAvailableVoices(_isEnglish);
    if (mounted) {
      setState(() => _availableVoices = v);
    }
  }

  void _onTtsUpdate() {
    if (mounted) {
      if (_tts.state == TtsPlayState.playing &&
          _tts.currentSectionId.isNotEmpty &&
          _tts.currentSectionId != _currentId) {
        setState(() {
          _currentId = _tts.currentSectionId;
          _loadSection();
        });
        _scrollController.jumpTo(0);
      }
      setState(() {});
      if (_tts.state == TtsPlayState.playing && _tts.currentSectionId == _currentId) {
        if (_tts.currentIndex == -1) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        } else {
          _scrollToParagraph(_tts.currentIndex);
        }
      }
    }
  }

  void _handleTtsSectionFinished() {
    if (mounted) {
      if (_tts.currentSectionId.isNotEmpty && _tts.currentSectionId != _currentId) {
        setState(() {
          _currentId = _tts.currentSectionId;
          _loadSection();
        });
        _scrollController.jumpTo(0);
      }
    }
  }

  void _syncReaderUrl({bool replace = false}) {
    if (_section == null) return;
    final url = SeoRouter.getReaderUrl(_currentId, _isEnglish);
    final title = SeoRouter.getReaderTitle(_section!.getTitle(_isEnglish), _isEnglish);
    final paras = _section!.getParagraphs(_isEnglish);
    final desc = paras.isNotEmpty ? paras.first : '';
    SeoService.updateUrl(url, title: title, description: desc, replace: replace);
  }

  void _loadSection() {
    setState(() {
      _section = _repo.getSectionById(_currentId);
      _paragraphKeys.clear();
      if (_section != null) {
        final count = _section!.getParagraphs(_isEnglish).length;
        for (int i = 0; i < count; i++) {
          _paragraphKeys[i] = GlobalKey();
        }
        _storage.saveLastRead(_section!.id, _section!.getTitle(_isEnglish));
        _syncReaderUrl(replace: false);
      }
    });
  }

  void _scrollToParagraph(int index) {
    if (index < 0) return;

    void attemptScroll(int retriesLeft) {
      final key = _paragraphKeys[index];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.25,
        );
      } else if (retriesLeft > 0) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) attemptScroll(retriesLeft - 1);
        });
      }
    }

    attemptScroll(5);
  }

  void _toggleLanguage() async {
    final next = !_isEnglish;
    await _storage.setIsEnglish(next);
    await _tts.setLanguage(next);
    setState(() {
      _isEnglish = next;
      _loadSection();
    });
    _loadVoices();
    if (_tts.state == TtsPlayState.playing) {
      _tts.stop();
    }
  }

  void _goToNext() {
    final next = _repo.getNextSection(_currentId);
    if (next != null) {
      if (_tts.state == TtsPlayState.playing) _tts.stop();
      setState(() {
        _currentId = next.id;
        _loadSection();
      });
      _scrollController.jumpTo(0);
    }
  }

  void _goToPrev() {
    final prev = _repo.getPrevSection(_currentId);
    if (prev != null) {
      if (_tts.state == TtsPlayState.playing) _tts.stop();
      setState(() {
        _currentId = prev.id;
        _loadSection();
      });
      _scrollController.jumpTo(0);
    }
  }

  void _toggleBookmark() async {
    await _storage.toggleBookmark(_currentId);
    setState(() {});
  }

  // --- TTS Controller ---
  void _startTts({int startIndex = 0}) {
    if (_section == null) return;
    final paras = _section!.getParagraphs(_isEnglish);
    _tts.startReadingSection(
      sectionId: _section!.id,
      paragraphs: paras,
      isEnglish: _isEnglish,
      title: _section!.getTitle(_isEnglish),
      startIndex: startIndex,
    );
  }

  // --- Show Paragraph Options Modal ---
  void _showParagraphOptions(int pIndex, String text) {
    final existingHighlight = _storage.getHighlights().firstWhere(
      (h) => h.sectionId == _currentId && h.paragraphIndex == pIndex,
      orElse: () => UserHighlight(
        id: '',
        sectionId: '',
        sectionTitle: '',
        paragraphIndex: -1,
        text: '',
        colorValue: 0,
        createdAt: DateTime.now(),
      ),
    );
    final bool isHighlighted = existingHighlight.paragraphIndex == pIndex && existingHighlight.colorValue != 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isEnglish ? 'PARAGRAPH OPTIONS' : 'TÙY CHỌN ĐOẠN VĂN',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),

                // TTS from here
                ListTile(
                  leading: const Icon(Icons.volume_up, color: AppColors.primary),
                  title: Text(_isEnglish ? 'Read from this paragraph' : 'Nghe máy đọc từ đoạn này'),
                  onTap: () {
                    Navigator.pop(context);
                    _startTts(startIndex: pIndex);
                  },
                ),

                // Highlight Color Palette
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEnglish ? 'Highlight Color:' : 'Tô màu đoạn văn:',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Row(
                        children: [
                          _buildColorCircle(pIndex, text, AppColors.highlightYellow, _isEnglish ? 'Yellow' : 'Vàng', isHighlighted && existingHighlight.colorValue == AppColors.highlightYellow.value, existingHighlight.id),
                          _buildColorCircle(pIndex, text, AppColors.highlightGreen, _isEnglish ? 'Green' : 'Xanh', isHighlighted && existingHighlight.colorValue == AppColors.highlightGreen.value, existingHighlight.id),
                          _buildColorCircle(pIndex, text, AppColors.highlightPurple, _isEnglish ? 'Purple' : 'Tím', isHighlighted && existingHighlight.colorValue == AppColors.highlightPurple.value, existingHighlight.id),
                          _buildColorCircle(pIndex, text, AppColors.highlightRose, _isEnglish ? 'Rose' : 'Hồng', isHighlighted && existingHighlight.colorValue == AppColors.highlightRose.value, existingHighlight.id),
                          if (isHighlighted)
                            _buildRemoveHighlightCircle(existingHighlight.id),
                        ],
                      ),
                    ],
                  ),
                ),

                // Remove Highlight tile
                if (isHighlighted)
                  ListTile(
                    leading: const Icon(Icons.format_color_reset, color: Colors.redAccent),
                    title: Text(
                      _isEnglish ? 'Remove Highlight' : 'Bỏ tô màu đoạn văn này',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _storage.removeHighlight(existingHighlight.id);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isEnglish ? 'Highlight removed' : 'Đã bỏ màu tô đoạn văn!')),
                      );
                    },
                  ),

                // Add Note
                ListTile(
                  leading: const Icon(Icons.edit_note, color: AppColors.secondary),
                  title: Text(_isEnglish ? 'Add Note' : 'Thêm Ghi chú cá nhân'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddNoteDialog(pIndex, text);
                  },
                ),

                // Share Quote Card
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.indigo),
                  title: Text(_isEnglish ? 'Create Quote Card' : 'Tạo Thẻ Trích Dẫn Chia Sẻ'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) {
                        final enParas = _section!.getParagraphs(true);
                        final viParas = _section!.getParagraphs(false);
                        final quoteVi = (pIndex >= 0 && pIndex < viParas.length) ? viParas[pIndex] : text;
                        final quoteEn = (pIndex >= 0 && pIndex < enParas.length) ? enParas[pIndex] : text;

                        return QuoteCardDialog(
                          quote: QuoteItem(
                            textVi: quoteVi,
                            textEn: quoteEn,
                            sourceVi: _section!.getTitle(false),
                            sourceEn: _section!.getTitle(true),
                            category: _section!.category,
                          ),
                          isEnglish: _isEnglish,
                        );
                      },
                    );
                  },
                ),

                // Copy Text
                ListTile(
                  leading: const Icon(Icons.copy, color: AppColors.textMuted),
                  title: Text(_isEnglish ? 'Copy Paragraph' : 'Sao chép đoạn văn'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isEnglish ? 'Copied to clipboard' : 'Đã sao chép!')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorCircle(int pIndex, String text, Color color, String name, bool isSelected, String existingId) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (isSelected) {
          await _storage.removeHighlight(existingId);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEnglish ? 'Highlight removed' : 'Đã bỏ màu tô đoạn văn!')),
          );
          return;
        }

        final h = UserHighlight(
          id: '${_currentId}_$pIndex',
          sectionId: _currentId,
          sectionTitle: _section!.getTitle(_isEnglish),
          paragraphIndex: pIndex,
          text: text,
          colorValue: color.value,
          createdAt: DateTime.now(),
        );
        await _storage.addHighlight(h);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEnglish ? 'Highlighted' : 'Đã tô màu đoạn văn!')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black.withOpacity(0.15),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black87) : null,
      ),
    );
  }

  Widget _buildRemoveHighlightCircle(String highlightId) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await _storage.removeHighlight(highlightId);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEnglish ? 'Highlight removed' : 'Đã bỏ màu tô đoạn văn!')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
        ),
        child: const Icon(Icons.format_color_reset, size: 16, color: Colors.redAccent),
      ),
    );
  }

  void _showAddNoteDialog(int pIndex, String text) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isEnglish ? 'Add Note' : 'Ghi Chú'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.length > 80 ? '${text.substring(0, 80)}...' : text,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isEnglish ? 'Write your thoughts/realisations here...' : 'Viết cảm ngộ, suy ngẫm của bạn...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_isEnglish ? 'Cancel' : 'Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = noteController.text.trim();
                if (content.isNotEmpty) {
                  final note = UserNote(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    sectionId: _currentId,
                    sectionTitle: _section!.getTitle(_isEnglish),
                    paragraphIndex: pIndex,
                    targetText: text,
                    noteContent: content,
                    createdAt: DateTime.now(),
                  );
                  await _storage.saveNote(note);
                  setState(() {});
                }
                Navigator.pop(context);
              },
              child: Text(_isEnglish ? 'Save' : 'Lưu Ghi Chú'),
            ),
          ],
        );
      },
    );
  }

  // --- Display Settings Sheet ---
  void _showDisplaySettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentMode = _storage.themeMode;
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEnglish ? 'READING & VOICE SETTINGS' : 'CÀI ĐẶT ĐỌC & GIỌNG NÓI',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Font Size Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEnglish ? 'Font Size: ${_fontSize.toInt()}sp' : 'Cỡ chữ đọc sách: ${_fontSize.toInt()}sp',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                                onPressed: () async {
                                  if (_fontSize > 13) {
                                    final s = _fontSize - 1;
                                    await _storage.setFontSize(s);
                                    setState(() => _fontSize = s);
                                    setModalState(() {});
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                onPressed: () async {
                                  if (_fontSize < 28) {
                                    final s = _fontSize + 1;
                                    await _storage.setFontSize(s);
                                    setState(() => _fontSize = s);
                                    setModalState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Theme Mode Selector
                      Text(
                        _isEnglish ? 'Page Color Theme' : 'Chế độ màu nền',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildThemeButton('light', _isEnglish ? 'Light' : 'Sáng', Colors.white, Colors.black87, currentMode == 'light', setModalState),
                          _buildThemeButton('sepia', _isEnglish ? 'Sepia' : 'Vàng Ấm', AppColors.sepiaBg, AppColors.textSepia, currentMode == 'sepia', setModalState),
                          _buildThemeButton('dark', _isEnglish ? 'Dark' : 'Đêm', AppColors.darkBg, AppColors.textLight, currentMode == 'dark', setModalState),
                        ],
                      ),

                      const Divider(height: 24),

                      // Voice Pitch (Nam / Nữ)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEnglish ? 'Voice Tone / Pitch:' : 'Tông giọng đọc (Nam / Nữ):',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          Text(
                            _ttsPitch < 0.95
                                ? (_isEnglish ? 'Deep Warm (Male)' : 'Trầm ấm (Nam)')
                                : (_ttsPitch > 1.05
                                    ? (_isEnglish ? 'Soft High (Female)' : 'Cao nhẹ (Nữ)')
                                    : (_isEnglish ? 'Natural Standard' : 'Chuẩn tự nhiên')),
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPitchButton(
                              label: _isEnglish ? 'Male (0.85)' : 'Giọng Nam (0.85)',
                              isSelected: (_ttsPitch - 0.85).abs() < 0.05,
                              onTap: () async {
                                setState(() => _ttsPitch = 0.85);
                                await _tts.setPitch(0.85);
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPitchButton(
                              label: _isEnglish ? 'Standard (1.0)' : 'Chuẩn (1.0)',
                              isSelected: (_ttsPitch - 1.0).abs() < 0.05,
                              onTap: () async {
                                setState(() => _ttsPitch = 1.0);
                                await _tts.setPitch(1.0);
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPitchButton(
                              label: _isEnglish ? 'Female (1.15)' : 'Giọng Nữ (1.15)',
                              isSelected: (_ttsPitch - 1.15).abs() < 0.05,
                              onTap: () async {
                                setState(() => _ttsPitch = 1.15);
                                await _tts.setPitch(1.15);
                                setModalState(() {});
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
                          setModalState(() {});
                        },
                        onChangeEnd: (val) async {
                          await _tts.setPitch(val);
                        },
                      ),

                      // Device Voice Engine Selection
                      if (_availableVoices.isNotEmpty) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isEnglish ? 'Select Voice Engine:' : 'Chọn Giọng máy đọc sách:',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.volume_up, size: 14, color: AppColors.primary),
                              label: Text(
                                _isEnglish ? 'Test' : 'Nghe thử',
                                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                final sample = _isEnglish ? 'Testing device speech voice.' : 'Nghe thử giọng đọc của máy.';
                                _tts.startReadingSection(sectionId: 'test', paragraphs: [sample], isEnglish: _isEnglish);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              final v = _availableVoices.firstWhere((item) => item['name'] == val);
                              await _tts.setVoice(v);
                              setState(() {});
                              setModalState(() {});
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeButton(String mode, String label, Color bg, Color textCol, bool isSelected, StateSetter setModalState) {
    return InkWell(
      onTap: () async {
        await _storage.setThemeMode(mode);
        setModalState(() {});
        setState(() {});
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

  Widget _buildPitchButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

  // --- Speed Selector Modal ---
  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEnglish ? 'READING SPEED' : 'TỐC ĐỘ ĐỌC SÁCH NÓI',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: TtsService.availableSpeeds.map((s) {
                    final isSel = _tts.currentSpeedMultiplier == s;
                    return ChoiceChip(
                      label: Text('${s}x', style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      onSelected: (val) async {
                        if (val) {
                          await _tts.setSpeedMultiplier(s);
                          setState(() {});
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  _isEnglish
                      ? 'Tip: 1.0x is standard calm pace. 0.75x or 0.5x is ideal for contemplation & meditation.'
                      : 'Gợi ý: Tốc độ 1.0x là tốc độ đọc chuẩn. Tốc độ 0.75x hoặc 0.5x rất thích hợp để tĩnh tâm, thiền định.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Chapter End Mode Selector ---
  void _toggleAutoNextMode() async {
    final cur = _storage.autoNextChapterMode;
    String next;
    String msg;
    if (cur == 'next') {
      next = 'repeat';
      msg = _isEnglish ? 'Mode: Repeat this chapter' : 'Chế độ: Lặp lại chương này';
    } else if (cur == 'repeat') {
      next = 'stop';
      msg = _isEnglish ? 'Mode: Stop when chapter ends' : 'Chế độ: Dừng khi hết chương';
    } else {
      next = 'next';
      msg = _isEnglish ? 'Mode: Auto-play next chapter' : 'Chế độ: Tự chuyển chương tiếp theo (Mặc định)';
    }

    await _storage.setAutoNextChapterMode(next);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_section == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy nội dung')),
      );
    }

    final isBookmarked = _storage.isBookmarked(_currentId);
    final paragraphs = _section!.getParagraphs(_isEnglish);
    final highlights = _storage.getHighlights().where((h) => h.sectionId == _currentId).toList();
    final notes = _storage.getNotes().where((n) => n.sectionId == _currentId).toList();

    final isTtsActive = _tts.state != TtsPlayState.stopped && _tts.currentSectionId == _currentId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? AppColors.textLight : AppColors.textDark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _section!.getTitle(_isEnglish),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Language toggle flag
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
          // Bookmark
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: isBookmarked ? AppColors.primary : null),
            onPressed: _toggleBookmark,
          ),
          // Display settings
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showDisplaySettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _scrollController,
              cacheExtent: 50000,
              padding: EdgeInsets.fromLTRB(16, 24, 16, isTtsActive ? 140 : 90),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Chapter Title with TTS Reading Highlight
                        Builder(
                          builder: (context) {
                            final isTitleReading = isTtsActive && _tts.currentIndex == -1;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isTitleReading
                                    ? AppColors.primary.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isTitleReading
                                    ? Border.all(color: AppColors.primaryDark, width: 2)
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isTitleReading) ...[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4, right: 8),
                                      child: Icon(Icons.volume_up, color: AppColors.primaryDark, size: 24),
                                    ),
                                  ],
                                  Expanded(
                                    child: Text(
                                      _section!.getTitle(_isEnglish),
                                      style: TextStyle(
                                        fontSize: _fontSize + 5,
                                        fontWeight: FontWeight.bold,
                                        height: 1.35,
                                        color: isDark ? AppColors.primary : AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

              // Full Width Chapter Illustration (Horizontal on Web, Vertical on App)
              if (_section!.getIllustration(_isEnglish) != null) ...[
                GestureDetector(
                  onTap: () {
                    InteractiveImageViewer.show(
                      context,
                      imagePath: _section!.getIllustration(_isEnglish)!,
                      title: _section!.getTitle(_isEnglish),
                      caption: _isEnglish ? 'Tap or pinch to zoom' : 'Chạm 2 lần hoặc dùng 2 ngón tay để phóng to/thu nhỏ',
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AppCachedImage(
                            imageUrlOrAsset: _section!.getIllustration(_isEnglish)!,
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _isEnglish ? 'Pinch to zoom' : 'Phóng to ảnh',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Additional Diagram if exists
              if (_section!.image != null && _section!.image != _section!.getImageVertical(_isEnglish)) ...[
                GestureDetector(
                  onTap: () {
                    InteractiveImageViewer.show(
                      context,
                      imagePath: _section!.image!,
                      title: _section!.getTitle(_isEnglish),
                      caption: _section!.imageCaption,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppCachedImage(
                      imageUrlOrAsset: _section!.image!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (_section!.imageCaption != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _section!.imageCaption!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              // Paragraphs
              ...List.generate(paragraphs.length, (idx) {
                final pText = paragraphs[idx];
                final isTtsReading = isTtsActive && _tts.currentIndex == idx;

                // Check highlight
                Color? highlightBg;
                final h = highlights.firstWhere(
                  (item) => item.paragraphIndex == idx,
                  orElse: () => UserHighlight(
                    id: '',
                    sectionId: '',
                    sectionTitle: '',
                    paragraphIndex: -1,
                    text: '',
                    colorValue: 0,
                    createdAt: DateTime.now(),
                  ),
                );
                if (h.paragraphIndex == idx && h.colorValue != 0) {
                  highlightBg = Color(h.colorValue);
                }

                // Check note
                final hasNote = notes.any((n) => n.paragraphIndex == idx);

                return Container(
                  key: _paragraphKeys[idx],
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isTtsReading
                        ? (isDark ? AppColors.primary.withOpacity(0.28) : AppColors.primary.withOpacity(0.18))
                        : (highlightBg != null
                            ? (isDark ? highlightBg.withOpacity(0.32) : highlightBg)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: isTtsReading
                        ? Border.all(color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark, width: 1.5)
                        : (highlightBg != null && isDark
                            ? Border.all(color: highlightBg.withOpacity(0.7), width: 1)
                            : (idx == widget.initialParagraphIndex && widget.initialParagraphIndex > 0
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null)),
                  ),
                  child: InkWell(
                    onTap: () => _showParagraphOptions(idx, pText),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pText,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.7,
                              fontWeight: isTtsReading ? FontWeight.w600 : FontWeight.normal,
                              color: (highlightBg != null && !isDark)
                                  ? const Color(0xFF1B1B1B)
                                  : textColor,
                            ),
                          ),
                          if (hasNote) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.sticky_note_2, size: 14, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  _isEnglish ? 'Personal Note added' : 'Có ghi chú cá nhân',
                                  style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 30),

              // Navigation between chapters
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _goToPrev,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(_isEnglish ? 'Previous' : 'Phần Trước'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _goToNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_isEnglish ? 'Next' : 'Phần Sau'),
                  ),
                ],
              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

          // Bottom TTS Controller Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildTtsBar(isTtsActive),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTtsBar(bool isTtsActive) {
    if (!isTtsActive && _tts.state == TtsPlayState.stopped) {
      // Floating button to start TTS
      return Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton.extended(
          onPressed: () => _startTts(startIndex: 0),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.volume_up),
          label: Text(
            _isEnglish ? 'Listen (TTS)' : 'Nghe Sách Nói (TTS)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final mode = _storage.autoNextChapterMode;
    IconData modeIcon;
    String modeTooltip;
    if (mode == 'repeat') {
      modeIcon = Icons.repeat_one_rounded;
      modeTooltip = _isEnglish ? 'Repeat this chapter' : 'Lặp lại chương này';
    } else if (mode == 'stop') {
      modeIcon = Icons.stop_circle_outlined;
      modeTooltip = _isEnglish ? 'Stop at end of chapter' : 'Dừng khi hết chương';
    } else {
      modeIcon = Icons.skip_next_rounded;
      modeTooltip = _isEnglish ? 'Auto-play next chapter (Default)' : 'Chuyển chương tiếp theo (Mặc định)';
    }

    // Active Audio / TTS Controller Bar
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? const Color(0xFFE5B968).withOpacity(0.5) : AppColors.primary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.18),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Speed button
          InkWell(
            onTap: _showSpeedSelector,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFE5B968).withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_tts.currentSpeedMultiplier}x',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.skip_previous),
            tooltip: _isEnglish ? 'Previous paragraph' : 'Đoạn trước',
            onPressed: () => _tts.prevParagraph(),
          ),
          IconButton(
            icon: Icon(
              _tts.state == TtsPlayState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 38,
              color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
            ),
            onPressed: () {
              if (_tts.state == TtsPlayState.playing) {
                _tts.pause();
              } else if (_tts.state == TtsPlayState.paused) {
                _tts.resume();
              } else {
                _startTts();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: _isEnglish ? 'Next paragraph' : 'Đoạn tiếp theo',
            onPressed: () => _tts.nextParagraph(),
          ),

          // Auto-next chapter mode toggle
          IconButton(
            icon: Icon(modeIcon, color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark, size: 22),
            tooltip: modeTooltip,
            onPressed: _toggleAutoNextMode,
          ),

          // Sleep timer button
          IconButton(
            icon: Icon(
              Icons.bedtime,
              size: 20,
              color: _tts.sleepMinutesRemaining > 0 ? (isDark ? const Color(0xFFE5B968) : AppColors.primary) : (isDark ? AppColors.textLightMuted : AppColors.textMuted),
            ),
            tooltip: _tts.sleepMinutesRemaining > 0
                ? (_isEnglish ? 'Timer: ${_tts.sleepMinutesRemaining}m' : 'Hẹn giờ: ${_tts.sleepMinutesRemaining}p')
                : (_isEnglish ? 'Sleep timer' : 'Hẹn giờ tắt'),
            onPressed: _showSleepTimerDialog,
          ),

          // Stop button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: _isEnglish ? 'Close player' : 'Đóng thanh đọc',
            onPressed: () => _tts.stop(),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isEnglish ? 'Sleep Timer' : 'Hẹn Giờ Tắt Sách Nói'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(_isEnglish ? '15 minutes' : '15 phút'),
                onTap: () {
                  _tts.setSleepTimer(15);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_isEnglish ? '30 minutes' : '30 phút'),
                onTap: () {
                  _tts.setSleepTimer(30);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_isEnglish ? '45 minutes' : '45 phút'),
                onTap: () {
                  _tts.setSleepTimer(45);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_isEnglish ? 'Turn off timer' : 'Tắt hẹn giờ'),
                onTap: () {
                  _tts.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
