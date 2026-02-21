import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/data/database/daos/media_dao.dart';
import 'package:muon/data/repositories/media_repository.dart';
import 'package:muon/presentation/providers/database_provider.dart';

part 'media_provider.g.dart';

@riverpod
class MediaSortOptionNotifier extends _$MediaSortOptionNotifier {
  @override
  MediaSortOption build() {
    return MediaSortOption.dateDesc;
  }

  void updateSort(MediaSortOption sort) {
    state = sort;
  }
}

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
  final sort = ref.watch(mediaSortOptionNotifierProvider);
  return repo.watchAllMediaItems(sort: sort);
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
