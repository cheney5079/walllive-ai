import Foundation

/// 隐私政策 / 用户协议线上 H5 地址（由 Info.plist 注入，配置见 `Configs/Legal.urls.xcconfig`）
enum LegalURLs {
    private static let privacyKey = "LegalPrivacyPolicyURL"
    private static let termsKey = "LegalUserAgreementURL"
    private static let supportKey = "LegalSupportURL"

    static var privacyPolicyURL: URL? {
        url(fromPlistKey: privacyKey)
    }

    static var userAgreementURL: URL? {
        url(fromPlistKey: termsKey)
    }

    /// App Store「技术支持网址」等同线上页面（见 Configs/Legal.urls.xcconfig）
    static var technicalSupportURL: URL? {
        url(fromPlistKey: supportKey)
    }

    private static func url(fromPlistKey key: String) -> URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let u = URL(string: trimmed) else { return nil }
        guard let scheme = u.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        return u
    }
}
