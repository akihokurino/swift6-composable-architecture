import SwiftUI
import UIKit

struct TextAreaView: UIViewRepresentable {
    let maxLength: Int

    var placeholder: String = ""

    @Binding var value: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.text = value
        textView.textColor = UIColor.label
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0

        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = UIColor.placeholderText
        placeholderLabel.font = UIFont.preferredFont(forTextStyle: .body)
        placeholderLabel.numberOfLines = 0
        placeholderLabel.lineBreakMode = .byWordWrapping
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)
        placeholderLabel.isHidden = !value.isEmpty

        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: textView.bottomAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -5)
        ])

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "閉じる", style: .done, target: context.coordinator, action: #selector(context.coordinator.closeKeyboard))
        toolbar.items = [flexSpace, doneButton]
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if let placeholderLabel = textView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            placeholderLabel.preferredMaxLayoutWidth = textView.frame.width - textView.textContainerInset.left - textView.textContainerInset.right - 2 * textView.textContainer.lineFragmentPadding
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private var parent: TextAreaView

        init(_ textView: TextAreaView) {
            parent = textView
        }

        func textViewDidBeginEditing(_ textView: UITextView) {}

        func textViewDidChange(_ textView: UITextView) {
            updatePlaceholderVisibility(in: textView)
            parent.value = textView.text
        }

        func textViewDidEndEditing(_ textView: UITextView) {}

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            return newText.count <= parent.maxLength
        }

        @objc func closeKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func updatePlaceholderVisibility(in textView: UITextView) {
            if let placeholderLabel = textView.subviews.compactMap({ $0 as? UILabel }).first {
                placeholderLabel.isHidden = !textView.text.isEmpty
            }
        }
    }
}
