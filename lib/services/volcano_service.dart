import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

/// 火山方舟 Ark API — 图生视频（Seedance 等）异步任务。
///
/// 文档基础路径：`https://ark.cn-beijing.volces.com/api/v3`
/// - 创建任务：`POST /contents/generations/tasks`
/// - 查询任务：`GET /contents/generations/tasks/{task_id}`
///
/// 注意：实际 `model` 字段需填控制台 **推理接入点 ID**（Endpoint ID），
/// 形如 `ep-xxxx`，与模型名称不同。
class VolcanoService {
  VolcanoService({
    required String apiKey,
    Dio? dio,
    this.baseUrl = 'https://ark.cn-beijing.volces.com/api/v3',
  })  : _apiKey = apiKey,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            );

  final String _apiKey;
  final Dio _dio;
  final String baseUrl;

  /// 将本地图片编码为 data URI，供 `image_url.url` 使用。
  static Future<String> imageFileToDataUri(File file) async {
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final ext = file.path.toLowerCase();
    String mime = 'image/jpeg';
    if (ext.endsWith('.png')) {
      mime = 'image/png';
    } else if (ext.endsWith('.webp')) {
      mime = 'image/webp';
    }
    return 'data:$mime;base64,$b64';
  }

  Map<String, String> _authHeaders() => {
        'Authorization': 'Bearer $_apiKey',
      };

  /// 创建图生视频任务。
  ///
  /// [endpointId]：方舟控制台 Endpoint ID（必填）。
  /// [textPrompt]：用户描述 + 效果指令（可附加到 text content）。
  Future<String> createImageToVideoTask({
    required String endpointId,
    required String imageDataUri,
    required String textPrompt,
    int durationSeconds = 5,
    String resolution = '720p',
    String ratio = '9:16',
  }) async {
    final url = '$baseUrl/contents/generations/tasks';
    final body = <String, dynamic>{
      'model': endpointId,
      'content': [
        {
          'type': 'text',
          'role': 'user',
          'text': textPrompt,
        },
        {
          'type': 'image_url',
          'role': 'reference_image',
          'image_url': {'url': imageDataUri},
        },
      ],
      'duration': durationSeconds,
      'resolution': resolution,
      'ratio': ratio,
    };

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        url,
        data: body,
        options: Options(headers: _authHeaders()),
      );

      final data = res.data;
      if (data == null) {
        throw VolcanoApiException('创建任务响应为空');
      }
      final id = data['id']?.toString() ??
          data['task_id']?.toString() ??
          data['data']?['id']?.toString();
      if (id == null || id.isEmpty) {
        throw VolcanoApiException('无法解析任务 ID：${jsonEncode(data)}');
      }
      return id;
    } on DioException catch (e) {
      throw VolcanoApiException(_formatDioError(e));
    }
  }

  /// 查询任务详情（轮询调用）。
  Future<TaskQueryResult> getTask(String taskId) async {
    final url = '$baseUrl/contents/generations/tasks/$taskId';
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: _authHeaders()),
      );
      final data = res.data;
      if (data == null) {
        throw VolcanoApiException('查询任务响应为空');
      }
      return TaskQueryResult.fromJson(data);
    } on DioException catch (e) {
      throw VolcanoApiException(_formatDioError(e));
    }
  }

  static String _formatDioError(DioException e) {
    final buf = StringBuffer('HTTP ${e.response?.statusCode ?? '-'}');
    final data = e.response?.data;
    if (data != null) {
      buf.write(' ');
      buf.write(data is Map ? jsonEncode(data) : data.toString());
    } else if (e.message != null) {
      buf.write(' ${e.message}');
    }
    return buf.toString();
  }

  /// 创建任务后轮询直到成功或失败。
  ///
  /// [pollInterval] 默认 2 秒；[maxAttempts] 防止无限等待。
  Future<VolcanoVideoResult> createAndPoll({
    required String endpointId,
    required File imageFile,
    required String textPrompt,
    int durationSeconds = 5,
    String resolution = '720p',
    String ratio = '9:16',
    Duration pollInterval = const Duration(seconds: 2),
    int maxAttempts = 120,
    void Function(String status, int attempt)? onProgress,
  }) async {
    final dataUri = await imageFileToDataUri(imageFile);
    final taskId = await createImageToVideoTask(
      endpointId: endpointId,
      imageDataUri: dataUri,
      textPrompt: textPrompt,
      durationSeconds: durationSeconds,
      resolution: resolution,
      ratio: ratio,
    );

    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(i == 0 ? Duration.zero : pollInterval);
      final q = await getTask(taskId);
      onProgress?.call(q.normalizedStatus, i + 1);

      if (q.isSucceeded) {
        final videoUrl = q.videoUrl ?? _deepExtractVideoUrl(q.raw);
        final thumb = q.thumbnailUrl ?? _deepExtractThumbnailUrl(q.raw);
        if (videoUrl == null || videoUrl.isEmpty) {
          throw VolcanoApiException('任务成功但未解析到视频 URL：${jsonEncode(q.raw)}');
        }
        return VolcanoVideoResult(
          taskId: taskId,
          videoUrl: videoUrl,
          thumbnailUrl: thumb,
          raw: q.raw,
        );
      }
      if (q.isFailed) {
        final err = q.errorMessage ?? '任务失败';
        throw VolcanoApiException(err);
      }
    }
    throw VolcanoApiException('轮询超时（${maxAttempts * pollInterval.inSeconds} 秒内未完成）');
  }

  /// 深度遍历 JSON，查找疑似视频直链。
  static String? _deepExtractVideoUrl(dynamic json) {
    return _deepExtractUrl(json, (s) {
      final lower = s.toLowerCase();
      return lower.contains('.mp4') ||
          lower.contains('.mov') ||
          lower.contains('video') && lower.startsWith('http');
    });
  }

  static String? _deepExtractThumbnailUrl(dynamic json) {
    return _deepExtractUrl(json, (s) {
      final lower = s.toLowerCase();
      return (lower.contains('.jpg') ||
              lower.contains('.jpeg') ||
              lower.contains('.png') ||
              lower.contains('.webp')) &&
          lower.startsWith('http');
    });
  }

  static String? _deepExtractUrl(dynamic json, bool Function(String) predicate) {
    if (json is String && predicate(json)) return json;
    if (json is Map) {
      for (final v in json.values) {
        final r = _deepExtractUrl(v, predicate);
        if (r != null) return r;
      }
    } else if (json is List) {
      for (final v in json) {
        final r = _deepExtractUrl(v, predicate);
        if (r != null) return r;
      }
    }
    return null;
  }
}

