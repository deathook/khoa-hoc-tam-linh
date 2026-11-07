class TocItem {
  final String id;
  final int order;
  final String category;
  final String num;
  final String titleVi;
  final String titleEn;
  final String? image;
  final String? imageVertical;
  final String? imageVerticalEn;
  final String? imageVerticalThumb;
  final String? imageVerticalThumbEn;
  final int paragraphsCountVi;
  final int paragraphsCountEn;

  TocItem({
    required this.id,
    required this.order,
    required this.category,
    required this.num,
    required this.titleVi,
    required this.titleEn,
    this.image,
    this.imageVertical,
    this.imageVerticalEn,
    this.imageVerticalThumb,
    this.imageVerticalThumbEn,
    required this.paragraphsCountVi,
    required this.paragraphsCountEn,
  });

  factory TocItem.fromJson(Map<String, dynamic> json) {
    return TocItem(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      num: json['num'] as String? ?? '',
      titleVi: json['title_vi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      image: json['image'] as String?,
      imageVertical: json['image_vertical'] as String?,
      imageVerticalEn: json['image_vertical_en'] as String?,
      imageVerticalThumb: json['image_vertical_thumb'] as String? ?? json['image_thumb'] as String?,
      imageVerticalThumbEn: json['image_vertical_thumb_en'] as String? ?? json['image_thumb_en'] as String?,
      paragraphsCountVi: json['paragraphsCountVi'] as int? ?? 0,
      paragraphsCountEn: json['paragraphsCountEn'] as int? ?? 0,
    );
  }

  String getTitle(bool isEnglish) => isEnglish ? (titleEn.isNotEmpty ? titleEn : titleVi) : titleVi;
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

  String getCategoryLabel(bool isEnglish) {
    switch (category) {
      case 'intro':
        return isEnglish ? 'Introduction' : 'Mở đầu';
      case 'part':
        return isEnglish ? 'Main Part' : 'Phần chính';
      case 'chapter':
        return isEnglish ? 'Chapter' : 'Chương';
      case 'realisation':
        return isEnglish ? 'Realisation' : 'Giải ngộ';
      case 'attainment':
        return isEnglish ? 'Attainment' : 'Chứng ngộ';
      case 'reflection':
        return isEnglish ? 'Reflection' : 'Suy ngẫm';
      case 'practice':
        return isEnglish ? 'Practice' : 'Thực hành';
      case 'appendix':
        return isEnglish ? 'Appendix' : 'Phụ lục';
      case 'poem':
        return isEnglish ? 'Poem' : 'Thơ';
      default:
        return isEnglish ? 'Section' : 'Mục';
    }
  }
}
