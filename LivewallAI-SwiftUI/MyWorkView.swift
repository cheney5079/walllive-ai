import SwiftUI
import UIKit

/// 我的作品：空状态 + 双列网格 + 详情播放
struct MyWorkView: View {
    @EnvironmentObject private var store: WallpaperStore
    var onGoGenerate: () -> Void = {}

    private let cols = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if store.items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: cols, spacing: 14) {
                            ForEach(store.items) { item in
                                NavigationLink {
                                    VideoDetailView(item: item)
                                } label: {
                                    WorkCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("我的作品")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Text("这里空空如也\n你的动态作品将展示在这里")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)

            Button {
                onGoGenerate()
            } label: {
                Text("去生成")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(AppTheme.surface)
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
                .padding(20)
        )
    }
}

private struct WorkCard: View {
    let item: WallpaperItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                thumb
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.56, contentMode: .fill)
                    .clipped()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(item.formattedTime)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)

            Text(item.effectLabel)
                .font(.caption2)
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
    }

    @ViewBuilder private var thumb: some View {
        if let p = item.localThumbnailPath, FileManager.default.fileExists(atPath: p),
           let ui = UIImage(contentsOfFile: p) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else if let p = item.localPreviewPath, FileManager.default.fileExists(atPath: p),
                  let ui = UIImage(contentsOfFile: p) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(colors: [AppTheme.gradientStart, AppTheme.gradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.5))
                }
        }
    }
}
