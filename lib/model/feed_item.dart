import 'package:equatable/equatable.dart';

class FeedItem extends Equatable {
  final String id;           // album_medias.id
  final String albumId;
  final String albumName;
  final String albumCoverUrl;
  final String mediaType;    // 'photo' or 'video'
  final String url;          // 원본/주요 이미지 URL
  final String? thumbUrl;    // 동영상이면 썸네일
  final int? width;
  final int? height;
  final double? duration;    // video일 때 초단위
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.albumId,
    required this.albumName,
    required this.albumCoverUrl,
    required this.mediaType,
    required this.url,
    required this.thumbUrl,
    required this.width,
    required this.height,
    required this.duration,
    required this.createdAt,
  });

  bool get isVideo => mediaType == 'video';
  String get displayUrl => thumbUrl?.isNotEmpty == true ? thumbUrl! : url;

  // yyyy.MM.dd
  String get formattedDateTime {
    String two(int n) => n.toString().padLeft(2, '0');

    final y = createdAt.year.toString();
    final m = two(createdAt.month);
    final d = two(createdAt.day);
    final h = two(createdAt.hour);
    final min = two(createdAt.minute);

    return '$y.$m.$d $h:$min';
  }

  @override
  List<Object?> get props => [
    id,
    albumId,
    albumName,
    albumCoverUrl,
    mediaType,
    url,
    thumbUrl,
    width,
    height,
    duration,
    createdAt,
  ];
}
