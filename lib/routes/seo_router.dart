enum SeoRouteType {
  home,
  toc,
  podcast,
  notes,
  settings,
  search,
  reader,
}

class ParsedSeoRoute {
  final SeoRouteType type;
  final bool isEnglish;
  final String? sectionId;
  final int tabIndex;
  final int paragraphIndex;

  const ParsedSeoRoute({
    required this.type,
    required this.isEnglish,
    this.sectionId,
    this.tabIndex = 0,
    this.paragraphIndex = -1,
  });
}

class SeoRouter {
  static const String siteBaseUrl = 'https://sach.khoahoctamlinh.vn';
  // --- Tab Index to URL ---
  static String getTabUrl(int tabIndex, bool isEnglish) {
    if (isEnglish) {
      switch (tabIndex) {
        case 0:
          return '/en';
        case 1:
          return '/en/contents';
        case 2:
          return '/en/podcast';
        case 3:
          return '/en/notes';
        case 4:
          return '/en/settings';
        default:
          return '/en';
      }
    } else {
      switch (tabIndex) {
        case 0:
          return '/vi';
        case 1:
          return '/vi/muc-luc';
        case 2:
          return '/vi/podcast';
        case 3:
          return '/vi/ghi-chu';
        case 4:
          return '/vi/cai-dat';
        default:
          return '/vi';
      }
    }
  }

  // --- Tab Titles ---
  static String getTabTitle(int tabIndex, bool isEnglish) {
    if (isEnglish) {
      switch (tabIndex) {
        case 0:
          return 'The Science of Spirituality - Hoang Nhat Minh | Two Languages, One Truth';
        case 1:
          return 'Table of Contents (173 Sections) | The Science of Spirituality';
        case 2:
          return 'Audiobooks & Podcasts | The Science of Spirituality';
        case 3:
          return 'My Notes & Highlights | The Science of Spirituality';
        case 4:
          return 'Reader & Audio Settings | The Science of Spirituality';
        default:
          return 'The Science of Spirituality';
      }
    } else {
      switch (tabIndex) {
        case 0:
          return 'Khoa Học Tâm Linh - Hoàng Nhật Minh | Hành trình tìm lại chính mình';
        case 1:
          return 'Mục Lục Toàn Bộ Sách (173 Mục) | Khoa Học Tâm Linh';
        case 2:
          return 'Sách Nói & Podcast Chữa Lành | Khoa Học Tâm Linh';
        case 3:
          return 'Ghi Chú & Đánh Dấu Sách | Khoa Học Tâm Linh';
        case 4:
          return 'Cài Đặt Đọc Sách & Giọng Đọc | Khoa Học Tâm Linh';
        default:
          return 'Khoa Học Tâm Linh';
      }
    }
  }

  // --- Chapter / Section URL ---
  static String getReaderUrl(String sectionId, bool isEnglish, {int? paragraphIndex}) {
    final cleanId = sectionId.trim().replaceAll('/', '');
    final base = isEnglish ? '/en/chapter/$cleanId' : '/vi/chuong/$cleanId';
    if (paragraphIndex != null && paragraphIndex >= 0) {
      return '$base?p=$paragraphIndex';
    }
    return base;
  }

  // --- Absolute Chapter / Quote URL for sharing ---
  static String getFullReaderUrl(String sectionId, bool isEnglish, {int? paragraphIndex}) {
    return '$siteBaseUrl${getReaderUrl(sectionId, isEnglish, paragraphIndex: paragraphIndex)}';
  }

  // --- Chapter / Section Title ---
  static String getReaderTitle(String sectionTitle, bool isEnglish) {
    return isEnglish
        ? '$sectionTitle | The Science of Spirituality'
        : '$sectionTitle | Khoa Học Tâm Linh';
  }

  // --- Search URL & Title ---
  static String getSearchUrl(bool isEnglish) => isEnglish ? '/en/search' : '/vi/tim-kiem';
  static String getSearchTitle(bool isEnglish) =>
      isEnglish ? 'Search Book | The Science of Spirituality' : 'Tìm Kiếm Trong Sách | Khoa Học Tâm Linh';

