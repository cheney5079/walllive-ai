import SwiftUI

/// API Key（Keychain）与 Endpoint ID（UserDefaults）
struct SettingsView: View {
    @EnvironmentObject private var store: WallpaperStore
    @State private var endpoint = ""
    @State private var apiKeyDraft = ""
    @State private var savedToast = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("推理接入点 Endpoint ID（如 ep-xxx）", text: $endpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("火山 API Key", text: $apiKeyDraft)
                } header: {
                    Text("火山方舟")
                } footer: {
                    Text("请在方舟控制台创建 Seedance 图生视频接入点；API Key 仅存于本机 Keychain。")
                }

                Section {
                    Button("保存") {
                        store.endpointId = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.persistEndpoint()
                        store.saveAPIKey(apiKeyDraft)
                        savedToast = true
                    }
                    .foregroundStyle(AppTheme.gradientStart)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("设置")
            .onAppear {
                endpoint = store.endpointId
                apiKeyDraft = store.apiKey() ?? ""
            }
            .alert("已保存", isPresented: $savedToast) {
                Button("好", role: .cancel) {}
            }
        }
    }
}
