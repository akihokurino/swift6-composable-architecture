import AVKit
import SwiftUI

struct LoopVideoPlayerView: View {
    private let size: CGSize
    private let start: Double
    private let end: Double?
    private let isMuted: Bool
    private let suppressLoop: Bool
    private let isShowControl: Bool
    private let autoHeight: Bool
    @StateObject var resolver: VideoResolver
    @State private var player = AVPlayer()
    @State private var timeObserverToken: Any?
    @State private var currentTime: Double = 0
    @State private var duration: Double?
    @Binding var isPlaying: Bool

    init(asset: LocalAsset,
         size: CGSize,
         start: Double = 0,
         end: Double? = nil,
         isMuted: Bool = false,
         suppressLoop: Bool = false,
         isShowControl: Bool = false,
         autoHeight: Bool = false,
         isPlaying: Binding<Bool> = Binding.constant(true))
    {
        self._resolver = StateObject(wrappedValue: VideoResolver(asset: asset, url: nil))
        self.size = size
        self.start = start
        self.end = end
        self.isMuted = isMuted
        self.suppressLoop = suppressLoop
        self.isShowControl = isShowControl
        self.autoHeight = autoHeight
        self._isPlaying = isPlaying
        UISlider.appearance().setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        UISlider.appearance().minimumTrackTintColor = .systemBlue
    }

    init(url: URL?,
         size: CGSize,
         start: Double = 0,
         end: Double? = nil,
         isMuted: Bool = false,
         suppressLoop: Bool = false,
         isShowControl: Bool = false,
         autoHeight: Bool = false,
         isPlaying: Binding<Bool> = Binding.constant(true))
    {
        self._resolver = StateObject(wrappedValue: VideoResolver(asset: nil, url: url))
        self.size = size
        self.start = start
        self.end = end
        self.isMuted = isMuted
        self.suppressLoop = suppressLoop
        self.isShowControl = isShowControl
        self.autoHeight = autoHeight
        self._isPlaying = isPlaying
        UISlider.appearance().setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        UISlider.appearance().minimumTrackTintColor = .systemBlue
    }

    var body: some View {
        ZStack {
            if let asset = resolver.displayAVAsset {
                AVPlayerView(player: player)
                    .applySize(size: size, autoHeight: autoHeight)
                    .onAppear {
                        start(asset: asset)
                    }
                    .onDisappear {
                        cleanUp()
                    }
            } else {
                ProgressView()
                    .applySize(size: size)
            }
            if isShowControl && player.timeControlStatus == .paused {
                Button {
                    player.play()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(.label))
                        .background(Circle().fill(.regularMaterial).frame(width: 50, height: 50))
                }
            }
            if isShowControl {
                VStack {
                    Spacer()
                    if let duration = self.duration {
                        HStack {
                            Spacer16()
                            Text("\(currentTime.formatSecondsToTimeString()) / \(duration.formatSecondsToTimeString())")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Slider(value: $currentTime, in: 0 ... duration, onEditingChanged: { isEditing in
                            if !isEditing {
                                let seekTime = CMTime(seconds: currentTime, preferredTimescale: 600)
                                player.seek(to: seekTime)
                                player.play()
                            } else {
                                player.pause()
                            }
                        })
                        .tint(Color(.white))
                        .padding(.horizontal, 16)
                    }

                    Spacer40()
                }
            }
        }
        .onChange(of: isMuted) { newValue in
            player.isMuted = newValue
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                player.play()
            } else {
                player.pause()
            }
        }
    }

    private func start(asset: AVAsset) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        Task {
            do {
                let _duration = try await asset.load(.duration)
                DispatchQueue.main.async {
                    self.duration = _duration.seconds
                }
            } catch {}

            player.replaceCurrentItem(with: AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: nil))
            await player.seek(to: CMTime(seconds: start, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            player.isMuted = isMuted

            if isPlaying {
                player.play()
            } else {
                player.pause()
            }
        }

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            MainActor.assumeIsolated {
                if let end = end, time.seconds >= end {
                    let seekTime = CMTime(seconds: self.start, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    self.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                        MainActor.assumeIsolated {
                            if !self.suppressLoop {
                                self.player.play()
                            }
                        }
                    }
                }

                currentTime = time.seconds
            }
        }

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            let seekTime = CMTime(seconds: self.start, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            MainActor.assumeIsolated {
                self.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                    MainActor.assumeIsolated {
                        if !self.suppressLoop {
                            self.player.play()
                        }
                    }
                }
            }
        }
    }

    private func cleanUp() {
        player.pause()

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
}

class PlayerUIView: UIView {
    var playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        layer.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspect
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct AVPlayerView: UIViewRepresentable {
    var player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

@MainActor
class VideoResolver: ObservableObject {
    private let asset: LocalAsset?
    private let url: URL?

    @Published var displayAVAsset: AVAsset?

    init(asset: LocalAsset?, url: URL?) {
        self.asset = asset
        self.url = url

        Task {
            if asset != nil {
                let fromCache = await localVideoFromCache()
                if !fromCache {
                    localVideoFromLocalDevice()
                }
            }

            if url != nil {
                let fromCache = await remoteVideoFromCache()
                if !fromCache {
                    remoteVideoFromRemoteUrl()
                }
            }
        }
    }

    func localVideoFromCache() async -> Bool {
        guard let asset = asset else {
            return false
        }

        guard let cacheAVAsset = await CachedVideoStore.shared.get(key: asset.id) else { return false }
        displayAVAsset = cacheAVAsset
        return true
    }

    func localVideoFromLocalDevice() {
        guard let asset = asset else {
            return
        }

        Task {
            do {
                let avAsset = try await PhotosClient.liveValue.requestFullVideo(asset: asset)
                await CachedVideoStore.shared.set(key: asset.id, video: avAsset)
                self.displayAVAsset = avAsset
            } catch {}
        }
    }

    func remoteVideoFromCache() async -> Bool {
        guard let url = url else {
            return false
        }

        guard let cacheAVAsset = await CachedVideoStore.shared.get(key: url.withoutQuery.absoluteString) else { return false }
        displayAVAsset = cacheAVAsset
        return true
    }

    func remoteVideoFromRemoteUrl() {
        guard let url = url else {
            return
        }

        let avAsset = AVURLAsset(url: url)
        Task {
            do {
                let isPlayable = try await avAsset.load(.isPlayable)
                guard isPlayable else {
                    return
                }

                await CachedVideoStore.shared.set(key: url.withoutQuery.absoluteString, video: avAsset)
                self.displayAVAsset = avAsset
            } catch {}
        }
    }
}
