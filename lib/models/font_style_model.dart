class FontStyleModel {
  final String name;
  final String Function(String) convert;

  const FontStyleModel({
    required this.name,
    required this.convert,
  });
}
