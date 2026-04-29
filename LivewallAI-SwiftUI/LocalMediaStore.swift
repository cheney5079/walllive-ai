import AVFoundation
import Foundation
import UIKit

/// 下载 MP4 到 Documents，并用 AVAssetImageGenerator 截取首帧当封面
enum LocalMediaStore {
    static var livewallRoot: URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return doc.appendingPathComponent("livewall", isDirectory: true)
    }

    static func saveVideoAndThumbnail(from remoteURL: URL, itemId: UUID) async throws -> (videoPath: String, thumbPath: String?) {
        let videoDir = livewallRoot.appendingPathComponent("videos", isDirectory: true)
        let thumbDir = livewallRoot.appendingPathComponent("thumbs", isDirectory: true)
        try FileManager.default.createDirectory(at: videoDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: thumbDir, withIntermediateDirectories: true)

        let destVideo = videoDir.appendingPathComponent("\(itemId.uuidString).mp4")
        let (tmpURL, _) = try await URLSession.shared.download(from: remoteURL)
        if FileManager.default.fileExists(atPath: destVideo.path) {
            try FileManager.default.removeItem(at: destVideo)
        }
        try FileManager.default.moveItem(at: tmpURL, to: destVideo)

        let thumbURL = thumbDir.appendingPathComponent("\(itemId.uuidString).jpg")
        let thumbPath = try await generateThumbnail(videoURL: destVideo, outputURL: thumbURL)
        return (destVideo.path, thumbPath)
    }

    private static func generateThumbnail(videoURL: URL, outputURL: URL) async throws -> String? {
        let asset = AVURLAsset(url: videoURL)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.3, preferredTimescale: 600)
        do {
            let (cg, _) = try await gen.image(at: time)
            let ui = UIImage(cgImage: cg)
            guard let data = ui.jpegData(compressionQuality: 0.88) else { return nil }
            try data.write(to: outputURL)
            return outputURL.path
        } catch {
            return nil
        }
    }

    static func deleteFiles(video: String?, thumbnail: String?) {
        [video, thumbnail].compactMap { $0 }.forEach { path in
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
