import SwiftUI

struct SelectedButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .fontWeight(isSelected ? .medium : .regular)
            .foregroundColor(isSelected ? Color(UIColor(named: "AccentColor")!) : Color.primary)
            .padding(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
            .background(Color(isSelected ? UIColor(named: "AccentColor")!.withAlphaComponent(0.12) : .systemBackground))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(isSelected ? UIColor(named: "AccentColor")! : .opaqueSeparator), lineWidth: 1)
            )
    }
}
