import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BrandMarkView: View {
    let size: CGFloat
    var cornerRadius: CGFloat = 20

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let image = brandUIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    PremiumTheme.Palette.accent,
                                    PremiumTheme.Palette.accentSecondary,
                                    PremiumTheme.Palette.info
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: size * 0.72, height: size * 0.72)
                        .offset(x: size * 0.12, y: size * 0.12)
                        .blur(radius: 4)

                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: size * 0.40, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: PremiumTheme.Palette.accent.opacity(0.24), radius: 14, x: 0, y: 10)
        .accessibilityHidden(true)
    }

    private var brandUIImage: UIImage? {
        // Use the new brand assets only.
        UIImage(named: colorScheme == .dark ? "BrandMarkDark" : "BrandMarkGreen")
            ?? UIImage(named: "BrandMarkGreenLogo")
            ?? UIImage(named: "BrandMarkLight")
    }
}
