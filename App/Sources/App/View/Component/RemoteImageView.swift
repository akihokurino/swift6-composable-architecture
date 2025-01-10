import Nuke
import SwiftUI

struct RemoteImageView: View {
    private let size: CGSize?
    private let isCircle: Bool
    private let radius: CGFloat
    private let isBorder: Bool
    private let borderColor: Color
    private let borderWidth: CGFloat
    private let scaleType: ScaleType
    private var autoHeight: Bool = false
    
    @StateObject var resolver: RemoteImageResolver
    
    init(
        url: URL?,
        size: CGSize? = nil,
        isCircle: Bool = false,
        radius: CGFloat = 0,
        isBorder: Bool = false,
        borderColor: Color = .clear,
        borderWidth: CGFloat = 0,
        scaleType: ScaleType = .fill,
        autoHeight: Bool = false)
    {
        self._resolver = StateObject(wrappedValue: RemoteImageResolver(imageUrl: url))
        self.size = size
        self.isCircle = isCircle
        self.radius = radius
        self.isBorder = isBorder
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.scaleType = scaleType
        self.autoHeight = autoHeight
    }
    
    var body: some View {
        if let image = resolver.displayImage {
            Image(uiImage: image)
                .resizable()
                .applyScale(type: self.scaleType)
                .applySize(size: self.size, autoHeight: self.autoHeight)
                .applyClip(isCircle: self.isCircle)
                .applyBorder(isBorder: self.isBorder, color: self.borderColor, width: self.borderWidth, isCircle: self.isCircle, radius: self.radius)
                .cornerRadius(self.radius)
                .contentShape(RoundedRectangle(cornerRadius: self.radius))
        } else {
            ProgressView()
                .applySize(size: self.size)
        }
    }
}

@MainActor
class RemoteImageResolver: ObservableObject {
    private let imageUrl: URL?
    
    @Published var displayImage: UIImage?
    
    init(imageUrl: URL?) {
        self.imageUrl = imageUrl
        self.loadByNuke()
    }
    
    func loadByNuke() {
        guard let url = imageUrl else {
            return
        }
        
        Task {
            let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let imageRequest = ImageRequest(urlRequest: urlRequest, userInfo: [.imageIdKey: url.withoutQuery.absoluteString])
            do {
                let imageTask = ImagePipeline.custom().imageTask(with: imageRequest)
                let image = try await imageTask.image
                
                self.displayImage = image
            
            } catch {}
        }
    }
}
