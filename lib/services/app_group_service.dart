import 'package:flutter/services.dart';

class AppGroupService {
  static const _channel = MethodChannel('com.yunajung.fonki/appgroup');

  static Future<void> syncFavorites(List<String> jsonItems) async {
    try {
      await _channel.invokeMethod('syncFavorites', {'items': jsonItems});
    } on PlatformException {
      // 키보드 익스텐션 미설치 시 무시
    }
  }

  static Future<List<String>> getCustomPhrases() async {
    try {
      final result = await _channel.invokeMethod<List>('getCustomPhrases');
      return result?.cast<String>() ?? [];
    } on PlatformException {
      return [];
    }
  }

  static Future<void> addCustomPhrase(String phrase) async {
    try {
      await _channel.invokeMethod('addCustomPhrase', {'phrase': phrase});
    } on PlatformException {
      // ignore
    }
  }

  static Future<void> deleteCustomPhrase(String phrase) async {
    try {
      await _channel.invokeMethod('deleteCustomPhrase', {'phrase': phrase});
    } on PlatformException {
      // ignore
    }
  }
}
