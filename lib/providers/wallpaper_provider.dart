import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/wallpaper.dart';
import '../services/media_storage_service.dart';
import '../services/volcano_service.dart';

/// 方舟 Endpoint ID 在 SharedPreferences 中的键（非密钥，可为明文）。
const String kPrefsEndpointId = 'livewall_volcano_endpoint_id';

/// API Key 存在 Secure Storage（敏感信息）。
const String kSecureApiKey = 'livewall_volcano_api_key';

/// 持久化作品列表
const String kPrefsWallpapers = 'livewall_wallpapers_json';

/// 全局壁纸状态：列表 + 生成流程 + 密钥配置加载。
///
/// **安全说明**：请勿将生产环境 API Key 硬编码进仓库；
/// 开发时可在「设置」页粘贴 Key，或使用 `assets/env/dev.env`（勿提交含密钥的版本）。
class WallpaperProvider extends ChangeNotifier {
  WallpaperProvider() {
    _bootstrap();
  }

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();
  final MediaStorageService _media = MediaStorageService();

  List<WallpaperItem> _items = [];
  String _endpointId = '';
  String? _apiKeyCache;

  bool _loadingPrefs = true;
  bool _generating = false;
  String? _generateMessage;
  int _pollAttempt = 0;

  /// 作品列表（时间倒序可在 UI 层排序）
  List<WallpaperItem> get items => List.unmodifiable(_items);

  bool get isLoadingPrefs => _loadingPrefs;

  /// 是否正在调用火山并轮询
  bool get isGenerating => _generating;

  /// 生成页展示的辅助文案（含轮询进度）
  String? get generateStatusMessage => _generateMessage;

  int get pollAttempt => _pollAttempt;

  /// 用户在设置中保存的 Endpoint ID
  String get endpointId => _endpointId;

  /// 实际用于请求的 Endpoint：优先设置页，其次 `dev.env` 中的 `VOLCANO_ENDPOINT_ID`。
  String get effectiveEndpointId {
    if (_endpointId.isNotEmpty) return _endpointId;
    return dotenv.env['VOLCANO_ENDPOINT_ID']?.trim() ?? '';
  }

  /// 是否已配置 API Key（仅反映内存/存储可读性，不暴露具体值）
  Future<bool> hasApiKey() async {
    final k = await getApiKey();
    return k != null && k.isNotEmpty;
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _endpointId = prefs.getString(kPrefsEndpointId) ?? '';
    final raw = prefs.getString(kPrefsWallpapers);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _items = list
            .map((e) => WallpaperItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        _items = [];
      }
    }
    _apiKeyCache = await _secure.read(key: kSecureApiKey);
    _loadingPrefs = false;
    notifyListeners();
  }

  /// 保存 Endpoint ID（控制台复制的 ep-xxx）
  Future<void> setEndpointId(String id) async {
    _endpointId = id.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsEndpointId, _endpointId);
    notifyListeners();
  }

  /// 保存 API Key 到安全存储
  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    await _secure.write(key: kSecureApiKey, value: trimmed);
    _apiKeyCache = trimmed;
    notifyListeners();
  }

  /// 读取 Key：优先安全存储，其次 `dev.env` 的 `VOLCANO_API_KEY`（仅本地调试）。
  Future<String?> getApiKey() async {
    _apiKeyCache ??= await _secure.read(key: kSecureApiKey);
    if (_apiKeyCache != null && _apiKeyCache!.isNotEmpty) {
      return _apiKeyCache;
    }
    final fromEnv = dotenv.env['VOLCANO_API_KEY']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return null;
  }

  Future<void> _persistItems() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(kPrefsWallpapers, encoded);
  }

  /// 调用火山图生视频：编码图片 → 创建任务 → 轮询 → 下载与缩略图 → 写入列表。
  ///
  /// [effectLabel]：用于「我的作品」卡片标签。
  /// [basePrompt]：首页选用的基础效果文案（拼入 text content）。
  /// [userPrompt]：用户可选补充描述。
  Future<void> generateLiveWallpaper({
    required File imageFile,
    required String effectLabel,
    required String basePrompt,
    String userPrompt = '',
  }) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError('请先在设置中配置火山 API Key，或在 assets/env/dev.env 中配置 VOLCANO_API_KEY');
    }
    final ep = effectiveEndpointId;
    if (ep.isEmpty) {
      throw StateError('请先在设置中配置推理接入点 Endpoint ID，或在 dev.env 中配置 VOLCANO_ENDPOINT_ID');
    }

    _generating = true;
    _pollAttempt = 0;
    _generateMessage = 'AI 正在生成动态视频... 预计 15-40 秒';
    notifyListeners();

    final combinedPrompt = [
      basePrompt.trim(),
      if (userPrompt.trim().isNotEmpty) userPrompt.trim(),
    ].join(' ');

    final itemId = _uuid.v4();
    final localPath = imageFile.path;

    try {
      final service = VolcanoService(apiKey: key);
      final result = await service.createAndPoll(
        endpointId: ep,
        imageFile: imageFile,
        textPrompt: combinedPrompt,
        onProgress: (status, attempt) {
          _pollAttempt = attempt;
          _generateMessage =
              'AI 正在生成动态视频... 预计 15-40 秒（状态：$status，第 $attempt 次查询）';
          notifyListeners();
        },
      );

      String? savedVideoPath;
      String? savedThumbPath;
      try {
        _generateMessage = '正在保存视频并生成封面…';
        notifyListeners();
        final mediaResult = await _media.downloadVideoAndThumbnail(
          videoUrl: result.videoUrl,
          itemId: itemId,
          onProgress: (m) {
            _generateMessage = m;
            notifyListeners();
          },
        );
        savedVideoPath = mediaResult.localVideoPath;
        savedThumbPath = mediaResult.localThumbnailPath;
      } catch (e, st) {
        debugPrint('本地保存/缩略图失败（仍保留网络 URL）：$e\n$st');
      }

      final item = WallpaperItem(
        id: itemId,
        title: '动态壁纸 · $effectLabel',
        videoUrl: result.videoUrl,
        createdAt: DateTime.now(),
        effectLabel: effectLabel,
        localPreviewPath: localPath,
        remoteThumbnailUrl: result.thumbnailUrl,
        localVideoPath: savedVideoPath,
        localThumbnailPath: savedThumbPath,
      );
      _items = [item, ..._items];
      await _persistItems();
    } finally {
      _generating = false;
      _generateMessage = null;
      notifyListeners();
    }
  }

  /// 删除一条作品（本地记录；并尝试删除本地视频与缩略图文件）
  Future<void> removeItem(String id) async {
    for (final e in _items) {
      if (e.id == id) {
        await MediaStorageService.deleteLocalFiles(
          videoPath: e.localVideoPath,
          thumbnailPath: e.localThumbnailPath,
        );
        break;
      }
    }
    _items = _items.where((e) => e.id != id).toList();
    await _persistItems();
    notifyListeners();
  }
}
