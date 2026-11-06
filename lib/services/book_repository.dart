import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_section.dart';
import '../models/toc_item.dart';
import '../models/quote_item.dart';
import '../models/podcast_item.dart';

class SearchResult {
  final TocItem section;
  final int paragraphIndex;
  final String matchedText;
  final String snippet;

  SearchResult({
    required this.section,
    required this.paragraphIndex,
    required this.matchedText,
    required this.snippet,
  });
}

class BookRepository {
  static final BookRepository _instance = BookRepository._internal();
  factory BookRepository() => _instance;
  BookRepository._internal();

  List<BookSection> _sections = [];
  List<TocItem> _toc = [];
  List<QuoteItem> _quotes = [];
  List<PodcastItem> _podcasts = [];

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<BookSection> get sections => _sections;
  List<TocItem> get toc => _toc;
  List<QuoteItem> get quotes => _quotes;
  List<PodcastItem> get podcasts => _podcasts;

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      // Load TOC
      final tocStr = await rootBundle.loadString('assets/data/toc.json');
      final tocJson = jsonDecode(tocStr) as List<dynamic>;
      _toc = tocJson.map((e) => TocItem.fromJson(e as Map<String, dynamic>)).toList();

      // Load Sections
      final secStr = await rootBundle.loadString('assets/data/book_sections.json');
      final secJson = jsonDecode(secStr) as List<dynamic>;
      _sections = secJson.map((e) => BookSection.fromJson(e as Map<String, dynamic>)).toList();

      // Load Quotes
      final quotesStr = await rootBundle.loadString('assets/data/quotes.json');
      final quotesJson = jsonDecode(quotesStr) as List<dynamic>;
      _quotes = quotesJson.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>)).toList();

      // Load Podcasts
      final podStr = await rootBundle.loadString('assets/data/podcasts.json');
      final podJson = jsonDecode(podStr) as List<dynamic>;
      _podcasts = podJson.map((e) => PodcastItem.fromJson(e as Map<String, dynamic>)).toList();

      _isLoaded = true;
    } catch (e) {
      // ignore: avoid_print
      print('Error loading book repository: $e');
    }
  }

  BookSection? getSectionById(String id) {
    try {
      return _sections.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  TocItem? getTocById(String id) {
    try {
      return _toc.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  BookSection? getNextSection(String currentId) {
    final idx = _sections.indexWhere((s) => s.id == currentId);
    if (idx >= 0 && idx < _sections.length - 1) {
      return _sections[idx + 1];
    }
    return null;
  }

  BookSection? getPrevSection(String currentId) {
    final idx = _sections.indexWhere((s) => s.id == currentId);
    if (idx > 0) {
      return _sections[idx - 1];
    }
    return null;
  }

  List<TocItem> getTocByCategory(String category) {
    if (category == 'all') return _toc;
    return _toc.where((t) => t.category == category).toList();
  }

  List<SearchResult> search(String query, bool isEnglish) {
    if (query.trim().isEmpty) return [];
    final cleanQuery = query.toLowerCase().trim();
    final results = <SearchResult>[];

    for (var section in _sections) {
      final paras = section.getParagraphs(isEnglish);
      final tocItem = getTocById(section.id) ??
          TocItem(
            id: section.id,
            order: 0,
            category: section.category,
            num: section.num,
            titleVi: section.titleVi,
            titleEn: section.titleEn,
            paragraphsCountVi: section.paragraphsVi.length,
            paragraphsCountEn: section.paragraphsEn.length,
          );

      // Search in title
      final title = section.getTitle(isEnglish);
      if (title.toLowerCase().contains(cleanQuery)) {
        results.add(SearchResult(
          section: tocItem,
          paragraphIndex: 0,
          matchedText: title,
          snippet: title,
        ));
      }

      // Search in paragraphs
      for (int i = 0; i < paras.length; i++) {
        final p = paras[i];
        if (p.toLowerCase().contains(cleanQuery)) {
          // create snippet
          final matchIdx = p.toLowerCase().indexOf(cleanQuery);
          final start = (matchIdx - 40).clamp(0, p.length);
          final end = (matchIdx + cleanQuery.length + 60).clamp(0, p.length);
          String snippet = p.substring(start, end);
          if (start > 0) snippet = '...' + snippet;
          if (end < p.length) snippet = snippet + '...';

          results.add(SearchResult(
            section: tocItem,
            paragraphIndex: i,
            matchedText: p,
            snippet: snippet,
          ));
        }
      }
    }
    return results;
  }
}
