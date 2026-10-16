abstract class EndPoints {
  //?======================== BASE URL ========================
  //static String appBaseUrl = 'https://darsi.md-soft.app/'; // for production

  static const String appBaseUrl =
      'http://192.168.1.60:1601/'; // for local testing
  static String baseUrl = '${appBaseUrl}api/v1/'; // for local testing
  static String baseImageUrl = "${appBaseUrl}uploads";

  // static String baseImgUrl = "${appBaseUrl}image/";

  //?======================== LOGIN & SIGNUP & REFRESH TOKEN ========================
  static String login = 'admin/auth/login';
  static String sendVerificationCodeForPhone = 'auth/createVerificationCode';
  static String sendVerificationCodeForPhoneStore = 'store/checkPhone/:';
  static String verifyCode = 'auth/verify';
  static String sendVerificationCodeForForgetPassword =
      'auth/createVerificationCodeCheck';
  static String forgetPassword = 'auth/forget-password';
  static String signup = 'auth/signup';
  static String logout = 'auth/logout';
  static String refreshUserToken = 'admin/auth/refresh';
  static String profile = 'admin/auth/profile';

  //========================= customer Apis =============================

  //?======================== Rest of  other Apis ========================
  static String uploadOneImage = 'upload/image';
  static String userProfile = 'users/profile';
  static String changePassword = 'user/changePassword';

  static String stores = 'store';
  static String categories = 'categories';
  static String notifications = 'note';

  static String confige = 'config';
  static String cities = 'admin/governorates';
  static String citiesAddUpdate = 'admin/governorates';
  static String regions = 'admin/regions';
  static String regionsAddUpdate = 'admin/regions';
  static String reports = 'reports';
  static String news = 'news';
  static String users = 'users';
  static String blocked = 'blockUsers';
  static String suggestions = 'suggestions';
  // uploads
  static String uploadAny = 'upload/any';
  static String uploadImage = 'upload/image';
  static String uploadVideo = 'upload/video';
  static String uploadDocument = 'upload/document';
  static String orders = 'admin/orders';
  static String replies = 'replays';
  static const String adminDashboardLandings = 'admin/dashboard';
  static const String adminStudentsParents = 'admin/students';
  static const String adminTeacherss = 'admin/teachers';
  static const String adminOrderss = 'admin/orders';
  static const String adminEmployees = 'admin/employees';
  static const String adminTransactionss = 'admin/transactions';
  static const String adminCategoriess = 'admin/categories';
  static const String adminSupports = 'support';
  static const String adminSliderss = 'admin/sliders';
  static const String adminSettingss = 'admin_settingss';
  static const String adminNotifications = 'admin/notifications';
  static const String lectureTypes = 'admin/lecture-types';
  static const String studyStages = 'admin/study-stages';
}
