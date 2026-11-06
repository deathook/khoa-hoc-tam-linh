class UserHighlight {
  final String id;
  final String sectionId;
  final String sectionTitle;
  final int paragraphIndex;
  final String text;
  final int colorValue; // ARGB int
  final DateTime createdAt;

  UserHighlight({
    required this.id,
    required this.sectionId,
    required this.sectionTitle,
    required this.paragraphIndex,
    required this.text,
    required this.colorValue,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sectionId': sectionId,
        'sectionTitle': sectionTitle,
        'paragraphIndex': paragraphIndex,
        'text': text,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserHighlight.fromJson(Map<String, dynamic> json) => UserHighlight(
        id: json['id'] as String,
        sectionId: json['sectionId'] as String,
        sectionTitle: json['sectionTitle'] as String? ?? '',
        paragraphIndex: json['paragraphIndex'] as int,
        text: json['text'] as String,
        colorValue: json['colorValue'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class UserNote {
  final String id;
  final String sectionId;
  final String sectionTitle;
  final int paragraphIndex;
  final String targetText;
  final String noteContent;
  final DateTime createdAt;

  UserNote({
    required this.id,
    required this.sectionId,
    required this.sectionTitle,
    required this.paragraphIndex,
    required this.targetText,
    required this.noteContent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sectionId': sectionId,
        'sectionTitle': sectionTitle,
        'paragraphIndex': paragraphIndex,
        'targetText': targetText,
        'noteContent': noteContent,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserNote.fromJson(Map<String, dynamic> json) => UserNote(
        id: json['id'] as String,
        sectionId: json['sectionId'] as String,
        sectionTitle: json['sectionTitle'] as String? ?? '',
        paragraphIndex: json['paragraphIndex'] as int,
        targetText: json['targetText'] as String,
        noteContent: json['noteContent'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
