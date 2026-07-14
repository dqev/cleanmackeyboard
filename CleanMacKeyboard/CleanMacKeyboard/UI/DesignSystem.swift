import SwiftUI

enum DS {

    static let accent = Color.accentColor
    static let accentActive = Color(red: 0.4, green: 0.55, blue: 0.95)
    static let background = Color(.windowBackgroundColor)
    static let secondaryBg = Color(nsColor: .underPageBackgroundColor)
    static let groupedBg = Color(.controlBackgroundColor)
    static let separator = Color(.separatorColor).opacity(0.4)

    static let secondaryLabel = Color(.secondaryLabelColor)
    static let tertiaryLabel = Color(.tertiaryLabelColor)

    static let lockAccent  = Color(red: 131/255, green: 99/255, blue: 214/255)
    static let lockDim     = Color(red: 131/255, green: 99/255, blue: 214/255).opacity(0.12)
    static let unlockAccent = Color.green

    static let cardFill = Color(nsColor: .quaternarySystemFill)

    static let popoverWidth: CGFloat = 380

    static let windowBg = Color(red: 24/255, green: 24/255, blue: 24/255)
    static let surfaceBg = Color(red: 30/255, green: 30/255, blue: 30/255)
    static let cardBg = Color(red: 38/255, green: 38/255, blue: 38/255)
    static let borderColor = Color(red: 48/255, green: 48/255, blue: 48/255)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
    }

    enum FontSize {
        static let caption: CGFloat = 10
        static let body: CGFloat = 12
        static let subhead: CGFloat = 11
        static let title: CGFloat = 14
        static let large: CGFloat = 16
        static let largeTitle: CGFloat = 28
        static let timer: CGFloat = 56
    }
}

extension NSColor {
    convenience init?(fromHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
