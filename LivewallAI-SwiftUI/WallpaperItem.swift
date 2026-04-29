import Foundation

/// 一条「我的作品」记录（本地持久化 + 可选网络视频 URL）
struct WallpaperItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    /// 火山返回的可访问 MP4 地址
    var videoURLString: String
    let createdAt: Date
    let effectLabel: String
    /// 本地缓存视频路径（Documents）
    var localVideoPath: String?
    /// 本地缩略图路径
    var localThumbnailPath: String?
    /// 生成前所选照片的本地路径（可选占位）
    var localPreviewPath: String?

    var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: createdAt)
    }
}
