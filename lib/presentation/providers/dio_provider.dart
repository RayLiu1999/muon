import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}

@Riverpod(keepAlive: true)
String backendBaseUrl(BackendBaseUrlRef ref) {
  // 1. 優先嘗試讀取外部傳入的 API_URL 參數
  const envApiUrl = String.fromEnvironment('API_URL');
  if (envApiUrl.isNotEmpty) {
    return envApiUrl;
  }

  // 2. 如果沒有傳入參數，則退回預設邏輯 (給開發用)
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}
