import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/wallpaper.dart';
import '../providers/wallpaper_provider.dart';
import '../theme.dart';
import 'settings_screen.dart';

/// 「我的作品」：空状态 / 双列网格 / 点击网络视频预览。
class MyWorkScreen extends StatelessWidget {
  const MyWorkScreen({
    super.key,
    required this.onGoGenerate,
  });

  /// 空状态「去生成」跳转到 Home Tab（由 Shell 注入）。
  final VoidCallback onGoGenerate;

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WallpaperProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '我的作品',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.onSurface),
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: wp.items.isEmpty ? _EmptyState(onGoGenerate: onGoGenerate) : _WorkGrid(items: wp.items),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态文案 + 紫色「去生成」
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onGoGenerate});

  final VoidCallback onGoGenerate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '这里空空如也\n你的动态作品将展示在这里',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 28),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: onGoGenerate,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        child: Text(
                          '去生成',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkGrid extends StatelessWidget {
  const _WorkGrid({required this.items});

  final List<WallpaperItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.56,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _WorkCard(item: item);
      },
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.item});

  final WallpaperItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => VideoPreviewScreen(
                videoUrl: item.videoUrl,
                title: item.title,
                localVideoPath: item.localVideoPath,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Thumb(item: item),
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 44,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formattedTime,
                    style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.effectLabel,
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 缩略：本地首帧 → 网络封面 → 用户所选静态图 → 渐变占位。
class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final WallpaperItem item;

  @override
  Widget build(BuildContext context) {
    final thumb = item.localThumbnailPath;
    if (thumb != null && thumb.isNotEmpty && File(thumb).existsSync()) {
      return Image.file(
        File(thumb),
        fit: BoxFit.cover,
      );
    }
    final remote = item.remoteThumbnailUrl;
    if (remote != null && remote.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: remote,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
        errorWidget: (_, __, ___) => _LocalOrFallback(item: item),
      );
    }
    return _LocalOrFallback(item: item);
  }
}

class _LocalOrFallback extends StatelessWidget {
  const _LocalOrFallback({required this.item});

  final WallpaperItem item;

  @override
  Widget build(BuildContext context) {
    final path = item.localPreviewPath;
    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, color: Colors.white54, size: 40),
    );
  }
}

/// 全屏播放：优先本地缓存 MP4，否则使用网络 URL。
class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.localVideoPath,
  });

  final String videoUrl;
  final String title;

  /// 若生成后已下载到应用目录，优先走本地解码（省流量、离线可播）。
  final String? localVideoPath;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final local = widget.localVideoPath;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      _controller = VideoPlayerController.file(File(local));
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      await _controller.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '无法播放：$_error',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            : !_ready
                ? const CircularProgressIndicator(color: AppColors.gradientEnd)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
    );
  }
}
