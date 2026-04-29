import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallpaper_provider.dart';
import '../theme.dart';

/// 开发 / 生产均可用的密钥配置页。
///
/// - **API Key**：写入 `FlutterSecureStorage`（勿提交到 Git）。
/// - **Endpoint ID**：方舟控制台「推理接入点」ID（如 `ep-2025xxxx-xx`）。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _endpointCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<WallpaperProvider>();
      _endpointCtrl.text = p.endpointId;
      final k = await p.getApiKey();
      if (k != null) {
        _keyCtrl.text = k;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '火山方舟',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _endpointCtrl,
            decoration: const InputDecoration(
              labelText: '推理接入点 Endpoint ID',
              hintText: '例如 ep-xxxxxxxx',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'Bearer Token',
            ),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final p = context.read<WallpaperProvider>();
                  await p.setEndpointId(_endpointCtrl.text);
                  await p.setApiKey(_keyCtrl.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已保存')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      '保存',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '说明：Endpoint 需在火山方舟控制台创建「Seedance / 图生视频」接入点；'
            'API Key 与控制台「API Key」一致。'
            ' 本地调试也可编辑 assets/env/dev.env（勿提交真实密钥）。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
