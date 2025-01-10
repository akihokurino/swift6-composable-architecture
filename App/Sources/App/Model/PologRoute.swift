import Foundation
import SwiftUI

extension PologRoute: Identifiable, HasDate {
    var reviewPriceString: String {
        var reviewString = ""
        if let review = review {
            switch review {
            case 1:
                reviewString = "★"
            case 2:
                reviewString = "★★"
            case 3:
                reviewString = "★★★"
            case 4:
                reviewString = "★★★★"
            case 5:
                reviewString = "★★★★★"
            default:
                reviewString = ""
            }
        }

        if reviewString.isEmpty && priceLabel == nil {
            return ""
        }
        return "\(reviewString)・\(priceLabel ?? "")"
    }

    var isVideo: Bool {
        return assetKind == .video
    }

    var thumbnailURL: URL? {
        if isVideo {
            return videoThumbnailSignedUrl?.url
        } else {
            return assetSignedUrl.url
        }
    }

    var date: Date? {
        return assetDate.iso8601
    }
}

struct PologRouteIndex<T: HasDate & Equatable>: Identifiable, Equatable {
    let date: String
    let routes: [T]

    var id: String {
        return date
    }

    static func from(routes: [T]) -> [PologRouteIndex] {
        let grouped = Dictionary(grouping: routes) { $0.mustDate().dateDisplayJST }
        let indexes = grouped.map { date, routes in
            PologRouteIndex(date: date, routes: routes.sorted { $0.mustDate() < $1.mustDate() })
        }

        return indexes.sorted { $0.date < $1.date }
    }
}

let priceLabelList: [String] = [
    "¥1~1,000",
    "¥1,000~2,000",
    "¥2,000~3,000",
    "¥3,000~4,000",
    "¥4,000~5,000",
    "¥5,000~6,000",
    "¥6,000~7,000",
    "¥7,000~8,000",
    "¥8,000~9,000",
    "¥9,000~10,000",
    "¥10,000~"
]

let transportationList: [Transportation] = [
    Transportation.walk,
    Transportation.car,
    Transportation.taxi,
    Transportation.bus,
    Transportation.train,
    Transportation.bicycle,
    Transportation.bike,
    Transportation.cableCar,
    Transportation.ferry,
    Transportation.airplane
]

extension Transportation {
    var icon: Image? {
        switch self {
        case .walk:
            return Image("IconTransportPedestrian")
        case .car:
            return Image("IconTransportCar")
        case .taxi:
            return Image("IconTransportTaxi")
        case .bus:
            return Image("IconTransportBus")
        case .train:
            return Image("IconTransportTrain")
        case .bicycle:
            return Image("IconTransportBycicle")
        case .bike:
            return Image("IconTransportMotorcycle")
        case .cableCar:
            return Image("IconTransportCableCar")
        case .ferry:
            return Image("IconTransportBoat")
        case .airplane:
            return Image("IconTransportAirplane")
        default:
            return nil
        }
    }
}
