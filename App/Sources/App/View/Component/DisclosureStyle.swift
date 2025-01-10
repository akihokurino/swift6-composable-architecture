import SwiftUI

struct DisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            HStack {
                configuration.label

                Spacer()

                if configuration.isExpanded {
                    Image(systemName: "chevron.up")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                } else {
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                Spacer16()
            }
            .tint(.primary)
            .contentShape(Rectangle())

            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}
