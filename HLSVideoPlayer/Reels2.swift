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
//        // No updates needed
//    }
//}
//
//// MARK: - Video Player Manager
//class VideoPlayerManager: ObservableObject {
//    @Published var players: [AVPlayer?]
//    private var preloadCount = 2 // Number of videos to preload ahead
//    private var videos: [Video]
//
//    init(videos: [Video]) {
//        self.videos = videos
//        self.players = Array(repeating: nil, count: videos.count)
//    }
//
//    func loadPlayer(for index: Int) {
//        guard players[index] == nil else { return }
//
//        print("Initializing player for video \(index)")
//        let player = AVPlayer(url: videos[index].url)
//        players[index] = player
//        player.pause() // Preload but don't play
//
//        // Add observer for auto-replay
//        NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: player.currentItem,
//            queue: .main
//        ) { _ in
//            print("Video \(index) ended, restarting...")
//            player.seek(to: .zero) // Restart the video
//            player.play() // Replay the video
//        }
//    }
//
//    func preloadNextVideos(from index: Int) {
//        let startIndex = index + 1
//        let endIndex = min(index + preloadCount, videos.count - 1)
//
//        // Ensure startIndex is within bounds and startIndex <= endIndex
//        guard startIndex < videos.count, startIndex <= endIndex else {
//            print("No more videos to preload")
//            return
//        }
//
//        for i in startIndex...endIndex {
//            if players[i] == nil {
//                print("Preloading video \(i)")
//                loadPlayer(for: i)
//            }
//        }
//    }
//
//    func pausePlayer(at index: Int) {
//        print("Pausing video \(index)")
//        players[index]?.pause()
//    }
//
//    func playPlayer(at index: Int) {
//        print("Playing video \(index)")
//        players[index]?.play()
//    }
//
//    deinit {
//        // Clean up observers
//        for player in players {
//            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
//        }
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
//
//                                if let player = playerManager.players[index] {
//                                    VideoPlayerView(player: player)
//                                        .frame(width: geometry.size.width, height: geometry.size.height)
//                                        .id(index)
//                                        .onChange(of: isVisible) { _, newIsVisible in
//                                            handleVisibilityChange(newIsVisible, index: index)
//                                        }
//                                } else {
//                                    Color.black // Placeholder while loading
//                                        .frame(width: geometry.size.width, height: geometry.size.height)
//                                        .onAppear {
//                                            print("Loading video \(index)")
//                                            playerManager.loadPlayer(for: index)
//                                            if index == 0 {
//                                                print("Force playing video \(index)")
//                                                playerManager.playPlayer(at: index)
//                                                playerManager.preloadNextVideos(from: index)
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
//            UIScrollView.appearance().isPagingEnabled = true
//        }
//    }
//
//    private func handleVisibilityChange(_ isVisible: Bool, index: Int) {
//        if isVisible {
//            print("Video \(index) is now visible")
//            if currentIndex != index {
//                playerManager.pausePlayer(at: currentIndex)
//                playerManager.playPlayer(at: index)
//                currentIndex = index
//            }
//            playerManager.preloadNextVideos(from: index)
//        }
//    }
//}
//
//// MARK: - ContentView
//struct Reels2: View {
//    let videos = [
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4267/posts/4675/stream_videos/post_media_4e7b5e5a-0d6f-4df1-b73f-a52b5db0d96c.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4690/stream_videos/post_media_8a8568f5-a6b6-4525-aef0-64a4b3409f60.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/1495/posts/4676/stream_videos/post_media_d0745a7c-33cd-491e-92f6-0fc373aee1a1.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4269/posts/4710/stream_videos/post_media_e0c128ce-ad99-4621-8b85-20a116a02e05.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4282/posts/4708/stream_videos/post_media_4c55abba-ec32-4da4-b2aa-097ff4bf5af3.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4274/posts/4709/stream_videos/post_media_d83bf0bc-9d30-4f97-8f3a-e5130c6089de.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4269/posts/4710/stream_videos/post_media_e0c128ce-ad99-4621-8b85-20a116a02e05.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4282/posts/4708/stream_videos/post_media_4c55abba-ec32-4da4-b2aa-097ff4bf5af3.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4274/posts/4709/stream_videos/post_media_d83bf0bc-9d30-4f97-8f3a-e5130c6089de.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4692/stream_videos/post_media_9d08dfda-1ff4-44da-874b-78a3d19a6303.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4050/posts/4700/stream_videos/post_media_d146690e-b09f-43ec-b266-694284c12f75.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4267/posts/4675/stream_videos/post_media_4e7b5e5a-0d6f-4df1-b73f-a52b5db0d96c.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4690/stream_videos/post_media_8a8568f5-a6b6-4525-aef0-64a4b3409f60.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4692/stream_videos/post_media_9d08dfda-1ff4-44da-874b-78a3d19a6303.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/4050/posts/4700/stream_videos/post_media_d146690e-b09f-43ec-b266-694284c12f75.m3u8")!),
//        Video(url: URL(string: "https://tootisabz.com:4090/storage/uploads/1495/posts/4676/stream_videos/post_media_d0745a7c-33cd-491e-92f6-0fc373aee1a1.m3u8")!),
//    ]
//
//    var body: some View {
//        VideoReelView(videos: videos)
//            .edgesIgnoringSafeArea(.all)
//    }
//}
//
///*
// BASE VERSION
// */
