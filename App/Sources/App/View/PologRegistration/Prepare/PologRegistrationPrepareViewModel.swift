import ComposableArchitecture
import Foundation

@Reducer
struct PologRegistrationPrepareReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.swiftDataClient) var swiftDataClient
    @Dependency(\.photosClient) var photosClient
    @Dependency(\.gqlClient) var gqlClient

    @Reducer
    enum Destination {
        case assetSelect(AssetSelectReducer)
    }

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // data
        var drafts: [InputPolog] = []
        var deleteConfirmingDraft: InputPolog?

        // presentation
        var isPresentedDeleteDraftAlert: Bool = false

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
        case startRegistration(InputPolog)
        case deleteDraft

        // setter
        case setDrafts([InputPolog])

        // presentation
        case isPresentedDeleteDraftAlert(Bool)
        case presentDeleteDraftAlert(InputPolog)
        case presentAssetSelectView

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

                return .run { send in
                    do {
                        let drafts: [SD_DraftedPolog] = try swiftDataClient.fetch()

                        var results: [InputPolog] = []
                        for draft in drafts {
                            guard let polog = draft.polog else {
                                continue
                            }
                            do {
                                var thumbnailAsset: Asset?
                                if let id = polog.thumbnailAssetId {
                                    switch polog.thumbnailAssetSource {
                                    case .local:
                                        let localAsset = try await photosClient.getAsset(id: id)
                                        thumbnailAsset = .localAsset(localAsset)
                                    case .groupAsset:
                                        let groupAsset = try (await gqlClient.query(PologAPI.GetGroupAssetQuery(assetId: id))).groupAsset.fragments.groupAssetFragment
                                        thumbnailAsset = .remoteAsset(RemoteAsset.from(asset: groupAsset))
                                    case .pologThumbnail, .pologRouteAsset, .none:
                                        throw AppError.defaultError()
                                    }
                                }

                                var companions: [InputCompanion] = []
                                for id in Array(polog.innerCompanionIds) {
                                    let user = try (await gqlClient.query(PologAPI.GetUserQuery(userId: id))).user.fragments.userFragment
                                    companions.append(.inner(InputInnerCompanion(id: user.id, name: user.fullName, iconUrl: user.iconSignedUrl.url)))
                                }
                                for name in Array(polog.outerCompanionNames) {
                                    companions.append(.outer(InputOuterCompanion(name: name)))
                                }

                                var routes: [InputPologRoute] = []
                                for route in Array(polog.routes) {
                                    let asset: Asset
                                    switch route.assetSource {
                                    case .local:
                                        let localAsset = try await photosClient.getAsset(id: route.assetId)
                                        asset = .localAsset(localAsset)
                                    case .groupAsset:
                                        let groupAsset = try (await gqlClient.query(PologAPI.GetGroupAssetQuery(assetId: route.assetId))).groupAsset.fragments.groupAssetFragment
                                        asset = .remoteAsset(RemoteAsset.from(asset: groupAsset))
                                    case .pologThumbnail, .pologRouteAsset:
                                        throw AppError.defaultError()
                                    }

                                    routes.append(InputPologRoute(
                                        asset: asset,
                                        description: route._description,
                                        isIncludeIndex: route.isIncludeIndex,
                                        updatedAssetDate: route.assetDate,
                                        priceLabel: route.priceLabel,
                                        review: route.review,
                                        transportations: Set(route.transportations),
                                        videoStartSeconds: route.videoStartSeconds,
                                        videoEndSeconds: route.videoEndSeconds,
                                        isVideoMuted: route.isVideoMuted,
                                        isVideoPlaying: false,
                                        spotId: route.spotId
                                    ))
                                }

                                var inputLabel: InputPologLabel?
                                if let label = polog.label {
                                    inputLabel = InputPologLabel(
                                        label1: label.label1,
                                        label2: label.label2,
                                        label3: label.label3
                                    )
                                }

                                results.append(InputPolog(
                                    id: polog.id,
                                    title: polog.title,
                                    forewordHtml: polog.forewordHtml,
                                    afterwordHtml: polog.afterwordHtml,
                                    label: inputLabel,
                                    thumbnail: thumbnailAsset,
                                    tags: polog.tags.map { InputTag(value: $0) },
                                    companions: companions,
                                    visibility: polog.visibility,
                                    isCommentable: polog.isCommentable,
                                    routes: routes,
                                    draftedAt: draft.createdAt
                                ))
                            } catch {
                                continue
                            }
                        }

                        await send(.setDrafts(results))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
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
                return .run { _ in
                    await dismiss()
                }
            case .startRegistration:
                // delegate
                return .none
            case .deleteDraft:
                guard let inputPolog = state.deleteConfirmingDraft else {
                    return .none
                }

                let currentDrafts = state.drafts
                return .run { send in
                    do {
                        try swiftDataClient.delete(item: SD_DraftedPolog(polog: inputPolog))
                        await send(.setDrafts(currentDrafts.filter { $0.id != inputPolog.id }))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setDrafts(let drafts):
                state.drafts = drafts
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .isPresentedDeleteDraftAlert(let val):
                state.isPresentedDeleteDraftAlert = val
                return .none
            case .presentDeleteDraftAlert(let inputPolog):
                state.deleteConfirmingDraft = inputPolog
                state.isPresentedDeleteDraftAlert = true
                return .none
            case .presentAssetSelectView:
                state.destination = .assetSelect(AssetSelectReducer.State())
                return .none
            // ----------------------------------------------------------------
            // destination
            // ----------------------------------------------------------------
            case .destination(let action):
                guard let action = action.presented else {
                    return .none
                }
                switch action {
                case .assetSelect(let action):
                    switch action {
                    case .finish(let selected):
                        let inputs = selected.map { InputPologRoute(asset: $0) }
                        let sorted = inputs.sorted { $0.assetDate < $1.assetDate }

                        return Effect.send(.startRegistration(InputPolog.new(routes: sorted)))
                    default:
                        return .none
                    }
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension PologRegistrationPrepareReducer.Destination.State: Equatable {}
