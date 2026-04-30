import SwiftUI

/// Endpoint ID（UserDefaults）；火山 API Key 由应用内置，不在设置中展示或填写。
struct SettingsView: View {
    @EnvironmentObject private var store: WallpaperStore
    @EnvironmentObject private var subscription: SubscriptionManager
    @State private var arkModel = ""
    @State private var savedToast = false
    @State private var showMembership = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showMembership = true
                    } label: {
                        HStack {
                            Label("Livewall 会员", systemImage: "crown.fill")
                                .foregroundStyle(AppTheme.navActive)
                            Spacer()
                            if subscription.isSubscribed {
                                Text("已开通")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("会员")
                }

                Section {
                    TextField("模型 Model ID（可选，留空用默认 Seedance）", text: $arkModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("火山方舟 Ark")
                } footer: {
                    Text("默认模型：\(ArkSeedanceConfig.defaultModel)。API Key 通过编译配置注入（VOLCANO_API_KEY），与控制台 ARK_API_KEY 相同密钥即可。")
                }

                Section {
                    Button("保存") {
                        store.arkModelId = arkModel.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.persistArkModel()
                        savedToast = true
                    }
                    .foregroundStyle(AppTheme.gradientStart)
                }

                Section {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("隐私政策")
                    }
                    NavigationLink {
                        UserAgreementView()
                    } label: {
                        Text("用户协议")
                    }
                    NavigationLink {
                        TechnicalSupportView()
                    } label: {
                        Text("技术支持")
                    }
                } header: {
                    Text("法律信息")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("设置")
            .onAppear {
                arkModel = store.arkModelId
            }
            .alert("已保存", isPresented: $savedToast) {
                Button("好", role: .cancel) {}
            }
            .sheet(isPresented: $showMembership) {
                MembershipView()
            }
            .onChange(of: showMembership) { isPresented in
                if !isPresented {
                    Task { await subscription.refreshEntitlements() }
                }
            }
            .task {
                await subscription.refreshAll()
            }
        }
    }
}
