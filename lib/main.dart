import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/wallpaper_provider.dart';
import 'screens/home_screen.dart';
import 'screens/my_work_screen.dart';
import 'theme.dart';

/// Livewall AI 入口：注入 [WallpaperProvider]，底部双 Tab（首页 / 我的作品）。
///
/// 工程仅维护 **iOS**；`ios/` 可由 `scripts/bootstrap_ios_only.sh`（或 Docker 内 `flutter create`）生成。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/dev.env');
  runApp(
    ChangeNotifierProvider(
      create: (_) => WallpaperProvider(),
      child: const LivewallApp(),
    ),
  );
}

class LivewallApp extends StatelessWidget {
  const LivewallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Livewall AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}

/// 壳：IndexedStack 保留页面状态；BottomNavigationBar 切换 Tab。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const HomeScreen(),
          MyWorkScreen(
            onGoGenerate: () => setState(() => _tabIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark_outlined),
            label: 'My Work',
          ),
        ],
      ),
    );
  }
}
