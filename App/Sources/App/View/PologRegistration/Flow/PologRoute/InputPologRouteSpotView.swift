import ComposableArchitecture
import SwiftUI

extension PologRouteRegistrationView {
    struct InputPologRouteSpotView: View {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>

        @State var value = Date()
        @State private var isPresentedDatePicker = false
        @State private var isPresentedTimePicker = false

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading) {
                    Spacer12()

                    Button(action: {}) {
                        HStack {
                            Spacer16()
                            Text("スポット")
                                .font(.body)
                                .foregroundColor(Color(UIColor.label))
                            Spacer()
                            Text("東京ディズニーランド")
                                .font(.body)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            Spacer8()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                            Spacer16()
                        }
                        .frame(height: 60)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10.0)
                    }
                    .padding(.horizontal, 16)

                    Spacer4()
                    Text("写真に位置情報が含まれている場合、初期値として設定されます")
                        .font(.callout)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 32)
                    Spacer16()

                    HStack {
                        Spacer16()
                        Text("撮影日")
                            .font(.body)
                            .foregroundColor(Color(UIColor.label))
                        Spacer()
                        Button(action: {
                            isPresentedDatePicker = true
                        }) {
                            Text(value.dateString)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .foregroundColor(.blue)
                        }
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color(UIColor.quaternarySystemFill)))
                        Spacer8()
                        Button(action: {
                            isPresentedTimePicker = true
                        }) {
                            Text(value.timeString)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .foregroundColor(.blue)
                        }
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color(UIColor.quaternarySystemFill)))
                        Spacer16()
                    }
                    .frame(height: 60)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10.0)
                    .padding(.horizontal, 16)

                    Spacer8()
                    Text("撮影日を変更した場合、ページの順番に変動がある場合があります")
                        .font(.callout)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 32)
                    Spacer16()

                    Spacer()
                }
                .navigationTitle("編集")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button(action: {
                    store.send(.isPresentedInputSpotView(false))
                }) {
                    Text("キャンセル")
                        .foregroundColor(Color(UIColor.label))
                }, trailing: Button(action: {
                    store.send(.setPologRouteAssetDate(value))
                    store.send(.isPresentedInputSpotView(false))
                }) {
                    Text("確定")
                        .bold()
                        .foregroundColor(Color(UIColor.label))
                })
                .sheet(isPresented: $isPresentedDatePicker) {
                    DatePickerView(onClose: {
                        isPresentedDatePicker = false
                    }, onDone: { date in
                        value = value.updateYMD(by: date)
                        isPresentedDatePicker = false
                    }, value: value)
                        .presentationDetents([.medium])
                }
                .sheet(isPresented: $isPresentedTimePicker) {
                    TimePickerView(onClose: {
                        isPresentedTimePicker = false
                    }, onDone: { date in
                        value = value.updateHMS(by: date)
                        isPresentedTimePicker = false
                    }, value: value)
                        .presentationDetents([.medium])
                }
            }
        }
    }
}
