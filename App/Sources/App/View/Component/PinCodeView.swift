import SwiftUI

struct PinCodeView: View {
    @State private var pin: [String] = Array(repeating: "", count: 6)
    @State private var shouldChangeFocus = true
    @FocusState private var focusedField: Int?

    @Binding var value: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< 6) { index in
                Group {
                    CustomTextField(
                        text: $pin[index],
                        placeholder: "",
                        keyboardType: .numberPad,
                        textAlignment: .center,
                        onDeleteBackward: { isEmptyText in
                            if (index != 0 && index != 5) || (index == 5 && isEmptyText) {
                                focusedField = index - 1
                                pin[index - 1] = ""
                            }
                        }
                    )
                    .frame(width: 48, height: 56)
                    .focused($focusedField, equals: index)
                    .onChange(of: pin[index]) { newValue in
                        if newValue.count == 6 {
                            for (index, character) in newValue.enumerated() {
                                pin[index] = String(character)
                            }
                            focusedField = 5
                            value = pin.joined()
                        } else {
                            if pin.count > 1 {
                                pin[index] = String(newValue.prefix(1))
                            }
                            handleInputChange(at: index)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding()
        .onAppear {
            focusedField = 0
        }
    }

    private func handleInputChange(at index: Int) {
        if shouldChangeFocus, pin[index].isNotEmpty, index < 5 {
            shouldChangeFocus = false
            focusedField = index + 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shouldChangeFocus = true
            }
        }

        if pin.allSatisfy({ $0.isNotEmpty }) {
            value = pin.joined()
        } else {
            value = ""
        }
    }
}

extension PinCodeView {
    class CustomUITextField: UITextField {
        var onDeleteBackward: ((Bool) -> Void)?

        override func deleteBackward() {
            let isEmptyText = text?.isEmpty ?? false
            super.deleteBackward()
            onDeleteBackward?(isEmptyText)
        }
    }

    struct CustomTextField: UIViewRepresentable {
        @Binding var text: String
        var placeholder: String
        var keyboardType: UIKeyboardType = .default
        var textAlignment: NSTextAlignment = .natural
        var onDeleteBackward: (Bool) -> Void

        class Coordinator: NSObject, UITextFieldDelegate {
            var parent: CustomTextField

            init(parent: CustomTextField) {
                self.parent = parent
            }

            @objc func textFieldDidChange(_ textField: UITextField) {
                parent.text = textField.text ?? ""
            }
        }

        func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> CustomUITextField {
            let textField = CustomUITextField()
            textField.placeholder = placeholder
            textField.textAlignment = textAlignment
            textField.keyboardType = keyboardType
            textField.textContentType = .oneTimeCode
            textField.delegate = context.coordinator
            textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
            textField.onDeleteBackward = { isEmptyText in
                self.onDeleteBackward(isEmptyText)
            }
            return textField
        }

        func updateUIView(_ uiView: CustomUITextField, context: Context) {
            uiView.text = text
        }
    }
}
