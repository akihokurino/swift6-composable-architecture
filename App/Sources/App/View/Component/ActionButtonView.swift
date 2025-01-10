import SwiftUI

struct ActionButtonView: View {
    let text: String
    let buttonType: ActionButtonType
    let icon: Image?
    let action: () -> Void

    init(text: String, buttonType: ActionButtonType, icon: Image? = nil, action: @escaping () -> Void) {
        self.text = text
        self.buttonType = buttonType
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack {
                HStack {
                    Spacer()
                    if let icon = icon {
                        icon
                        Spacer4()
                    }
                    Text(text)
                        .foregroundColor(buttonType.textColor)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Capsule().foregroundColor(buttonType.backgroundColor))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension ActionButtonView {
    enum ActionButtonType {
        case primary
        case normal
        case destructive
        case disable

        var backgroundColor: Color {
            switch self {
            case .primary:
                return Color.accentColor
            case .normal:
                return Color(UIColor.tertiarySystemFill)
            case .destructive:
                return Color(UIColor.tertiarySystemFill)
            case .disable:
                return Color(.secondaryLabel)
            }
        }

        var textColor: Color {
            switch self {
            case .primary:
                return Color.white
            case .normal:
                return Color(UIColor.label)
            case .destructive:
                return Color(UIColor.systemRed)
            case .disable:
                return Color.white
            }
        }
    }
}
