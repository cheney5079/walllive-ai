import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// 将云端生成的 MP4 下载到应用目录，并用 [video_thumbnail] 截取首帧作为网格封面。
///
/// 目录结构：`Documents/livewall/videos/{id}.mp4`、`thumbs/{id}.jpg`
class MediaStorageService {
  MediaStorageService([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  /// 下载视频并生成缩略图；任一步失败会抛出，由调用方降级为「仅网络 URL」。
  Future<MediaSaveResult> downloadVideoAndThumbnail({
    required String videoUrl,
    required String itemId,
    void Function(String message)? onProgress,
  }) async {
    final doc = await getApplicationDocumentsDirectory();
    final root = Directory('${doc.path}/livewall');
    final videoDir = Directory('${root.path}/videos');
    final thumbDir = Directory('${root.path}/thumbs');
    await videoDir.create(recursive: true);
    await thumbDir.create(recursive: true);

    final videoPath = '${videoDir.path}/$itemId.mp4';
    onProgress?.call('正在下载视频…');
    await _dio.download(
      videoUrl,
      videoPath,
      options: Options(
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    String? thumbPath;
    try {
      onProgress?.call('正在生成封面缩略图…');
      thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 480,
        quality: 88,
      );
    } catch (e, st) {
      debugPrint('video_thumbnail 失败: $e\n$st');
    }

    return MediaSaveResult(
      localVideoPath: videoPath,
      localThumbnailPath: thumbPath,
    );
  }

  /// 删除一条作品对应的本地文件（忽略不存在）。
  static Future<void> deleteLocalFiles({
    String? videoPath,
    String? thumbnailPath,
  }) async {
    Future<void> tryDelete(String? p) async {
      if (p == null || p.isEmpty) return;
      final f = File(p);
      if (await f.exists()) {
        await f.delete();
      }
    }

    await tryDelete(videoPath);
    await tryDelete(thumbnailPath);
  }
}

/// [downloadVideoAndThumbnail] 的结果。
class MediaSaveResult {
  MediaSaveResult({
    required this.localVideoPath,
    this.localThumbnailPath,
  });

  final String localVideoPath;
  final String? localThumbnailPath;
}
