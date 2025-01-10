import Photos
import SwiftUI

struct LocalImageView: View {
    private let asset: LocalAsset
    private let size: CGSize
    private let scaleType: ScaleType
    private let shouldShowVideoDuration: Bool
    private var isCircle: Bool = false
    private let radius: CGFloat
    private var autoHeight: Bool = false
    
    @StateObject var resolver: LocalImageResolver

    init(asset: LocalAsset,
         size: CGSize,
         scaleType: ScaleType = .fill,
         shouldShowVideoDuration: Bool = false,
         isCircle: Bool = false,
         radius: CGFloat = 0,
         autoHeight: Bool = false)
    {
        self._resolver = StateObject(wrappedValue: LocalImageResolver(asset: asset, size: size))
        self.asset = asset
        self.size = size
        self.scaleType = scaleType
        self.shouldShowVideoDuration = shouldShowVideoDuration
        self.isCircle = isCircle
        self.radius = radius
        self.autoHeight = autoHeight
    }
        
    var body: some View {
        ZStack {
            if let image = resolver.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .applyScale(type: scaleType)
                    .cornerRadius(radius)
                    .applySize(size: size, autoHeight: autoHeight)
                    .applyClip(isCircle: isCircle)
                    .cornerRadius(radius)
                    .contentShape(RoundedRectangle(cornerRadius: radius))
            } else {
                ProgressView()
                    .applySize(size: size)
            }
            
            if shouldShowVideoDuration {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Text(asset.displayDurationSecond)
                        Spacer4()
                    }
                    Spacer4()
                }
            }
        }
        .onAppear {
            resolver.loadImg()
        }
        .onDisappear {
            resolver.clean()
        }
    }
}

@MainActor
class LocalImageResolver: ObservableObject {
    private let asset: LocalAsset
    private let size: CGSize
    private var requestID: PHImageRequestID?
    
    @Published var displayImage: UIImage?
    
    init(asset: LocalAsset, size: CGSize) {
        self.asset = asset
        self.size = size
    }
    
    func loadImg() {
        Task {
            let fromCache = await imageFromCache()
            if !fromCache {
                imageFromLocalDevice()
            }
        }
    }
    
    func imageFromCache() async -> Bool {
        guard let cacheImage = await DiskCachedImageStore.shared.get(key: asset.id) else { return false }
        displayImage = cacheImage
        return true
    }
    
    func imageFromLocalDevice() {
        requestID = PhotosClient.liveValue.requestCachedImage(
            asset: asset,
            targetSize: CGSize(width: size.width * 2, height: size.height * 2),
            completion: { image in
                guard let image = image else {
                    return
                }
                Task {
                    await DiskCachedImageStore.shared.set(key: self.asset.id, image: image)
                    self.displayImage = image
                }
            })
    }
    
    func clean() {
        if let requestID = requestID {
            PHCachingImageManager.default().cancelImageRequest(requestID)
        }
    }
}
