import Combine
import Foundation
import SwiftUI

/// 动态效果选项（与产品文案一致）
struct EffectOption: Identifiable, Hashable {
    var id: String { label }
    let label: String
    let promptHint: String

    static let all: [EffectOption] = [
        EffectOption(label: "轻微视差", promptHint: "轻微视差效果，稳定运镜"),
        EffectOption(label: "流动动画", promptHint: "流体般缓慢流动，光影平滑过渡"),
        EffectOption(label: "自然运动", promptHint: "自然微风、枝叶轻摆，真实物理感"),
        EffectOption(label: "梦幻流动", promptHint: "梦幻柔和流动，轻雾与柔光"),
        EffectOption(label: "粒子效果", promptHint: "细微粒子漂浮，电影感氛围"),
        EffectOption(label: "3D景深", promptHint: "浅景深与立体层次，镜头缓慢推进")
    ]
}

@MainActor
final class WallpaperStore: ObservableObject {
    @Published var items: [WallpaperItem] = []
    @Published var endpointId: String = ""
    @Published var isGenerating = false
    @Published var statusMessage: String?

    init() {
        endpointId = UserDefaults.standard.string(forKey: UserDefaultsKeys.endpointId) ?? ""
        loadItems()
    }

    func persistEndpoint() {
        UserDefaults.standard.set(endpointId, forKey: UserDefaultsKeys.endpointId)
    }

    func saveAPIKey(_ key: String) {
        SecureSettings.saveAPIKey(key.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func apiKey() -> String? {
        SecureSettings.loadAPIKey()
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.wallpapersJSON),
              let decoded = try? JSONDecoder().decode([WallpaperItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }

    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.wallpapersJSON)
        }
    }

    func delete(_ item: WallpaperItem) {
        LocalMediaStore.deleteFiles(video: item.localVideoPath, thumbnail: item.localThumbnailPath)
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    /// 使用 JPEG 数据调用火山并下载到本地
    func generateWallpaper(imageJPEGData: Data, effect: EffectOption, userExtraPrompt: String) async throws {
        guard let key = apiKey(), !key.isEmpty else {
            throw VolcanoError.message("请先在设置中保存 API Key")
        }
        let ep = endpointId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ep.isEmpty else {
            throw VolcanoError.message("请先在设置中填写 Endpoint ID")
        }

        let combined = [effect.promptHint, userExtraPrompt.trimmingCharacters(in: .whitespacesAndNewlines)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        isGenerating = true
        statusMessage = "AI 正在生成动态视频…预计 15–40 秒"
        defer {
            isGenerating = false
            statusMessage = nil
        }

        let service = VolcanoService(apiKey: key)
        let itemId = UUID()

        let result = try await service.imageToVideo(
            imageJPEGData: imageJPEGData,
            textPrompt: combined,
            endpointId: ep,
            onPoll: { [weak self] status, attempt in
                Task { @MainActor in
                    self?.statusMessage = "AI 正在生成…（\(status)，第 \(attempt) 次查询）"
                }
            }
        )

        statusMessage = "正在保存视频并生成封面…"
        var localVideo: String?
        var localThumb: String?
        do {
            let saved = try await LocalMediaStore.saveVideoAndThumbnail(from: result.videoURL, itemId: itemId)
            localVideo = saved.videoPath
            localThumb = saved.thumbPath
        } catch {
            // 仍保存网络 URL，便于在线播放
        }

        let item = WallpaperItem(
            id: itemId,
            title: "动态壁纸 · \(effect.label)",
            videoURLString: result.videoURL.absoluteString,
            createdAt: Date(),
            effectLabel: effect.label,
            localVideoPath: localVideo,
            localThumbnailPath: localThumb,
            localPreviewPath: nil
        )
        items.insert(item, at: 0)
        saveItems()
    }
}
