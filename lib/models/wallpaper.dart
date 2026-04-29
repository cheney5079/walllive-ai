import 'package:intl/intl.dart';

/// 单条「我的作品」数据模型。
///
/// [videoUrl] 为火山生成完成后的可访问视频地址（通常为 HTTPS）。
/// [localVideoPath]：下载到应用目录后的本地 MP4（离线播放、省流量）。
/// [localThumbnailPath]：`video_thumbnail` 截取的首帧 JPEG。
/// [localPreviewPath]：生成前用户所选静态图，可作占位。
/// [remoteThumbnailUrl]：若接口返回封面图 URL。
class WallpaperItem {
  WallpaperItem({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.createdAt,
    required this.effectLabel,
    this.localPreviewPath,
    this.remoteThumbnailUrl,
    this.localVideoPath,
    this.localThumbnailPath,
  });

  final String id;
  final String title;

  /// 动态视频地址（网络）
  final String videoUrl;

  /// 生成时间
  final DateTime createdAt;

  /// 动态效果标签（与首页 Chips 文案对应）
  final String effectLabel;

  /// 本地预览图路径（用户选择的静态图），可为空
  final String? localPreviewPath;

  /// 服务端返回的缩略图 / 封面，可为空
  final String? remoteThumbnailUrl;

  /// 已缓存到本地的视频文件路径（可选）
  final String? localVideoPath;

  /// 本地生成的视频首帧缩略图路径（可选）
  final String? localThumbnailPath;

  String get formattedTime {
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'videoUrl': videoUrl,
        'createdAt': createdAt.toIso8601String(),
        'effectLabel': effectLabel,
        'localPreviewPath': localPreviewPath,
        'remoteThumbnailUrl': remoteThumbnailUrl,
        'localVideoPath': localVideoPath,
        'localThumbnailPath': localThumbnailPath,
      };

  static WallpaperItem fromJson(Map<String, dynamic> j) {
    return WallpaperItem(
      id: j['id'] as String,
      title: j['title'] as String,
      videoUrl: j['videoUrl'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      effectLabel: j['effectLabel'] as String,
      localPreviewPath: j['localPreviewPath'] as String?,
      remoteThumbnailUrl: j['remoteThumbnailUrl'] as String?,
      localVideoPath: j['localVideoPath'] as String?,
      localThumbnailPath: j['localThumbnailPath'] as String?,
    );
  }

  WallpaperItem copyWith({
    String? title,
    String? videoUrl,
    DateTime? createdAt,
    String? effectLabel,
    String? localPreviewPath,
    String? remoteThumbnailUrl,
    String? localVideoPath,
    String? localThumbnailPath,
  }) {
    return WallpaperItem(
      id: id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      effectLabel: effectLabel ?? this.effectLabel,
      localPreviewPath: localPreviewPath ?? this.localPreviewPath,
      remoteThumbnailUrl: remoteThumbnailUrl ?? this.remoteThumbnailUrl,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
    );
  }
}
