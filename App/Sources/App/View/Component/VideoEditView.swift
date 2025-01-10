import AVKit
import SwiftUI

struct VideoEditView: View {
    private let videoSize: CGSize

    @StateObject var resolver: VideoResolver
    @State private var player = AVPlayer()
    @State private var timeObserverToken: Any?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying: Bool = true
    @Binding var start: Double
    @Binding var end: Double
    private var isMuted: Bool = false

    init(asset: LocalAsset,
         videoSize: CGSize,
         start: Binding<Double>,
         end: Binding<Double>,
         isMuted: Bool)
    {
        self._resolver = StateObject(wrappedValue: VideoResolver(asset: asset, url: nil))
        self.videoSize = videoSize
        self._start = start
        self._end = end
        self.isMuted = isMuted
    }

    init(url: URL?,
         videoSize: CGSize,
         start: Binding<Double>,
         end: Binding<Double>,
         isMuted: Bool)
    {
        self._resolver = StateObject(wrappedValue: VideoResolver(asset: nil, url: url))
        self.videoSize = videoSize
        self._start = start
        self._end = end
        self.isMuted = isMuted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let asset = resolver.displayAVAsset {
                    AVPlayerView(player: player)
                        .applySize(size: videoSize)
                        .onAppear {
                            start(video: AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: nil))
                        }
                        .onDisappear {
                            cleanUp()
                        }
                        .onTapGesture {
                            if player.timeControlStatus == .playing {
                                isPlaying = false
                            } else {
                                isPlaying = true
                            }
                        }
                } else {
                    ProgressView()
                        .applySize(size: videoSize)
                }
                if isMuted {
                    VStack {
                        Spacer12()
                        HStack {
                            Spacer16()
                            HStack {
                                Image("IconVolumeOff")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Color(UIColor.label))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Capsule().fill(.regularMaterial))
                            .foregroundColor(.white)
                            Spacer()
                        }

                        Spacer()
                    }
                }

                if !isPlaying {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "play.fill")
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }

            GeometryReader { geometry in
//                let widthRatio: CGFloat = 0.7
//                let aspectRatio: CGFloat = 49 / 270
//                let size = CGSize(
//                    width: geometry.size.width * widthRatio,
//                    height: geometry.size.width * widthRatio * aspectRatio)
                VStack {}
                    .frame(maxWidth: geometry.size.width)
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

    private func start(video: AVPlayerItem) {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        player.replaceCurrentItem(with: video)
        player.seek(to: start.cmTime)
        player.isMuted = isMuted

        if isPlaying {
            player.play()
        } else {
            player.pause()
        }

        Task {
            do {
                let _duration = try await player.currentItem?.asset.load(.duration)
                DispatchQueue.main.async {
                    self.duration = _duration?.seconds ?? 0.0
                }
            } catch {}
        }

        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            MainActor.assumeIsolated {
                if time.seconds >= end {
                    let seekTime = start.cmTime
                    self.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                        MainActor.assumeIsolated {
                            self.player.play()
                        }
                    }
                }
                currentTime = time.seconds
            }
        }

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            MainActor.assumeIsolated {
                let seekTime = start.cmTime
                self.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                    MainActor.assumeIsolated {
                        self.player.play()
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
