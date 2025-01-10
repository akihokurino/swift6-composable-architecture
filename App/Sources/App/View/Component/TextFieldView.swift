import SwiftUI

struct TextFieldView: View {
    @Binding var value: String
    @FocusState var focus: Bool

    let placeholder: String
    let keyboardType: UIKeyboardType
    var height: CGFloat = 50
    var isDisable: Bool = false
    var submitLabel: SubmitLabel = .done
    var leftIcon: Image?
    var hasCloseButton: Bool = false
    var onCommit: ((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            if let icon = leftIcon {
                icon
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer8()
            }

            TextField(placeholder, text: $value, onEditingChanged: { _ in

            }, onCommit: {
                if let fn = onCommit {
                    fn(value)
                }
            })
            .disabled(isDisable)
            .keyboardType(keyboardType)
            .textFieldStyle(PlainTextFieldStyle())
            .frame(height: height)
            .submitLabel(submitLabel)
            .focused($focus)

            if hasCloseButton && self.value.isNotEmpty {
                Spacer8()
                Button(
                    action: {
                        self.value = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
            }
        }
        .frame(height: height)
        .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
        .background(Color(UIColor.quaternarySystemFill))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.clear, lineWidth: 1)
        )
    }
}
