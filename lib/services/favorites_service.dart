import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_item.dart';
import 'app_group_service.dart';

class FavoritesService {
  static const _key = 'favorites_v2';

  Future<List<FavoriteItem>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map(FavoriteItem.decode).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addFavorite(String text, String styleName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final existing = raw.map(FavoriteItem.decode).toList();
    if (existing.any((e) => e.text == text)) return;
    final item = FavoriteItem(text: text, styleName: styleName);
    raw.add(item.encode());
    await prefs.setStringList(_key, raw);
    await _syncToAppGroup(raw);
  }

  Future<void> removeFavorite(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final filtered =
        raw.map(FavoriteItem.decode).where((e) => e.text != text).toList();
    final encodedList = filtered.map((e) => e.encode()).toList();
    await prefs.setStringList(_key, encodedList);
    await _syncToAppGroup(encodedList);
  }

  Future<bool> isFavorite(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map(FavoriteItem.decode).any((e) => e.text == text);
  }

  Future<void> _syncToAppGroup(List<String> raw) async {
    await AppGroupService.syncFavorites(raw);
  }
}
