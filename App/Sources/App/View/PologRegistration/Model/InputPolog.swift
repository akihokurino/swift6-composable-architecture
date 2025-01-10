import Foundation

struct InputPolog: Equatable {
    let id: String
    var title: String = ""
    var forewordHtml: String?
    var afterwordHtml: String?
    var label: InputPologLabel?
    var thumbnail: Asset?
    var tags: [InputTag] = []
    var companions: [InputCompanion] = []
    var visibility: PologVisibility?
    var isCommentable: Bool = false
    var routes: [InputPologRoute] = []
    var draftedAt: Date?
    var isEdit: Bool = false

    var idForViewRendering = UUID()

    var displayDraftedAtJST: String {
        guard let date = draftedAt else {
            return ""
        }

        return date.dateTimeDisplayJST
    }

    var isDraft: Bool {
        return draftedAt != nil
    }

    static func new(routes: [InputPologRoute]) -> InputPolog {
        return InputPolog(
            id: UUID().uuidString,
            routes: routes
        )
    }

    static func from(polog: Polog) -> InputPolog {
        return InputPolog(
            id: polog.id,
            title: polog.title,
            forewordHtml: polog.forewordHtml,
            afterwordHtml: polog.afterwordHtml,
            label: InputPologLabel(
                label1: polog.label.label1 ?? "",
                label2: polog.label.label2 ?? "",
                label3: polog.label.label3 ?? ""
            ),
            thumbnail: .remoteAsset(RemoteAsset.from(asset: polog)),
            tags: polog.tags.map { InputTag(value: $0) },
            companions: polog.companions.map { InputCompanion.inner(InputInnerCompanion(id: $0.id, name: $0.fullName, iconUrl: $0.iconSignedUrl.url)) } + polog.outerCompanionNames.map { InputCompanion.outer(InputOuterCompanion(name: $0)) },
            visibility: polog.visibility.value!,
            isCommentable: polog.isCommentable,
            routes: polog.routes.map { InputPologRoute.from(route: $0.fragments.pologRouteFragment) },
            isEdit: true
        )
    }
}

struct InputPologLabel: Equatable {
    let label1: String
    let label2: String
    let label3: String
}

struct InputTag: Identifiable, Equatable {
    let id: String = UUID().uuidString
    let value: String
}

enum InputCompanion: Identifiable, Equatable, Hashable {
    case inner(InputInnerCompanion)
    case outer(InputOuterCompanion)

    var id: String {
        switch self {
        case .inner(let user):
            return user.id
        case .outer(let user):
            return user.id
        }
    }

    var name: String {
        switch self {
        case .inner(let user):
            return user.name
        case .outer(let user):
            return user.name
        }
    }

    var iconUrl: URL? {
        switch self {
        case .inner(let user):
            return user.iconUrl
        case .outer:
            return nil
        }
    }
}

struct InputInnerCompanion: Equatable, Hashable {
    let id: String
    let name: String
    let iconUrl: URL?
}

struct InputOuterCompanion: Equatable, Hashable {
    let id: String = UUID().uuidString
    let name: String
}
