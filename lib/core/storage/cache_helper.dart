import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String token = 'token';
const String skipLogin = 'skip';
const String userPrefs = 'user';
const String prefsOnBoarding = 'onBoarding';
const String language = 'language';

class AppSharedPreferences {
  static late SharedPreferences sharedPreferences;

  static Future<void> initialSharedPreference() async {
    await SharedPreferences.getInstance().then(
      (value) => sharedPreferences = value,
    );
  }

  //***************  set data *********** */
  static Future<void> setString({
    required String value,
    required String key,
  }) async {
    await sharedPreferences.setString(key, value);
  }

  static Future<void> setListString({
    required List<String> value,
    required String key,
  }) async {
    await sharedPreferences.setStringList(key, value);
  }

  static Future<void> setBool({
    required bool value,
    required String key,
  }) async {
    await sharedPreferences.setBool(key, value);
  }

  static Future<void> setInt({required int value, required String key}) async {
    await sharedPreferences.setInt(key, value);
  }

  static Future<void> setDouble({
    required double value,
    required String key,
  }) async {
    await sharedPreferences.setDouble(key, value);
  }

  //************** get data ************* */
  static double? getDouble({required String key}) {
    return sharedPreferences.getDouble(key);
  }

  static String? getString({required String key}) {
    return sharedPreferences.getString(key);
  }

  static int? getInt({required String key}) {
    return sharedPreferences.getInt(key);
  }

  static bool? getBool({required String key}) {
    return sharedPreferences.getBool(key);
  }

  static List<String>? getStringList({required String key}) {
    return sharedPreferences.getStringList(key);
  }

  //************** delete data ************* */

  static Future<void> remove({required String key}) async {
    await sharedPreferences.remove(key);
  }

  static Future<void> setAppLang({String? lang}) async {
    await sharedPreferences.setString("lang", lang ?? "ar");
  }

  static String getAppLang() {
    return sharedPreferences.getString("lang") ?? "ar";
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
