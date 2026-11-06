class QuoteItem {
  final String textVi;
  final String textEn;
  final String sourceVi;
  final String sourceEn;
  final String category;

  QuoteItem({
    required this.textVi,
    this.textEn = '',
    required this.sourceVi,
    this.sourceEn = '',
    required this.category,
  });

  String getText(bool isEnglish) => isEnglish && textEn.isNotEmpty ? textEn : textVi;
  String getSource(bool isEnglish) => isEnglish && sourceEn.isNotEmpty ? sourceEn : sourceVi;

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      textVi: json['text_vi'] as String? ?? '',
      textEn: json['text_en'] as String? ?? '',
      sourceVi: json['source_vi'] as String? ?? '',
      sourceEn: json['source_en'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}
