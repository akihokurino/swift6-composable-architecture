import SwiftUI

struct ChipView: View {
    let value: String
    let onTap: () -> Void
    var backgroundColor: Color = .blue
    var textColor: Color = .white
    var borderColor: Color = .black
    var isDeletable: Bool = false
    var isBorder: Bool = false
    var icon: (() -> Image)? = nil
    var iconColor: Color = .black

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                icon().foregroundColor(iconColor)
            }
            Text(value)
                .lineLimit(1)
                .font(.footnote)
                .foregroundColor(textColor)
            if isDeletable {
                Image(systemName: "xmark")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .foregroundColor(textColor)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isBorder ? borderColor : Color.clear, lineWidth: isBorder ? 1 : 0)
        )
        .onTapGesture {
            onTap()
        }
    }
}
