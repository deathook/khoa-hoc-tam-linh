import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  Directory? _cacheDir;

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/khtl_images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _getFilename(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        final isThumb = url.contains('/thumb/') || url.contains('_thumb');
        final prefix = isThumb ? 'thumb_' : '';
        return '$prefix${segments.last}';
      }
    } catch (_) {}
    return 'image_${url.hashCode}.webp';
  }

  Future<File?> getLocalImageFile(String url) async {
    if (url.isEmpty) return null;
    try {
      final dir = await _getCacheDir();
      final filename = _getFilename(url);
      final localFile = File('${dir.path}/$filename');
      if (await localFile.exists() && await localFile.length() > 1024) {
        return localFile;
      }
    } catch (_) {}
    return null;
  }

  Future<File?> downloadAndCacheImage(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    try {
      final dir = await _getCacheDir();
      final filename = _getFilename(url);
      final localFile = File('${dir.path}/$filename');

      // Check if already exists
      if (await localFile.exists() && await localFile.length() > 1024) {
        return localFile;
      }

      // Download from web
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading image ($url): $e');
      }
    }
    return null;
  }

  Future<int> getCachedImageCount() async {
    try {
      final dir = await _getCacheDir();
      if (!await dir.exists()) return 0;
      final files = dir.listSync().whereType<File>();
      return files.length;
    } catch (_) {
      return 0;
    }
  }

  Future<double> getCachedSizeMB() async {
    try {
      final dir = await _getCacheDir();
      if (!await dir.exists()) return 0.0;
      final files = dir.listSync().whereType<File>();
      int totalBytes = 0;
      for (var f in files) {
        totalBytes += f.lengthSync();
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> prefetchAllImages({
    required List<String> urls,
    required void Function(int completed, int total) onProgress,
    bool Function()? isCancelled,
  }) async {
    int count = 0;
    final validUrls = urls.where((u) => u.isNotEmpty && u.startsWith('http')).toList();
    final total = validUrls.length;
    for (final url in validUrls) {
      if (isCancelled != null && isCancelled()) break;
      await downloadAndCacheImage(url);
      count++;
      onProgress(count, total);
    }
  }

  Future<void> clearCache() async {
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _cacheDir = null;
      }
    } catch (_) {}
  }
}
