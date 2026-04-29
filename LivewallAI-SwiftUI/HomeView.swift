import PhotosUI
import SwiftUI
import UIKit

/// 首页：选图、效果 Chips、可选 Prompt、渐变生成按钮
struct HomeView: View {
    @EnvironmentObject private var store: WallpaperStore
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoJPEG: Data?
    @State private var selectedEffect = EffectOption.all[0]
    @State private var extraPrompt = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        uploadCard

                        Text("动态效果")
                            .font(.headline)
                            .foregroundStyle(.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(EffectOption.all) { opt in
                                    chip(opt)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("补充描述（可选）")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.muted)
                            TextField("光线、氛围、镜头…", text: $extraPrompt, axis: .vertical)
                                .lineLimit(3 ... 6)
                                .padding(12)
                                .background(AppTheme.surfaceVariant)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                VStack {
                    Spacer()
                    gradientGenerateButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
            }
            .navigationTitle("Livewall AI")
            .navigationBarTitleDisplayMode(.large)
            .alert("生成失败", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay {
                if store.isGenerating {
                    generatingOverlay
                }
            }
        }
    }

    private var uploadCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surface)
                .shadow(color: .black.opacity(0.35), radius: 24, y: 16)

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]),
                    antialiased: true
                )
                .foregroundStyle(AppTheme.muted.opacity(0.45))

            VStack(spacing: 16) {
                if let data = photoJPEG, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("重新上传", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.gradientEnd)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.primaryGradient)
                        .padding(16)
                        .background(
                            Circle().fill(AppTheme.gradientStart.opacity(0.22))
                        )

                    Text("上传照片，AI 让它动起来")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("支持人物、宠物、风景，一键生成动态壁纸")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Text("点击选择照片")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.gradientEnd)
                    }
                }
            }
            .padding(24)
        }
        .onChange(of: pickerItem) { _, new in
            Task { await loadPhoto(new) }
        }
    }

    private func chip(_ opt: EffectOption) -> some View {
        let on = selectedEffect == opt
        return Button {
            selectedEffect = opt
        } label: {
            Text(opt.label)
                .font(.subheadline.weight(on ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(on ? AppTheme.gradientStart.opacity(0.35) : AppTheme.surfaceVariant)
                .clipShape(Capsule())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private var gradientGenerateButton: some View {
        Button {
            Task { await runGenerate() }
        } label: {
            Text(store.isGenerating ? "生成中…" : "生成动态壁纸")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: AppTheme.gradientStart.opacity(0.45), radius: 20, y: 8)
        }
        .disabled(store.isGenerating || photoJPEG == nil)
        .opacity(photoJPEG == nil ? 0.5 : 1)
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(AppTheme.gradientEnd)
                Text(store.statusMessage ?? "处理中…")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
            }
            .padding(24)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(32)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let jpeg: Data?
                if let ui = UIImage(data: data) {
                    jpeg = ui.jpegData(compressionQuality: 0.92)
                } else {
                    jpeg = data
                }
                await MainActor.run { photoJPEG = jpeg }
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func runGenerate() async {
        guard let jpeg = photoJPEG else { return }
        do {
            try await store.generateWallpaper(imageJPEGData: jpeg, effect: selectedEffect, userExtraPrompt: extraPrompt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