  // --- Parse incoming URL path ---
  static ParsedSeoRoute parsePath(String rawPath) {
    final uri = Uri.tryParse(rawPath);
    final path = (uri != null ? uri.path : rawPath).trim();

    int paragraphIndex = -1;
    if (uri != null) {
      final pParam = uri.queryParameters['p'] ?? uri.queryParameters['paragraph'];
      if (pParam != null) {
        paragraphIndex = int.tryParse(pParam) ?? -1;
      }
      if (paragraphIndex < 0 && uri.fragment.isNotEmpty) {
        final frag = uri.fragment.replaceAll(RegExp(r'^(p=|p-|paragraph=|p)'), '');
        paragraphIndex = int.tryParse(frag) ?? -1;
      }
    }

    // Default to Vietnamese if empty or root
    if (path.isEmpty || path == '/') {
      return const ParsedSeoRoute(type: SeoRouteType.home, isEnglish: false, tabIndex: 0);
    }

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      return const ParsedSeoRoute(type: SeoRouteType.home, isEnglish: false, tabIndex: 0);
    }

    final langPrefix = segments[0].toLowerCase();
    final isEnglish = langPrefix == 'en';
    final isVietnamese = langPrefix == 'vi';

    // If only '/vi' or '/en'
    if (segments.length == 1) {
      if (isEnglish) {
        return const ParsedSeoRoute(type: SeoRouteType.home, isEnglish: true, tabIndex: 0);
      }
      return const ParsedSeoRoute(type: SeoRouteType.home, isEnglish: false, tabIndex: 0);
    }

    final sectionKey = segments[1].toLowerCase();

    // Reader: /vi/chuong/:id or /en/chapter/:id
    if (sectionKey == 'chuong' || sectionKey == 'chapter' || sectionKey == 'read') {
      final sectionId = segments.length > 2 ? segments.sublist(2).join('/') : 'preface';
      return ParsedSeoRoute(
        type: SeoRouteType.reader,
        isEnglish: isEnglish,
        sectionId: sectionId,
        tabIndex: 1,
        paragraphIndex: paragraphIndex,
      );
    }

    // Table of contents: /vi/muc-luc or /en/contents
    if (sectionKey == 'muc-luc' || sectionKey == 'contents' || sectionKey == 'book' || sectionKey == 'toc') {
      return ParsedSeoRoute(type: SeoRouteType.toc, isEnglish: isEnglish, tabIndex: 1);
    }

    // Podcast: /vi/podcast or /en/podcast
    if (sectionKey == 'podcast' || sectionKey == 'audio' || sectionKey == 'sach-noi') {
      return ParsedSeoRoute(type: SeoRouteType.podcast, isEnglish: isEnglish, tabIndex: 2);
    }

    // Notes: /vi/ghi-chu or /en/notes
    if (sectionKey == 'ghi-chu' || sectionKey == 'notes' || sectionKey == 'highlights') {
      return ParsedSeoRoute(type: SeoRouteType.notes, isEnglish: isEnglish, tabIndex: 3);
    }

    // Settings: /vi/cai-dat or /en/settings
    if (sectionKey == 'cai-dat' || sectionKey == 'settings') {
      return ParsedSeoRoute(type: SeoRouteType.settings, isEnglish: isEnglish, tabIndex: 4);
    }

    // Search: /vi/tim-kiem or /en/search
    if (sectionKey == 'tim-kiem' || sectionKey == 'search') {
      return ParsedSeoRoute(type: SeoRouteType.search, isEnglish: isEnglish, tabIndex: 0);
    }

    // Default fallback to home
    return ParsedSeoRoute(
      type: SeoRouteType.home,
      isEnglish: isEnglish || (!isVietnamese && false),
      tabIndex: 0,
    );
  }

  // --- Translate current path to another language ---
  static String translatePath(String currentPath, bool targetIsEnglish) {
    final parsed = parsePath(currentPath);
    switch (parsed.type) {
      case SeoRouteType.home:
        return getTabUrl(0, targetIsEnglish);
      case SeoRouteType.toc:
        return getTabUrl(1, targetIsEnglish);
      case SeoRouteType.podcast:
        return getTabUrl(2, targetIsEnglish);
      case SeoRouteType.notes:
        return getTabUrl(3, targetIsEnglish);
      case SeoRouteType.settings:
        return getTabUrl(4, targetIsEnglish);
      case SeoRouteType.search:
        return getSearchUrl(targetIsEnglish);
      case SeoRouteType.reader:
        return getReaderUrl(parsed.sectionId ?? 'preface', targetIsEnglish);
    }
  }
}
