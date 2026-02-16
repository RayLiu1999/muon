import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/data/repositories/media_repository.dart';
import 'package:muon/presentation/providers/database_provider.dart';

part 'media_provider.g.dart';

/// MediaRepository Provider
@Riverpod(keepAlive: true)
MediaRepository mediaRepository(MediaRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return MediaRepository(db.mediaDao);
}

/// 所有媒體項目 Provider（串流）
@riverpod
Stream<List<MediaItem>> allMediaItems(AllMediaItemsRef ref) {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.watchAllMediaItems();
}

/// 我的最愛 Provider（串流）
@riverpod
Stream<List<MediaItem>> favoriteMediaItems(FavoriteMediaItemsRef ref) {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.watchFavorites();
}

/// 最近播放 Provider
@riverpod
Future<List<MediaItem>> recentlyPlayed(RecentlyPlayedRef ref) {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getRecentlyPlayed();
}

/// 最近下載 Provider
@riverpod
Future<List<MediaItem>> recentlyDownloaded(RecentlyDownloadedRef ref) {
  final repo = ref.watch(mediaRepositoryProvider);
  return repo.getRecentlyDownloaded();
}
