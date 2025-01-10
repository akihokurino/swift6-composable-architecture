import SwiftUI

struct IconButtonView: View {
    let label: String
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack {
                Spacer40()
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24, alignment: .center)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(.label))
                Spacer12()
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
            .background(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(.label), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
