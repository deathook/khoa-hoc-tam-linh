import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class AppCachedImage extends StatefulWidget {
  final String imageUrlOrAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    Key? key,
    required this.imageUrlOrAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<AppCachedImage> createState() => _AppCachedImageState();
}

class _AppCachedImageState extends State<AppCachedImage> {
  final ImageCacheService _cacheService = ImageCacheService();

  File? _localFile;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant AppCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrlOrAsset != widget.imageUrlOrAsset) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final src = widget.imageUrlOrAsset;
    if (src.isEmpty) return;

    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _localFile = null;
        });
      }
      return;
    }

    if (src.startsWith('assets/')) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _localFile = null;
        });
      }
      return;
    }

    // Network image: check local cache first
    final cached = await _cacheService.getLocalImageFile(src);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _localFile = cached;
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    // Need download
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    final downloaded = await _cacheService.downloadAndCacheImage(src);
    if (mounted) {
      setState(() {
        _localFile = downloaded;
        _isLoading = false;
        _hasError = downloaded == null;
      });
    }
  }

  bool get _isThumbnail {
    if (widget.width != null && widget.width! < 90) return true;
    if (widget.height != null && widget.height! < 90) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (kIsWeb) {
      if (widget.imageUrlOrAsset.startsWith('assets/')) {
        imageContent = Image.asset(
          widget.imageUrlOrAsset,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          cacheWidth: _isThumbnail ? 160 : null,
          errorBuilder: (_, __, ___) => _buildErrorWidget(),
        );
      } else {
        // On web, transform absolute https://khoahoctamlinh.vn/app/ to relative /app/ for same-origin proxy
        String webUrl = widget.imageUrlOrAsset;
        if (webUrl.startsWith('https://khoahoctamlinh.vn/app/')) {
          webUrl = webUrl.replaceFirst('https://khoahoctamlinh.vn/app/', '/app/');
        }

        imageContent = Image.network(
          webUrl,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          cacheWidth: _isThumbnail ? 160 : null,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return widget.placeholder ?? _buildPlaceholder();
          },
          errorBuilder: (_, error, stack) => _buildErrorWidget(),
        );
      }
    } else if (widget.imageUrlOrAsset.startsWith('assets/')) {
      imageContent = Image.asset(
        widget.imageUrlOrAsset,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        cacheWidth: _isThumbnail ? 160 : null,
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    } else if (_localFile != null) {
      imageContent = Image.file(
        _localFile!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        cacheWidth: _isThumbnail ? 160 : null,
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    } else if (_isLoading) {
      imageContent = widget.placeholder ?? _buildPlaceholder();
    } else if (_hasError || _localFile == null) {
      imageContent = widget.errorWidget ?? _buildErrorWidget();
    } else {
      imageContent = widget.errorWidget ?? _buildErrorWidget();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildPlaceholder() {
    if (_isThumbnail) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: widget.borderRadius,
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }

    final isEn = StorageService().isEnglish;
    return Container(
      width: widget.width,
      height: widget.height ?? 240,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: widget.borderRadius,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            isEn ? 'Loading illustration from server...' : 'Đang tải hình ảnh minh họa từ máy chủ...',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (_isThumbnail) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: widget.borderRadius,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          size: 20,
          color: Colors.grey.shade400,
        ),
      );
    }

    final isEn = StorageService().isEnglish;
    return InkWell(
      onTap: _loadImage,
      child: Container(
        width: widget.width,
        height: widget.height ?? 220,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: widget.borderRadius,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_download_outlined, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              isEn ? 'Could not load illustration' : 'Chưa tải được hình ảnh minh họa',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 4),
            Text(
              isEn ? 'Tap here to retry loading' : 'Chạm vào đây để tải lại',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
