import AVKit
import SwiftUI

/// 全屏播放：优先本地文件，其次网络 URL
struct VideoDetailView: View {
    let item: WallpaperItem
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ProgressView()
                    .tint(AppTheme.gradientEnd)
            }
        }
        .background(Color.black)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setup() }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setup() {
        if let path = item.localVideoPath, FileManager.default.fileExists(atPath: path) {
            player = AVPlayer(url: URL(fileURLWithPath: path))
            return
        }
        if let u = URL(string: item.videoURLString) {
            player = AVPlayer(url: u)
        }
    }
}
