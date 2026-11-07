import 'package:flutter/material.dart';

/// Removes Vietnamese diacritics / tones from a string while preserving character count 1:1.
String removeVietnameseTones(String str) {
  var result = str.toLowerCase();
  result = result.replaceAll(RegExp(r'[àáảãạăằắẳẵặâầấẩẫậ]'), 'a');
  result = result.replaceAll(RegExp(r'[èéẻẽẹêềếểễệ]'), 'e');
  result = result.replaceAll(RegExp(r'[ìíỉĩị]'), 'i');
  result = result.replaceAll(RegExp(r'[òóỏõọôồốổỗộơờớởỡợ]'), 'o');
  result = result.replaceAll(RegExp(r'[ùúủũụưừứửữự]'), 'u');
  result = result.replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y');
  result = result.replaceAll(RegExp(r'[đ]'), 'd');
  return result;
}

class _MatchRange {
  int start;
  int end;
  _MatchRange(this.start, this.end);
}

/// Builds a list of [TextSpan]s where keyword occurrences are highlighted.
List<TextSpan> buildHighlightedSpans({
  required String text,
  required String query,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  if (query.trim().isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final normText = removeVietnameseTones(text);
  final cleanQuery = query.trim();
  final normQuery = removeVietnameseTones(cleanQuery);

  final intervals = <_MatchRange>[];

  // 1. Try full phrase match first
  int start = 0;
  while (start < normText.length) {
    final idx = normText.indexOf(normQuery, start);
    if (idx == -1) break;
    intervals.add(_MatchRange(idx, idx + normQuery.length));
    start = idx + normQuery.length;
  }

  // 2. Also match individual tokens (words) if multi-word
  final words = normQuery
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1)
      .toList();

  for (final w in words) {
    int wStart = 0;
    while (wStart < normText.length) {
      final idx = normText.indexOf(w, wStart);
      if (idx == -1) break;
      intervals.add(_MatchRange(idx, idx + w.length));
      wStart = idx + w.length;
    }
  }

  if (intervals.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  // Merge overlapping intervals
  intervals.sort((a, b) => a.start.compareTo(b.start));
  final merged = <_MatchRange>[];
  for (final interval in intervals) {
    if (merged.isEmpty) {
      merged.add(interval);
    } else {
      final last = merged.last;
      if (interval.start <= last.end) {
        if (interval.end > last.end) last.end = interval.end;
      } else {
        merged.add(interval);
      }
    }
  }

  // Build TextSpan segments
  final spans = <TextSpan>[];
  int currentIndex = 0;
  for (final m in merged) {
    final mStart = m.start.clamp(0, text.length);
    final mEnd = m.end.clamp(0, text.length);

    if (mStart > currentIndex) {
      spans.add(TextSpan(
        text: text.substring(currentIndex, mStart),
        style: baseStyle,
      ));
    }
    if (mEnd > mStart) {
      spans.add(TextSpan(
        text: text.substring(mStart, mEnd),
        style: highlightStyle,
      ));
    }
    currentIndex = mEnd;
  }

  if (currentIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(currentIndex),
      style: baseStyle,
    ));
  }

  return spans;
}
