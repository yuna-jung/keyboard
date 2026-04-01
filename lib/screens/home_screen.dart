import 'package:flutter/material.dart';
import 'fonts_screen.dart';
import 'emoticon_screen.dart';
import 'special_chars_screen.dart';
import 'favorites_screen.dart';

const _pink = Color(0xFFFF6B9D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _fontsKey = GlobalKey<FontsScreenState>();
  final _favoritesKey = GlobalKey<FavoritesScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      FontsScreen(key: _fontsKey),
      const EmoticonScreen(),
      const SpecialCharsScreen(),
      FavoritesScreen(key: _favoritesKey),
    ];

    // FontsScreen 즐겨찾기 변경 → FavoritesScreen 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fontsKey.currentState?.onFavoritesChanged = () {
        _favoritesKey.currentState?.reload();
      };
    });
  }

  void _onTabTapped(int index) {
    // Favorites 탭으로 이동 시 항상 새로고침
    if (index == 3) {
      _favoritesKey.currentState?.reload();
    }
    // Fonts 탭으로 돌아올 때 즐겨찾기 상태 동기화
    if (index == 0) {
      _fontsKey.currentState?.reloadFavorites();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Keyboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: 설정 화면 연결
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            activeIcon: Icon(Icons.text_fields),
            label: 'Fonts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_emotions_outlined),
            activeIcon: Icon(Icons.emoji_emotions),
            label: '이모티콘',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            activeIcon: Icon(Icons.star),
            label: '특수문자',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite, color: _pink),
            label: '즐겨찾기',
          ),
        ],
      ),
    );
  }
}
