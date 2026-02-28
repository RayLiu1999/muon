/// 所有透過 --dart-define 傳入的環境變數集中在此
///
/// 使用方式：
///   flutter run  --dart-define=API_KEY=xxx --dart-define=API_URL=https://api.example.com
///   flutter build apk --dart-define=API_KEY=xxx --dart-define=API_URL=https://api.example.com
///
/// 或建立 dart_defines/prod.env（見下方說明）後：
///   flutter run  --dart-define-from-file=dart_defines/prod.env
///   flutter build apk --dart-define-from-file=dart_defines/prod.env
class AppEnv {
  AppEnv._();

  /// 後端 API 金鑰，對應後端 .env 的 API_KEY
  /// 未傳入時為空字串（開發模式：後端會自動放行）
  static const String apiKey = String.fromEnvironment('API_KEY');

  /// 後端 Base URL，未傳入時由 dio_provider 依平台決定預設值
  static const String apiUrl = String.fromEnvironment('API_URL');

  /// 是否處於開發模式（apiKey 與 apiUrl 均未設定）
  static bool get isDev => apiKey.isEmpty && apiUrl.isEmpty;
}