/// 单次查询结果（字段兼容多种方舟响应形态）。
class TaskQueryResult {
  TaskQueryResult({
    required this.raw,
    required this.normalizedStatus,
    this.videoUrl,
    this.thumbnailUrl,
    this.errorMessage,
  });

  factory TaskQueryResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> root = json;
    if (json['data'] is Map<String, dynamic>) {
      root = Map<String, dynamic>.from(json['data'] as Map);
    }

    final status = (root['status'] ??
            root['task_status'] ??
            root['state'] ??
            json['status'] ??
            '')
        .toString()
        .toLowerCase();

    final content =
        root['content'] ?? root['output'] ?? root['result'] ?? json['content'];
    String? video;
    String? thumb;

    void pickFromMap(Map<String, dynamic> m) {
      video ??= m['video_url']?.toString() ??
          m['url']?.toString() ??
          m['video']?.toString();
      thumb ??= m['cover_url']?.toString() ??
          m['thumbnail_url']?.toString() ??
          m['poster_url']?.toString();
    }

    if (content is Map<String, dynamic>) {
      pickFromMap(content);
      final inner = content['video'] ?? content['videos'];
      if (inner is List && inner.isNotEmpty && inner.first is Map) {
        pickFromMap(Map<String, dynamic>.from(inner.first as Map));
      }
    }

    String? err = root['error']?.toString() ?? json['error']?.toString();
    err ??= root['failure_reason']?.toString();
    final errObj = root['error'] ?? json['error'];
    if (errObj is Map && errObj['message'] != null) {
      err = errObj['message'].toString();
    }

    return TaskQueryResult(
      raw: json,
      normalizedStatus: status.isEmpty ? 'unknown' : status,
      videoUrl: video,
      thumbnailUrl: thumb,
      errorMessage: err,
    );
  }

  final Map<String, dynamic> raw;
  final String normalizedStatus;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? errorMessage;

  bool get isSucceeded {
    return normalizedStatus == 'succeeded' ||
        normalizedStatus == 'success' ||
        normalizedStatus == 'completed';
  }

  bool get isFailed {
    return normalizedStatus == 'failed' ||
        normalizedStatus == 'error' ||
        normalizedStatus == 'cancelled';
  }
}

class VolcanoVideoResult {
  VolcanoVideoResult({
    required this.taskId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.raw,
  });

  final String taskId;
  final String videoUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? raw;
}

class VolcanoApiException implements Exception {
  VolcanoApiException(this.message);
  final String message;

  @override
  String toString() => 'VolcanoApiException: $message';
}
