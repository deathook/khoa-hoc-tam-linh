import 'dart:convert';
import 'dart:html' as html;

class SeoService {
  static bool _initialized = false;
  static final List<Function(String path)> _popListeners = [];

  static void init() {
    if (_initialized) return;
    _initialized = true;

    html.window.onPopState.listen((event) {
      final loc = html.window.location;
      final currentPath = '${loc.pathname}${loc.search}${loc.hash}';
      for (final listener in List<Function(String)>.from(_popListeners)) {
        try {
          listener(currentPath.isEmpty ? '/' : currentPath);
        } catch (_) {}
      }
    });
  }

  static void listenPopState(Function(String path) onPop) {
    init();
    if (!_popListeners.contains(onPop)) {
      _popListeners.add(onPop);
    }
  }

  static String getCurrentPath() {
    final loc = html.window.location;
    final path = loc.pathname;
    final search = loc.search;
    final hash = loc.hash;
    final full = '$path$search$hash';
    return full.isEmpty ? '/' : full;
  }

  static void updateUrl(
    String path, {
    String? title,
    String? description,
    String? image,
    bool replace = false,
  }) {
    final loc = html.window.location;
    final currentFullPath = '${loc.pathname}${loc.search}${loc.hash}';
    final normalizedPath = path.isEmpty ? '/' : (path.startsWith('/') ? path : '/$path');

    // Update document title
    if (title != null && title.isNotEmpty) {
      html.document.title = title;
      _setMetaContent('property', 'og:title', title);
      _setMetaContent('name', 'twitter:title', title);
    }

    // Update description
    if (description != null && description.isNotEmpty) {
      final cleanDesc = description.replaceAll('\n', ' ').trim();
      final truncatedDesc = cleanDesc.length > 200 ? '${cleanDesc.substring(0, 197)}...' : cleanDesc;
      _setMetaContent('name', 'description', truncatedDesc);
      _setMetaContent('property', 'og:description', truncatedDesc);
      _setMetaContent('name', 'twitter:description', truncatedDesc);
    }

    // Update language attribute
    if (normalizedPath.startsWith('/en')) {
      html.document.documentElement?.lang = 'en';
    } else {
      html.document.documentElement?.lang = 'vi';
    }

    final origin = html.window.location.origin;
    if (origin.isNotEmpty) {
      final fullUrl = '$origin$normalizedPath';
      _setMetaContent('property', 'og:url', fullUrl);

      // Canonical link
      try {
        var canonical = html.document.querySelector('link[rel="canonical"]');
        if (canonical != null) {
          canonical.setAttribute('href', fullUrl);
        } else {
          final link = html.LinkElement();
          link.setAttribute('rel', 'canonical');
          link.setAttribute('href', fullUrl);
          html.document.head?.append(link);
        }
      } catch (_) {}

      // Open Graph & Twitter Image
      if (image != null && image.isNotEmpty) {
        final fullImg = image.startsWith('http') ? image : '$origin/$image';
        _setMetaContent('property', 'og:image', fullImg);
        _setMetaContent('name', 'twitter:image', fullImg);
      }

      // JSON-LD Structured Data Update
      _updateDynamicJsonLd(fullUrl, title, description);
    }

    if (currentFullPath == normalizedPath) {
      if (replace || (title != null && title.isNotEmpty)) {
        try {
          html.window.history.replaceState(null, title ?? '', normalizedPath);
        } catch (_) {}
      }
      return;
    }

    try {
      if (replace) {
        html.window.history.replaceState(null, title ?? '', normalizedPath);
      } else {
        html.window.history.pushState(null, title ?? '', normalizedPath);
      }
    } catch (_) {}
  }

  static void _setMetaContent(String attribute, String name, String content) {
    try {
      final selector = 'meta[$attribute="$name"]';
      var element = html.document.querySelector(selector);
      if (element != null) {
        element.setAttribute('content', content);
      } else {
        final meta = html.MetaElement();
        meta.setAttribute(attribute, name);
        meta.content = content;
        html.document.head?.append(meta);
      }
    } catch (_) {}
  }

  static void _updateDynamicJsonLd(String url, String? title, String? description) {
    try {
      const scriptId = 'khtl-dynamic-jsonld';
      var script = html.document.getElementById(scriptId) as html.ScriptElement?;
      if (script == null) {
        script = html.ScriptElement();
        script.id = scriptId;
        script.type = 'application/ld+json';
        html.document.head?.append(script);
      }

      final schema = {
        '@context': 'https://schema.org',
        '@type': 'WebPage',
        'name': title ?? 'Khoa Học Tâm Linh',
        'description': description ?? 'Hai ngôn ngữ của một chân lý - Hoàng Nhật Minh',
        'url': url,
        'isPartOf': {
          '@type': 'Book',
          'name': 'Khoa Học Tâm Linh',
          'alternateName': 'The Science of Spirituality',
          'author': {
            '@type': 'Person',
            'name': 'Hoàng Nhật Minh',
          },
          'url': 'https://sach.khoahoctamlinh.vn',
        },
      };

      script.text = jsonEncode(schema);
    } catch (_) {}
  }
}
