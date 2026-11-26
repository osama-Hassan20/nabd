import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String token = 'token';
const String skipLogin = 'skip';
const String userPrefs = 'user';
const String prefsOnBoarding = 'onBoarding';
const String language = 'language';

class AppSharedPreferences {
  static SharedPreferences? _prefs;
  static set sharedPreferences(SharedPreferences val) => _prefs = val;
  static SharedPreferences get sharedPreferences {
    if (_prefs == null) {
      throw StateError('AppSharedPreferences not initialized. Call initialSharedPreference() first.');
    }
    return _prefs!;
  }

  static Future<void> initialSharedPreference() async {
    _prefs = await SharedPreferences.getInstance();
  }

  //***************  set data *********** */
  static Future<void> setString({
    required String value,
    required String key,
  }) async {
    try {
      await _prefs?.setString(key, value);
    } catch (_) {}
  }

  static Future<void> setListString({
    required List<String> value,
    required String key,
  }) async {
    try {
      await _prefs?.setStringList(key, value);
    } catch (_) {}
  }

  static Future<void> setBool({
    required bool value,
    required String key,
  }) async {
    try {
      await _prefs?.setBool(key, value);
    } catch (_) {}
  }

  static Future<void> setInt({required int value, required String key}) async {
    try {
      await _prefs?.setInt(key, value);
    } catch (_) {}
  }

  static Future<void> setDouble({
    required double value,
    required String key,
  }) async {
    try {
      await _prefs?.setDouble(key, value);
    } catch (_) {}
  }

  //************** get data ************* */
  static double? getDouble({required String key}) {
    try {
      return _prefs?.getDouble(key);
    } catch (_) {
      return null;
    }
  }

  static String? getString({required String key}) {
    try {
      return _prefs?.getString(key);
    } catch (_) {
      return null;
    }
  }

  static int? getInt({required String key}) {
    try {
      return _prefs?.getInt(key);
    } catch (_) {
      return null;
    }
  }

  static bool? getBool({required String key}) {
    try {
      return _prefs?.getBool(key);
    } catch (_) {
      return null;
    }
  }

  static List<String>? getStringList({required String key}) {
    try {
      return _prefs?.getStringList(key);
    } catch (_) {
      return null;
    }
  }

  //************** delete data ************* */

  static Future<void> remove({required String key}) async {
    try {
      await _prefs?.remove(key);
    } catch (_) {}
  }

  static Future<void> setAppLang({String? lang}) async {
    try {
      await _prefs?.setString("lang", lang ?? "ar");
    } catch (_) {}
  }

  static String getAppLang() {
    try {
      return _prefs?.getString("lang") ?? "ar";
    } catch (_) {
      return "ar";
    }
  }

  static Future<void> clearAll() async {
    final userName = AppSharedPreferences.getString(key: AppConstants.userName);

    final password = AppSharedPreferences.getString(
      key: AppConstants.remeberMePassword,
    );
    bool? isRember = AppSharedPreferences.getBool(
      key: AppConstants.remeberMeKey,
    );
    await sharedPreferences.clear();
    if (isRember != null) {
      AppSharedPreferences.setBool(
        value: isRember,
        key: AppConstants.remeberMeKey,
      );
    }
    if (userName != null) {
      AppSharedPreferences.setString(
        key: AppConstants.userName,
        value: userName,
      );
    }
    if (password != null) {
      AppSharedPreferences.setString(
        key: AppConstants.remeberMePassword,
        value: password,
      );
    }
  }

  // static String getAppLang() {
  //   String? lang = sharedPreferences.getString(language);
  //
  //   if (lang != null && lang.isNotEmpty) {
  //     return lang;
  //   } else {
  //     return LanguageType.arabic.getValue();
  //   }
  // }

  // static Future<void> changeAppLang() async {
  //   String currentLang = getAppLang();
  //
  //   if (currentLang == LanguageType.arabic.getValue()) {
  //     await sharedPreferences.setString(
  //         language, LanguageType.arabic.getValue());
  //   } else {
  //     await sharedPreferences.setString(
  //         language, LanguageType.arabic.getValue());
  //   }
  // }

  // static Future<Locale> getLocal() async {
  //   String currentLang = getAppLang();
  //   if (currentLang == LanguageType.arabic.getValue()) {
  //     return arabicLocal;
  //   } else {
  //     return englishLocal;
  //   }
  // }
}
