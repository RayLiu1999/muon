// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchResultImpl _$$SearchResultImplFromJson(Map<String, dynamic> json) =>
    _$SearchResultImpl(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      channel: json['channel'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      duration: json['duration'] as String,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );

Map<String, dynamic> _$$SearchResultImplToJson(_$SearchResultImpl instance) =>
    <String, dynamic>{
      'videoId': instance.videoId,
      'title': instance.title,
      'channel': instance.channel,
      'thumbnailUrl': instance.thumbnailUrl,
      'duration': instance.duration,
      'isDownloaded': instance.isDownloaded,
    };
