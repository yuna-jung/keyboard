import 'package:flutter/services.dart';

class AppGroupService {
  static const _channel = MethodChannel('com.yourapp.fontkeyboard/appgroup');

  static Future<void> syncFavorites(List<String> jsonItems) async {
    try {
      await _channel.invokeMethod('syncFavorites', {'items': jsonItems});
    } on PlatformException {
      // 키보드 익스텐션 미설치 시 무시
    }
  }
}
