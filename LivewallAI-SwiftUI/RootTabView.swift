import SwiftUI

/// 底部主导航：首页 / 我的作品 / 设置
struct RootTabView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(0)
            MyWorkView(onGoGenerate: { tab = 0 })
                .tabItem { Label("我的作品", systemImage: "square.grid.2x2.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(AppTheme.navActive)
    }
}
