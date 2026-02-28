import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/core/constants/app_env.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final baseUrl = ref.watch(backendBaseUrlProvider);

  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      if (AppEnv.apiKey.isNotEmpty) 'X-API-Key': AppEnv.apiKey,
    },
  );

  return Dio(options);
}

@Riverpod(keepAlive: true)
String backendBaseUrl(BackendBaseUrlRef ref) {
  // 1. 優先使用 --dart-define=API_URL=... 傳入的值
  if (AppEnv.apiUrl.isNotEmpty) {
    return AppEnv.apiUrl;
  }

  // 2. 未傳入時依平台決定開發預設值
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000'; // Android 模擬器 host
  }
  return 'http://localhost:8000';
}
