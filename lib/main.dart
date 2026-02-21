import 'package:audio_service/audio_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/app.dart';
import 'package:muon/audio/audio_handler.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/database_provider.dart';
import 'package:muon/presentation/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Muon App 進入點
///
/// 初始化 AudioService、資料庫，並透過 ProviderScope override 注入。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 AudioHandler（背景播放 + 通知列控制）
  final audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.muon.muon.audio',
      androidNotificationChannelName: 'Muon 播放',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // 初始化資料庫
  final appDir = await getApplicationDocumentsDirectory();
  final dbFile = File('${appDir.path}/muon.db');
  final database = AppDatabase(NativeDatabase(dbFile));

  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        databaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MuonApp(),
    ),
  );
}
