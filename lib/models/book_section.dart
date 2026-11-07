import 'package:flutter/foundation.dart';

class BookSection {
  final String id;
  final String category;
  final String num;
  final String titleVi;
  final String titleEn;
  final String? image;
  final String? imageVertical;
  final String? imageVerticalEn;
  final String? imageVerticalThumb;
  final String? imageVerticalThumbEn;
  final String? imageCaption;
  final List<String> paragraphsVi;
  final List<String> paragraphsEn;

  BookSection({
    required this.id,
    required this.category,
    required this.num,
    required this.titleVi,
    required this.titleEn,
    this.image,
    this.imageVertical,
    this.imageVerticalEn,
    this.imageVerticalThumb,
    this.imageVerticalThumbEn,
    this.imageCaption,
    required this.paragraphsVi,
    required this.paragraphsEn,
  });

  factory BookSection.fromJson(Map<String, dynamic> json) {
    return BookSection(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      num: json['num'] as String? ?? '',
      titleVi: json['title_vi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      image: json['image'] as String?,
      imageVertical: json['image_vertical'] as String?,
      imageVerticalEn: json['image_vertical_en'] as String?,
      imageVerticalThumb: json['image_vertical_thumb'] as String? ?? json['image_thumb'] as String?,
      imageVerticalThumbEn: json['image_vertical_thumb_en'] as String? ?? json['image_thumb_en'] as String?,
      imageCaption: json['image_caption'] as String?,
      paragraphsVi: (json['paragraphs_vi'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      paragraphsEn: (json['paragraphs_en'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  String getTitle(bool isEnglish) => isEnglish ? (titleEn.isNotEmpty ? titleEn : titleVi) : titleVi;
  List<String> getParagraphs(bool isEnglish) => isEnglish ? (paragraphsEn.isNotEmpty ? paragraphsEn : paragraphsVi) : paragraphsVi;
  String? getImageVertical(bool isEnglish) => isEnglish ? (imageVerticalEn ?? imageVertical) : imageVertical;

  String? getImageVerticalThumb(bool isEnglish) {
    final explicit = isEnglish ? (imageVerticalThumbEn ?? imageVerticalThumb) : imageVerticalThumb;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final orig = getImageVertical(isEnglish);
    if (orig == null) return null;
    if (orig.contains('/vertical/')) {
      return orig.replaceFirst('/vertical/', '/vertical/thumb/');
    }
    if (orig.contains('/vertical_en/')) {
      return orig.replaceFirst('/vertical_en/', '/vertical_en/thumb/');
    }
    return orig;
  }

  String? getIllustration(bool isEnglish) {
    final vert = getImageVertical(isEnglish);
    if (vert == null) return null;
    if (kIsWeb) {
      return vert.replaceAll('/vertical/', '/horizontal/').replaceAll('/vertical_en/', '/horizontal/');
    }
    return vert;
  }
}
