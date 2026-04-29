import Foundation
import Security

/// 简易 Keychain 读写 API Key（开发阶段也可用 UserDefaults，生产建议只用 Keychain）
enum SecureSettings {
    private static let service = "ai.livewall.app"
    private static let apiKeyAccount = "volcano_api_key"

    static func saveAPIKey(_ key: String) {
        let data = Data(key.utf8)
        SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: apiKeyAccount
        ] as CFDictionary)
        SecItemAdd([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: apiKeyAccount,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary, nil)
    }

    static func loadAPIKey() -> String? {
        var result: AnyObject?
        let status = SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: apiKeyAccount,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum UserDefaultsKeys {
    static let endpointId = "livewall_volcano_endpoint_id"
    static let wallpapersJSON = "livewall_wallpapers_json"
}
