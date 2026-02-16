import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';
part 'search_result.g.dart';

/// YouTube 搜尋結果 Model
@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    /// YouTube 影片 ID
    required String videoId,

    /// 標題
    required String title,

    /// 頻道名稱
    required String channel,

    /// 縮圖 URL
    required String thumbnailUrl,

    /// 時長描述（例如 "3:45"）
    required String duration,

    /// 是否已下載
    @Default(false) bool isDownloaded,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);
}
