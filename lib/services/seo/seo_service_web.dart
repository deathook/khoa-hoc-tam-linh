import 'dart:html' as html;

class SeoService {
  static bool _initialized = false;
  static final List<Function(String path)> _popListeners = [];

  static void init() {
    if (_initialized) return;
    _initialized = true;

    html.window.onPopState.listen((event) {
      final currentPath = html.window.location.pathname ?? '/';
      for (final listener in List<Function(String)>.from(_popListeners)) {
        try {
          listener(currentPath);
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
    final path = html.window.location.pathname ?? '/';
    return path.isEmpty ? '/' : path;
  }

  static void updateUrl(
    String path, {
    String? title,
    String? description,
    bool replace = false,
  }) {
    final currentPath = html.window.location.pathname ?? '/';
    final normalizedPath = path.isEmpty ? '/' : (path.startsWith('/') ? path : '/$path');

    if (title != null && title.isNotEmpty) {
      html.document.title = title;
      _setMetaContent('property', 'og:title', title);
      _setMetaContent('name', 'twitter:title', title);
    }

    if (description != null && description.isNotEmpty) {
      _setMetaContent('name', 'description', description);
      _setMetaContent('property', 'og:description', description);
      _setMetaContent('name', 'twitter:description', description);
    }

    final origin = html.window.location.origin;
    if (origin.isNotEmpty) {
      final fullUrl = '$origin$normalizedPath';
      _setMetaContent('property', 'og:url', fullUrl);
    }

    if (currentPath == normalizedPath) {
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
}
