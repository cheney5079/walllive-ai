在 Xcode 中使用本 SwiftUI 源码（约 3 分钟）

1. 打开 Xcode → File → New → Project → iOS → App
   - Product Name: LivewallAI
   - Interface: SwiftUI
   - Language: Swift

2. 删除模板自带的 ContentView.swift、LivewallAIApp.swift（避免与下列文件重复）。

3. 将「LivewallAI-SwiftUI」文件夹内全部 .swift 拖入工程左侧（勾选 Copy items if needed；Target 勾选 LivewallAI）。

4. 确保只有一个带 @main 的入口：保留拖入的 LivewallAIApp.swift。

5. Target → Info → 自定义 iOS Target Properties 添加：
   - Privacy - Photo Library Usage Description → 「用于选择照片生成动态壁纸」
   （可选）Privacy - Camera Usage Description → 同上

6. Deployment Target：iOS 16 或以上。

7. Signing & Capabilities 选择 Team，Run。

8. 「设置」Tab 中填写火山 Endpoint ID 与 API Key。

说明：原 Flutter 工程仍在上一级目录；本目录为纯 SwiftUI 实现，可独立维护。
