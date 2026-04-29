import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/wallpaper_provider.dart';
import '../theme.dart';
import 'settings_screen.dart';

/// 首页：上传照片、选择动态效果、填写 Prompt、触发火山图生视频。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// （展示名称，拼入模型 prompt 的英文/中文指令片段）
typedef EffectOption = ({String label, String promptHint});

/// 与产品文案一致的六个效果（可按模型能力微调 promptHint）
final List<EffectOption> kEffectOptions = [
  (label: '轻微视差', promptHint: '轻微视差视差效果，稳定运镜'),
  (label: '流动动画', promptHint: '流体般缓慢流动，光影平滑过渡'),
  (label: '自然运动', promptHint: '自然微风、枝叶轻摆，真实物理感'),
  (label: '梦幻流动', promptHint: '梦幻柔和流动，轻雾与柔光'),
  (label: '粒子效果', promptHint: '细微粒子漂浮，电影感氛围'),
  (label: '3D景深', promptHint: '浅景深与立体层次，镜头缓慢推进'),
];

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _promptCtrl = TextEditingController();

  File? _imageFile;
  int _selectedEffectIndex = 0;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (x == null) return;
    setState(() => _imageFile = File(x.path));
  }

  Future<void> _onGenerate(BuildContext context) async {
    final file = _imageFile;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一张照片')),
      );
      return;
    }

    final wp = context.read<WallpaperProvider>();
    final effect = kEffectOptions[_selectedEffectIndex];

    try {
      await wp.generateLiveWallpaper(
        imageFile: file,
        effectLabel: effect.label,
        basePrompt: effect.promptHint,
        userPrompt: _promptCtrl.text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生成完成，可在「我的作品」中预览')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WallpaperProvider>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Livewall AI',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
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
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _UploadHeroCard(
                      imageFile: _imageFile,
                      onTapPick: _pickImage,
                      onRePick: _pickImage,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '动态效果',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: kEffectOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final selected = i == _selectedEffectIndex;
                        return ChoiceChip(
                          label: Text(kEffectOptions[i].label),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedEffectIndex = i),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      controller: _promptCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '补充描述（可选）',
                        hintText: '描述光线、氛围、镜头运动等…',
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            if (wp.isGenerating)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.gradientEnd),
                      const SizedBox(height: 16),
                      Text(
                        wp.generateStatusMessage ?? '处理中…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.onSurface, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: wp.isGenerating ? null : () => _onGenerate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    wp.isGenerating ? '生成中…' : '生成动态壁纸',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 顶部上传区域：虚线边框 + AI 图标；选中后展示预览与「重新上传」。
class _UploadHeroCard extends StatelessWidget {
  const _UploadHeroCard({
    required this.imageFile,
    required this.onTapPick,
    required this.onRePick,
  });

  final File? imageFile;
  final VoidCallback onTapPick;
  final VoidCallback onRePick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: imageFile == null ? onTapPick : null,
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(24),
              color: AppColors.onSurfaceMuted.withValues(alpha: 0.45),
              strokeWidth: 1.6,
              dashPattern: const [8, 6],
              padding: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: imageFile == null
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gradientStart.withValues(alpha: 0.22),
                                  AppColors.gradientEnd.withValues(alpha: 0.22),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: AppColors.gradientEnd,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '上传照片，AI 让它动起来',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '支持人物、宠物、风景，一键生成动态壁纸',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceMuted,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '点击选择照片',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.gradientEnd,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Image.file(
                                imageFile!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: onRePick,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('重新上传'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
