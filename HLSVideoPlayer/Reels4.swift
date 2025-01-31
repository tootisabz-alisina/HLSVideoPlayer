//import SwiftUI
//import AVKit
//
//// MARK: - Video Model
//struct Video: Identifiable {
//    let id = UUID()
//    let url: URL
//}
//
//// MARK: - Video Player View
//struct VideoPlayerView: UIViewControllerRepresentable {
//    let player: AVPlayer
//
//    func makeUIViewController(context: Context) -> AVPlayerViewController {
//        let playerViewController = AVPlayerViewController()
//        playerViewController.player = player
//        playerViewController.showsPlaybackControls = false // Hide controls for a cleaner look
//        playerViewController.requiresLinearPlayback = true // Disable visual search and other non-linear features
//        return playerViewController
//    }
//
//    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
//        // Update the player if needed
//    }
//}
//
//// MARK: - Video Player Manager
//class VideoPlayerManager: ObservableObject {
//    @Published var players: [AVPlayer?] = []
//    @Published var loadingPercentages: [Int: Double] = [:] // Track loading percentages for each video
//    private var observers: [NSObjectProtocol] = []
//    private var timeObservers: [Any] = []
//
//    init(videos: [Video]) {
//        self.players = Array(repeating: nil, count: videos.count)
//    }
//
//    func loadPlayer(for index: Int, with url: URL) {
//        if players[index] == nil {
//            print("Initializing player for video \(index)")
//            let player = AVPlayer(url: url)
//            players[index] = player
//            player.pause() // Preload but don't play
//
//            // Configure player to start playback earlier
//            player.automaticallyWaitsToMinimizeStalling = false // Start playback as soon as possible
//
//            if let currentItem = player.currentItem {
//                currentItem.preferredForwardBufferDuration = 1 // Buffer 1 second ahead
//            }
//
//            // Add observer for auto-replay
//            let observer = NotificationCenter.default.addObserver(
//                forName: .AVPlayerItemDidPlayToEndTime,
//                object: player.currentItem,
//                queue: .main
//            ) { [weak self] _ in
//                print("Video \(index) ended, restarting...")
//                self?.restartVideo(at: index)
//            }
//            observers.append(observer)
//
//            // Add observer to track loading progress
//            let timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] _ in
//                self?.updateLoadingPercentage(for: index)
//            }
//            timeObservers.append(timeObserver)
//        }
//    }
//
//    func updateLoadingPercentage(for index: Int) {
//        guard let player = players[index],
//              let currentItem = player.currentItem else { return }
//
//        let loadedTimeRanges = currentItem.loadedTimeRanges
//        guard let timeRange = loadedTimeRanges.first?.timeRangeValue else { return }
//
//        let startSeconds = CMTimeGetSeconds(timeRange.start)
//        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
//        let loadedSeconds = startSeconds + durationSeconds
//
//        if let totalDuration = currentItem.duration.seconds.isFinite ? currentItem.duration.seconds : nil {
//            let percentage = (loadedSeconds / totalDuration) * 100
//            loadingPercentages[index] = percentage
//            print("Video \(index) loaded: \(String(format: "%.2f", percentage))%")
//
//            // Start playback when 40% of the video is loaded
//            if percentage >= 40 && player.rate == 0 {
//                print("Starting playback for video \(index) at \(String(format: "%.2f", percentage))% loaded")
//                player.play()
//            }
//        }
//    }
//
//    func restartVideo(at index: Int) {
//        guard let player = players[index] else { return }
//        player.seek(to: .zero)
//        player.play()
//    }
//
//    func pauseVideo(at index: Int) {
//        print("Pausing video \(index)")
//        players[index]?.pause()
//    }
//
//    func playVideo(at index: Int) {
//        print("Playing video \(index)")
//        players[index]?.play()
//    }
//
//    func seekToBeginning(at index: Int) {
//        guard let player = players[index] else { return }
//        player.seek(to: .zero)
//    }
//
//    deinit {
//        // Remove all observers
//        observers.forEach { NotificationCenter.default.removeObserver($0) }
//        timeObservers.forEach { _ in players.compactMap { $0 }.forEach { $0.removeTimeObserver($0) } }
//    }
//}
//
//// MARK: - Video Reel View
//struct VideoReelView: View {
//    let videos: [Video]
//    @StateObject private var playerManager: VideoPlayerManager
//    @State private var currentIndex: Int = 0
//
//    init(videos: [Video]) {
//        self.videos = videos
//        self._playerManager = StateObject(wrappedValue: VideoPlayerManager(videos: videos))
//    }
//
//    var body: some View {
//        GeometryReader { geometry in
//            ScrollViewReader { proxy in
//                ScrollView(.vertical, showsIndicators: false) {
//                    LazyVStack(spacing: 0) {
//                        ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
//                            GeometryReader { itemGeometry in
//                                let isVisible = abs(itemGeometry.frame(in: .global).minY) < geometry.size.height / 2
//                                if let player = playerManager.players[index] {
//                                    VStack {
//                                        VideoPlayerView(player: player)
//                                            .frame(width: geometry.size.width, height: geometry.size.height)
//                                            .id(index)
//                                        if let percentage = playerManager.loadingPercentages[index] {
//                                            Text("Loaded: \(String(format: "%.2f", percentage))%")
//                                                .foregroundColor(.white)
//                                                .padding()
//                                                .background(Color.black.opacity(0.7))
//                                                .cornerRadius(8)
//                                        }
//                                    }
//                                    .onChange(of: isVisible) { _, newIsVisible in
//                                        print("Video \(index) visibility changed to \(newIsVisible)")
//                                        handleVisibilityChange(newIsVisible, at: index)
//                                    }
//                                } else {
//                                    Color.black // Placeholder while loading
//                                        .frame(width: geometry.size.width, height: geometry.size.height)
//                                        .onAppear {
//                                            print("Loading video \(index)")
//                                            playerManager.loadPlayer(for: index, with: video.url)
//                                            if index == 0 {
//                                                print("Playing first video \(index)")
//                                                playerManager.playVideo(at: index)
//                                                preloadNextVideos(from: index)
//                                            }
//                                        }
//                                }
//                            }
//                            .frame(width: geometry.size.width, height: geometry.size.height)
//                        }
//                    }
//                    .scrollTargetLayout()
//                }
//                .scrollTargetBehavior(.paging)
//            }
//        }
//        .edgesIgnoringSafeArea(.all)
//        .onAppear {
//            UIScrollView.appearance().isPagingEnabled = true // Enable paging behavior
//        }
//    }
//
//    private func handleVisibilityChange(_ isVisible: Bool, at index: Int) {
//        if isVisible {
//            if currentIndex != index {
//                playerManager.pauseVideo(at: currentIndex)
//                playerManager.seekToBeginning(at: index) // Restart the video from the beginning
//                playerManager.playVideo(at: index)
//                currentIndex = index
//            }
//            preloadNextVideos(from: index)
//        }
//    }
//
//    private func preloadNextVideos(from index: Int) {
//        let preloadCount = 1 // Number of videos to preload ahead
//        let endIndex = min(index + preloadCount, videos.count - 1)
//
//        // Ensure the range is valid
//        if index + 1 <= endIndex {
//            for i in (index + 1)...endIndex {
//                if playerManager.players[i] == nil {
//                    print("Preloading video \(i)")
//                    playerManager.loadPlayer(for: i, with: videos[i].url)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - ContentView
//struct Reels2: View {
//    let videos = [
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4269/posts/4710/stream_videos/post_media_e0c128ce-ad99-4621-8b85-20a116a02e05.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4282/posts/4708/stream_videos/post_media_4c55abba-ec32-4da4-b2aa-097ff4bf5af3.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4274/posts/4709/stream_videos/post_media_d83bf0bc-9d30-4f97-8f3a-e5130c6089de.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4692/stream_videos/post_media_9d08dfda-1ff4-44da-874b-78a3d19a6303.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4050/posts/4700/stream_videos/post_media_d146690e-b09f-43ec-b266-694284c12f75.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4267/posts/4675/stream_videos/post_media_4e7b5e5a-0d6f-4df1-b73f-a52b5db0d96c.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4690/stream_videos/post_media_8a8568f5-a6b6-4525-aef0-64a4b3409f60.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/1495/posts/4676/stream_videos/post_media_d0745a7c-33cd-491e-92f6-0fc373aee1a1.m3u8")!),
//    ]
//
//    var body: some View {
//        VideoReelView(videos: videos)
//            .edgesIgnoringSafeArea(.all)
//    }
//}
