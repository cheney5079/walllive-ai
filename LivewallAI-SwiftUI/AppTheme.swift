import SwiftUI

/// 深色主题 + 紫色渐变品牌色（#6B46FF → #C84CFF）
enum AppTheme {
    static let gradientStart = Color(red: 0x6B / 255, green: 0x46 / 255, blue: 0xFF / 255)
    static let gradientEnd = Color(red: 0xC8 / 255, green: 0x4C / 255, blue: 0xFF / 255)

    static let background = Color(red: 0x0A / 255, green: 0x0A / 255, blue: 0x0B / 255)
    static let surface = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    static let surfaceVariant = Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255)
    static let muted = Color(red: 0xAE / 255, green: 0xAE / 255, blue: 0xB2 / 255)
    static let navActive = Color(red: 0xE8 / 255, green: 0xA3 / 255, blue: 0x17 / 255)

    static let primaryGradient = LinearGradient(
        colors: [gradientStart, gradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
}
