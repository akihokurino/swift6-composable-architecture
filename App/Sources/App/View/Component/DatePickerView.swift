import SwiftUI

struct DatePickerView: View {
    let onClose: () -> Void
    let onDone: (Date) -> Void

    @State var value = Date()

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                DatePicker("", selection: $value, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
                Spacer()
            }
            .navigationTitle("日付の選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                onClose()
            }) {
                Text("キャンセル")
            }, trailing: Button(action: {
                onDone(value)
            }) {
                Text("確定")
            })
        }
    }
}
