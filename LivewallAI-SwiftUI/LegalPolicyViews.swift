import SwiftUI

/// 技术支持（上架可与隐私政策同一域名）
struct TechnicalSupportView: View {
    private let fallbackText = """
Livewall AI（AI Wallpaper App）技术支持

联系邮箱：cheneyc08@gmail.com

生成异常时请检查网络与方舟模型配置；订阅与扣款由 Apple 处理，可在「设置 → Apple ID → 订阅」管理。

相关法律文档见 App 内「隐私政策」「用户协议」。
"""

    var body: some View {
        Group {
            if let url = LegalURLs.technicalSupportURL {
                WebLegalView(url: url, pageTitle: "技术支持")
            } else {
                localScroll(fallbackText)
                    .navigationTitle("技术支持")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

/// 隐私政策：优先打开线上 H5，未配置或加载失败时展示本地 `LegalCopy`
struct PrivacyPolicyView: View {
    var body: some View {
        Group {
            if let url = LegalURLs.privacyPolicyURL {
                WebLegalView(url: url, pageTitle: "隐私政策")
            } else {
                localScroll(LegalCopy.privacyPolicyZH)
                    .navigationTitle("隐私政策")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

/// 用户协议：同上
struct UserAgreementView: View {
    var body: some View {
        Group {
            if let url = LegalURLs.userAgreementURL {
                WebLegalView(url: url, pageTitle: "用户协议")
            } else {
                localScroll(LegalCopy.userAgreementZH)
                    .navigationTitle("用户协议")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

/// 自动续费说明（仍以本地文案为主；若后续单独上线 H5，可再接入 LegalURLs）
struct AutoRenewalAgreementView: View {
    var body: some View {
        localScroll(LegalCopy.autoRenewalAgreementZH)
            .navigationTitle("自动续费说明")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private func localScroll(_ text: String) -> some View {
    ScrollView {
        Text(text)
            .font(.body)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
    }
    .background(AppTheme.background)
}
