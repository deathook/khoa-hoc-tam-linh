class SeoService {
  static void init() {}

  static void updateUrl(
    String path, {
    String? title,
    String? description,
    String? image,
    bool replace = false,
  }) {}

  static void listenPopState(Function(String path) onPop) {}

  static String getCurrentPath() => '/';
}
