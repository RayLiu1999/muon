import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

/// SharedPreferences Provider
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError('sharedPreferences 必須在 ProviderScope 注入');
}

/// 音質設定 Provider
@Riverpod(keepAlive: true)
class AudioQuality extends _$AudioQuality {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('audio_quality') ?? 'best'; // 預設最高音質
  }

  Future<void> updateQuality(String quality) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('audio_quality', quality);
    state = quality;
  }
}

/// 下載格式設定 Provider
@Riverpod(keepAlive: true)
class DownloadFormat extends _$DownloadFormat {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('download_format') ?? 'm4a'; // 預設 m4a
  }

  Future<void> updateFormat(String format) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('download_format', format);
    state = format;
  }
}

/// 主題模式設定 Provider
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('theme_mode') ?? 'system'; // system, light, dark
  }

  Future<void> updateThemeMode(String mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('theme_mode', mode);
    state = mode;
  }
}

/// 下載目錄設定 Provider（顯示使用者自訂的存檔資料夾路徑）
@Riverpod(keepAlive: true)
class DownloadDirectory extends _$DownloadDirectory {
  static const _key = 'download_directory_path';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_key) ?? '';
  }

  Future<void> updatePath(String path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, path);
    state = path;
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_key);
    state = '';
  }
}
