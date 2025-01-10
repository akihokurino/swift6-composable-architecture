import SwiftUI

struct ProgressIndicatorView: View {
    let text: String
    var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .foregroundStyle(Color(.secondaryLabel))
                .font(.footnote)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
            ProgressView(value: value)
                .tint(.blue)
        }
        .background(Color(.secondarySystemBackground))
        .frame(height: 48)
        .frame(maxWidth: .infinity)
    }
}
