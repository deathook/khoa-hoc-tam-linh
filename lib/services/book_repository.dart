import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_section.dart';
import '../models/toc_item.dart';
import '../models/quote_item.dart';
import '../models/podcast_item.dart';
import '../utils/vietnamese_utils.dart';

class SearchResult {
  final TocItem section;
  final int paragraphIndex;
  final String matchedText;
  final String snippet;
  final int score;

  SearchResult({
    required this.section,
    required this.paragraphIndex,
    required this.matchedText,
    required this.snippet,
    this.score = 0,
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

  static _SearchMatchScore? _evaluateSearchMatch(
      String text, String normQuery, List<String> queryWords) {
    if (text.isEmpty || normQuery.isEmpty) return null;
    final normText = removeVietnameseTones(text);

    // 1. Exact full phrase match
    final fullIdx = normText.indexOf(normQuery);
    if (fullIdx != -1) {
      return _SearchMatchScore(100, fullIdx);
    }

    // 2. Multi-word checks
    if (queryWords.length > 1) {
      int matchedWordCount = 0;
      int firstIdx = -1;
      for (final w in queryWords) {
        final idx = normText.indexOf(w);
        if (idx != -1) {
          matchedWordCount++;
          if (firstIdx == -1 || idx < firstIdx) {
            firstIdx = idx;
          }
        }
      }

      if (matchedWordCount == queryWords.length) {
        // All words matched!
        return _SearchMatchScore(80, firstIdx);
      } else if (matchedWordCount >= 2 &&
          matchedWordCount >= (queryWords.length / 2).ceil()) {
        // Partial words matched!
        return _SearchMatchScore(40 + matchedWordCount * 5, firstIdx);
      }
    } else if (queryWords.length == 1) {
      final idx = normText.indexOf(queryWords[0]);
      if (idx != -1) {
        return _SearchMatchScore(90, idx);
      }
    }

    return null;
  }

  List<SearchResult> search(String query, bool isEnglish) {
    final rawQuery = query.trim();
    if (rawQuery.isEmpty) return [];

    final normQuery = removeVietnameseTones(rawQuery);
    final queryWords = normQuery
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();

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
      final titleMatch = _evaluateSearchMatch(title, normQuery, queryWords);
      if (titleMatch != null) {
        results.add(SearchResult(
          section: tocItem,
          paragraphIndex: 0,
          matchedText: title,
          snippet: title,
          score: titleMatch.score + 50, // Title matches have high priority
        ));
      }

      // Search in paragraphs
      for (int i = 0; i < paras.length; i++) {
        final p = paras[i];
        final match = _evaluateSearchMatch(p, normQuery, queryWords);
        if (match != null) {
          // create snippet around the match
          final matchIdx = match.matchIndex;
          final start = (matchIdx - 40).clamp(0, p.length);
          final end = (matchIdx + normQuery.length + 70).clamp(0, p.length);
          String snippet = p.substring(start, end);
          if (start > 0) snippet = '...' + snippet;
          if (end < p.length) snippet = snippet + '...';

          results.add(SearchResult(
            section: tocItem,
            paragraphIndex: i,
            matchedText: p,
            snippet: snippet,
            score: match.score,
          ));
        }
      }
    }

    // Sort by relevance score descending
    results.sort((a, b) => b.score.compareTo(a.score));

    // Limit to top 150 results for optimal performance
    if (results.length > 150) {
      return results.sublist(0, 150);
    }

    return results;
  }
}

class _SearchMatchScore {
  final int score;
  final int matchIndex;
  _SearchMatchScore(this.score, this.matchIndex);
}
