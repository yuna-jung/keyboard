import 'dart:convert';

class FavoriteItem {
  final String text;
  final String styleName;
  final DateTime createdAt;

  FavoriteItem({
    required this.text,
    required this.styleName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'styleName': styleName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        text: json['text'] as String,
        styleName: json['styleName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String encode() => jsonEncode(toJson());

  static FavoriteItem decode(String source) =>
      FavoriteItem.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
