class FontStyleModel {
  final String name;
  final String Function(String) convert;
  final bool isPremium;

  const FontStyleModel({
    required this.name,
    required this.convert,
    this.isPremium = true,
  });
}
