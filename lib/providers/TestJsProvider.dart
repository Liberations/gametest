import 'dart:convert' show jsonDecode;

import 'package:flutter/foundation.dart';
import 'package:giftgame/providers/http_helper.dart' as httpHelper show httpGet;

class TestJsProvider with ChangeNotifier {
  // URL parameters from web (uid, token)
  String? _uid;
  String? _token;
  String? _lang;

  // User info from API
  String? _userAvatar;
  String? _userNickname;
  bool _isLoadingUserInfo = false;

  // Public getter for UI
  bool get isLoadingUserInfo => _isLoadingUserInfo;

  String? get uid => _uid;

  String? get token => _token;

  String? get userAvatar => _userAvatar;

  String? get userNickname => _userNickname;

  String? get lang => _lang;

  // Set language and optionally refresh user info
  void setLang(String? newLang) {
    if (newLang == null) return;
    if (_lang == newLang) return;
    _lang = newLang;
    notifyListeners();
    // If we already have uid/token, refresh user info with new language
    if (_uid != null && _token != null) {
      fetchUserInfo();
    }
  }

  void setUrlParams(String? lang,String? uid, String? token) {
    _uid = uid;
    _token = token;
    // Set global language, default to English if not provided
    _lang = lang ?? 'en';
    notifyListeners();
    // Fetch user info when params are set
    if (uid != null && token != null) {
      fetchUserInfo();
    }
  }

  Future<void> fetchUserInfo() async {
    debugPrint('fetchUserInfo $_uid $_token');
    if (_uid == null || _token == null) return;

    _isLoadingUserInfo = true;
    notifyListeners();

    try {
      final response = await httpHelper.httpGet(
        'https://app.test.horovoice.com/api/charge_reward_api/get_activity_user_rank',
        {
          'uid': _uid!,
          'token': _token!,
          'event_id': '14',
          'gift_id': '409',
          'type': '2',
          'language': _lang ?? 'en',
        },
      );
      debugPrint('fetchUserInfo ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 1 && data['data'] != null) {
          _userAvatar = data['data']['user']['avatar'];
          _userNickname = data['data']['user']['user_nickname'];
          debugPrint(
            'User info loaded: avatar=$_userAvatar, nickname=$_userNickname',
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user info: $e');
    } finally {
      _isLoadingUserInfo = false;
      notifyListeners();
    }
  }
}
