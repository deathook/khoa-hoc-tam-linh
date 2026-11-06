class PodcastItem {
  final String id;
  final String language; // 'vi' or 'en'
  final String titleVi;
  final String titleEn;
  final String author;
  final String duration;
  final String category;
  final String categoryEn;
  final String descriptionVi;
  final String descriptionEn;
  final String audioUrl;
  final String? fallbackAudioUrl;
  final String? image;

  PodcastItem({
    required this.id,
    this.language = 'vi',
    required this.titleVi,
    required this.titleEn,
    required this.author,
    required this.duration,
    required this.category,
    this.categoryEn = '',
    required this.descriptionVi,
    required this.descriptionEn,
    required this.audioUrl,
    this.fallbackAudioUrl,
    this.image,
  });

  factory PodcastItem.fromJson(Map<String, dynamic> json) {
    return PodcastItem(
      id: json['id'] as String? ?? '',
      language: json['language'] as String? ?? 'vi',
      titleVi: json['title_vi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      author: json['author'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      category: json['category'] as String? ?? '',
      categoryEn: json['category_en'] as String? ?? '',
      descriptionVi: json['description_vi'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      fallbackAudioUrl: json['fallback_audio_url'] as String?,
      image: json['image'] as String?,
    );
  }

  String getTitle(bool isEnglish) => isEnglish ? (titleEn.isNotEmpty ? titleEn : titleVi) : titleVi;
  String getDescription(bool isEnglish) => isEnglish ? (descriptionEn.isNotEmpty ? descriptionEn : descriptionVi) : descriptionVi;
  String getCategory(bool isEnglish) => isEnglish && categoryEn.isNotEmpty ? categoryEn : category;
}
