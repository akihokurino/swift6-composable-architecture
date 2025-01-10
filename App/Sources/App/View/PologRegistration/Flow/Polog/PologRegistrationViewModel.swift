import ComposableArchitecture
import Foundation

@Reducer
struct PologRegistrationReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.swiftDataClient) var swiftDataClient

    @Reducer
    enum Destination {
        case thumbnailRegistration(PologThumbnailRegistrationReducer)
        case companionRegistration(PologCompanionRegistrationReducer)
    }

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // data
        var inputPolog: InputPolog
        var actionSheetType: ActionSheetType = .menuForCreate

        // presentation
        var isPresentedActionSheet = false
        var isPresentedCreateConfirmAlert = false
        var isPresentedDeleteDraftAlert = false

        // destination
        @Presents var destination: Destination.State?
    }

    enum Action {
        // common
        case initialize
        case setAlert(AlertEntity)
        case isPresentedHUD(Bool)
        case isPresentedAlert(Bool)

        // action
        case dismiss
        case syncInput(InputPolog)
        case confirm
        case register(InputPolog)
        case draft(InputPolog)
        case cancel
        case deleteDraft

        // setter
        case setTitle(String)
        case setTag(InputTag)
        case deleteTag(InputTag)
        case setVisibility(PologVisibility)
        case setIsCommentable(Bool)

        // presentation
        case presentPologThumbnailRegistrationView
        case presentPologCompanionRegistrationView
        case presentMenuActionSheet
        case isPresentedActionSheet(Bool)
        case isPresentedCreateConfirmAlert(Bool)
        case isPresentedDeleteDraftAlert(Bool)

        // destination
        case destination(PresentationAction<Destination.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // ----------------------------------------------------------------
            // common
            // ----------------------------------------------------------------
            case .initialize:
                guard !state.isInitialized else {
                    return .none
                }
                state.isInitialized = true
                return .none
            case .setAlert(let entity):
                state.alert = entity
                state.isPresentedAlert = true
                return .none
            case .isPresentedHUD(let val):
                state.isPresentedHUD = val
                return .none
            case .isPresentedAlert(let val):
                state.isPresentedAlert = val
                return .none
            // ----------------------------------------------------------------
            // action
            // ----------------------------------------------------------------
            case .dismiss:
                let input = state.inputPolog
                return .run { send in
                    await send(.syncInput(input))
                    await dismiss()
                }
            case .syncInput:
                // delegate
                return .none
            case .confirm:
                guard state.inputPolog.title != "" && state.inputPolog.thumbnail != nil && state.inputPolog.visibility != nil else {
                    var message = "以下の必須項目を入力してください\n\n"
                    if state.inputPolog.title == "" {
                        message += "・タイトル\n"
                    }
                    if state.inputPolog.thumbnail == nil {
                        message += "・表紙\n"
                    }
                    if state.inputPolog.visibility == nil {
                        message += "・公開範囲\n"
                    }
                    state.alert = AlertEntity(title: "未入力の項目があります", message: message)
                    state.isPresentedAlert = true
                    return .none
                }

                state.isPresentedCreateConfirmAlert = true
                return .none
            case .register:
                // delegate
                return .none
            case .draft:
                // delegate
                return .none
            case .cancel:
                // delegate
                return .none
            case .deleteDraft:
                let inputPolog = state.inputPolog
                let draftedPolog = SD_DraftedPolog(polog: inputPolog)
                return .run { send in
                    do {
                        try swiftDataClient.delete(item: draftedPolog)
                        await send(.cancel)
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setTitle(let val):
                state.inputPolog.title = val
                return .none
            case .setTag(let val):
                state.inputPolog.tags.append(val)
                return .none
            case .deleteTag(let val):
                guard let index = state.inputPolog.tags.firstIndex(where: { $0.id == val.id }) else {
                    return .none
                }
                state.inputPolog.tags.remove(at: index)
                return .none
            case .setVisibility(let val):
                state.inputPolog.visibility = val
                return .none
            case .setIsCommentable(let val):
                state.inputPolog.isCommentable = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .presentPologThumbnailRegistrationView:
                state.destination = .thumbnailRegistration(PologThumbnailRegistrationReducer.State(
                    thumbnail: state.inputPolog.thumbnail,
                    topLabel: state.inputPolog.label?.label1 ?? "",
                    middleLabel: state.inputPolog.label?.label2 ?? "",
                    bottomLabel: state.inputPolog.label?.label3 ?? ""
                ))
                return .none
            case .presentPologCompanionRegistrationView:
                state.destination = .companionRegistration(PologCompanionRegistrationReducer.State(
                    companions: state.inputPolog.companions
                ))
                return .none
            case .presentMenuActionSheet:
                if state.inputPolog.isEdit {
                    state.actionSheetType = .menuForEdit
                } else if state.inputPolog.isDraft {
                    state.actionSheetType = .menuForDraft
                } else {
                    state.actionSheetType = .menuForCreate
                }

                state.isPresentedActionSheet = true
                return .none
            case .isPresentedActionSheet(let val):
                state.isPresentedActionSheet = val
                return .none
            case .isPresentedCreateConfirmAlert(let val):
                state.isPresentedCreateConfirmAlert = val
                return .none
            case .isPresentedDeleteDraftAlert(let val):
                state.isPresentedDeleteDraftAlert = val
                return .none
            // ----------------------------------------------------------------
            // destination
            // ----------------------------------------------------------------
            case .destination(let action):
                guard let action = action.presented else {
                    return .none
                }
                switch action {
                case .thumbnailRegistration(let action):
                    switch action {
                    case .finish(let result):
                        state.inputPolog.thumbnail = result.0
                        state.inputPolog.label = result.1
                        return .none
                    default:
                        return .none
                    }
                case .companionRegistration(let action):
                    switch action {
                    case .finish(let result):
                        state.inputPolog.companions = result
                        return .none
                    default:
                        return .none
                    }
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    enum ActionSheetType {
        case menuForCreate
        case menuForDraft
        case menuForEdit
    }
}

extension PologRegistrationReducer.Destination.State: Equatable {}
