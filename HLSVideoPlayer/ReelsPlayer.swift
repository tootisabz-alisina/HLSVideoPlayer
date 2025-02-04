//
//  ReelsPlayer.swift
//  HLSVideoPlayer
//
//  Created by Alisina Haidari on 31.01.2025.
//

import SwiftUI
import AVKit

// MARK: - Video Model
struct Video: Identifiable {
    let id = UUID()
    let url: URL
    let userProfileImage: String // Placeholder for profile image
    let username: String
    let caption: String
    let likes: Int
    let comments: Int
    let views: Int
    let timestamp: String // Example: "6:28"
}

// MARK: - Video Player View
struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false // Hide controls for a cleaner look
        playerViewController.requiresLinearPlayback = true // Disable visual search and other non-linear features
        
        // Disable user interaction for the entire view
        playerViewController.view.isUserInteractionEnabled = false
        
        return playerViewController
    }


    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Video Player Manager
class VideoPlayerManager: ObservableObject {
    @Published var players: [AVPlayer?]
    private var preloadCount = 1 // Number of videos to preload ahead
    private var videos: [Video]

    init(videos: [Video]) {
        self.videos = videos
        self.players = Array(repeating: nil, count: videos.count)
    }

    func loadPlayer(for index: Int) {
        guard players[index] == nil else { return }

        print("Initializing player for video \(index)")
        let player = AVPlayer(url: videos[index].url)
        players[index] = player
        player.pause() // Preload but don't play

        // Add observer for auto-replay
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            print("Video \(index) ended, restarting...")
            player.seek(to: .zero) // Restart the video
            player.play() // Replay the video
        }
    }

    func preloadNextVideos(from index: Int) {
        let startIndex = index + 1
        let endIndex = min(index + preloadCount, videos.count - 1)

        // Ensure startIndex is within bounds and startIndex <= endIndex
        guard startIndex < videos.count, startIndex <= endIndex else {
            print("No more videos to preload")
            return
        }

        for i in startIndex...endIndex {
            if players[i] == nil {
                print("Preloading video \(i)")
                loadPlayer(for: i)
            }
        }
    }

    func pausePlayer(at index: Int) {
        print("Pausing video \(index)")
        players[index]?.pause()
    }

    func playPlayer(at index: Int) {
        print("Playing video \(index)")
        players[index]?.play()
    }

    func seekPlayer(at index: Int, to time: CMTime) {
        print("Seeking video \(index) to \(time.seconds)")
        players[index]?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func resetPlayer(at index: Int) {
        print("Resetting video \(index)")
        players[index]?.seek(to: .zero)
    }

    deinit {
        // Clean up observers
        for player in players {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        }
    }
}

// MARK: - Video Reel View
struct VideoReelView: View {
    let videos: [Video]
    @StateObject private var playerManager: VideoPlayerManager
    @State private var currentIndex: Int = 0
    @State private var showFullCaption: Bool = false
    @State private var isPaused: Bool = false
    @State private var progress: Double = 0.0
    @State private var isLoading: Bool = false
    @State private var showPauseIcon: Bool = false
    @State private var isSeeking: Bool = false
    @State private var seekProgress: Double = 0.0
    @State private var loadingAnimation: Bool = false

    init(videos: [Video]) {
        self.videos = videos
        self._playerManager = StateObject(wrappedValue: VideoPlayerManager(videos: videos))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                            GeometryReader { itemGeometry in
                                let isVisible = abs(itemGeometry.frame(in: .global).minY) < geometry.size.height / 2

                                ZStack {
                                    if let player = playerManager.players[index] {
                                        VideoPlayerView(player: player)
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .id(index)
                                            .onChange(of: isVisible) { _, newIsVisible in
                                                handleVisibilityChange(newIsVisible, index: index)
                                            }
                                            .onAppear {
                                                // Observe progress for the current video
                                                let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                                                player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                                                    if let duration = player.currentItem?.duration.seconds, duration > 0 {
                                                        progress = time.seconds / duration
                                                    }
                                                }
                                            }
                                            .overlay(
                                                // Progress Bar
                                                VStack {
                                                    Spacer()
                                                    ZStack(alignment: .leading) {
                                                        Rectangle()
                                                            .frame(height: 3)
                                                            .foregroundColor(isLoading ? (loadingAnimation ? .gray.opacity(0.7) : .gray.opacity(0.2)) : .gray.opacity(0.5))
                                                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: loadingAnimation)
                                                        Rectangle()
                                                            .frame(width: geometry.size.width * CGFloat(isSeeking ? seekProgress : progress), height: 3)
                                                            .foregroundColor(.white)
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.bottom, 60)
                                                    .gesture(
                                                        // Seek Gesture
                                                        DragGesture(minimumDistance: 0)
                                                            .onChanged { value in
                                                                isSeeking = true
                                                                let seekLocation = value.location.x / geometry.size.width
                                                                seekProgress = max(0, min(seekLocation, 1))
                                                                if let duration = player.currentItem?.duration.seconds {
                                                                    let seekTime = CMTime(seconds: duration * seekProgress, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                                                                    playerManager.seekPlayer(at: index, to: seekTime)
                                                                }
                                                            }
                                                            .onEnded { _ in
                                                                isSeeking = false
                                                            }
                                                    )
                                                }
                                            )
                                            .overlay(
                                                // Pause Icon with Animation
                                                Group {
                                                    if showPauseIcon {
                                                        Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                                                            .font(.system(size: 60))
                                                            .foregroundColor(.white.opacity(0.8))
                                                            .transition(.scale.combined(with: .opacity))
                                                    }
                                                }
                                                .animation(.easeInOut(duration: 0.2), value: showPauseIcon)
                                            )
                                            .onTapGesture { location in
                                                // Calculate the tap location relative to the screen height
                                                let screenHeight = geometry.size.height
                                                let tapY = location.y

                                                // Only trigger play/pause if the tap is in the top 80% of the screen
                                                if tapY < screenHeight * 0.8 {
                                                    isPaused.toggle()
                                                    if isPaused {
                                                        playerManager.pausePlayer(at: index)
                                                    } else {
                                                        playerManager.playPlayer(at: index)
                                                    }
                                                    // Show pause icon with animation
                                                    showPauseIcon = true
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        showPauseIcon = false
                                                    }
                                                }
                                            }
                                    } else {
                                        Color.black // Placeholder while loading
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .onAppear {
                                                print("Loading video \(index)")
                                                isLoading = true
                                                loadingAnimation = true
                                                playerManager.loadPlayer(for: index)
                                                if index == 0 {
                                                    print("Force playing video \(index)")
                                                    playerManager.playPlayer(at: index)
                                                    playerManager.preloadNextVideos(from: index)
                                                }
                                                isLoading = false
                                                loadingAnimation = false
                                            }
                                    }

                                    // Overlay UI for likes, comments, views, profile, etc.
                                    VStack {
                                        Spacer()
                                            .onTapGesture { location in
                                                // Calculate the tap location relative to the screen height
                                                let screenHeight = geometry.size.height
                                                let tapY = location.y

                                                // Only trigger play/pause if the tap is in the top 80% of the screen
                                                if tapY < screenHeight * 0.8 {
                                                    isPaused.toggle()
                                                    if isPaused {
                                                        playerManager.pausePlayer(at: index)
                                                    } else {
                                                        playerManager.playPlayer(at: index)
                                                    }
                                                    // Show pause icon with animation
                                                    showPauseIcon = true
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        showPauseIcon = false
                                                    }
                                                }
                                            }

                                        
                                        // Like, Comment, View Section
                                        HStack {
                                            Spacer()
                                            VStack(alignment: .trailing ,spacing: 20) {
                                                Button(action: {
                                                    // Handle like action
                                                }) {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "heart.fill")
                                                            .font(.system(size: 24))
                                                            .foregroundColor(.white)
                                                        
                                                        Text("\(video.likes)")
                                                            .font(.system(size: 12, weight: .semibold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                
                                                Button(action: {
                                                    // Handle comment action
                                                }) {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "message.fill")
                                                            .font(.system(size: 24))
                                                            .foregroundColor(.white)
                                                        
                                                        Text("\(video.comments)")
                                                            .font(.system(size: 12, weight: .semibold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                
                                                Button(action: {
                                                    // Handle view action
                                                }) {
                                                    VStack(spacing: 4) {
                                                        Image(systemName: "eye.fill")
                                                            .font(.system(size: 24))
                                                            .foregroundColor(.white)
                                                        
                                                        Text("\(video.views)")
                                                            .font(.system(size: 12, weight: .semibold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                            }
                                            .padding(.trailing,16)
                                        }

                                        VStack {
                                            
                                            HStack {
                                                Image(video.userProfileImage) // Replace with your image asset
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())
                                                
                                                Circle()
                                                    .frame(width: 40, height: 40, alignment: .center)

                                            
                                            // User Profile, Username, Timestamp, and Caption
                                            VStack(alignment: .leading, spacing: 8) {

                                                    Text(video.username)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.white)

                                    //                                                    Spacer()

                                                    Text(video.timestamp)
                                                        .font(.system(size: 12, weight: .regular))
                                                        .foregroundColor(.white)
                                                }
                                                Spacer()
                                            }.padding(.leading,16)
                                            
                                            Text(video.caption)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.white)
                                                .lineLimit(showFullCaption ? nil : 2)
                                                .onTapGesture {
                                                    showFullCaption.toggle()
                                                }
                                                .padding(.leading,16)

                                            
                                        }
                                        .padding(.bottom, 70)
                                    }
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            UIScrollView.appearance().isPagingEnabled = true
        }
    }

    private func handleVisibilityChange(_ isVisible: Bool, index: Int) {
        if isVisible {
            print("Video \(index) is now visible")
            if currentIndex != index {
                playerManager.pausePlayer(at: currentIndex)
                playerManager.resetPlayer(at: currentIndex) // Reset previous video
                playerManager.playPlayer(at: index)
                currentIndex = index
            }
            playerManager.preloadNextVideos(from: index)
        }
    }
}
// MARK: - ContentView
struct ReelsPlayer: View {
    let videos = [
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/4269/posts/4710/stream_videos/post_media_e0c128ce-ad99-4621-8b85-20a116a02e05.m3u8")!,
            userProfileImage: "profile1", // Replace with your image asset
            username: "user1",
            caption: "This is a sample caption for the first video. Tap to show more or less.",
            likes: 123,
            comments: 45,
            views: 678,
            timestamp: "6:28"
        ),
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/4282/posts/4708/stream_videos/post_media_4c55abba-ec32-4da4-b2aa-097ff4bf5af3.m3u8")!,
            userProfileImage: "profile2", // Replace with your image asset
            username: "user2",
            caption: "Another example caption for the second video.",
            likes: 456,
            comments: 78,
            views: 910,
            timestamp: "4:15"
        ),
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/4274/posts/4709/stream_videos/post_media_d83bf0bc-9d30-4f97-8f3a-e5130c6089de.m3u8")!,
            userProfileImage: "profile2", // Replace with your image asset
            username: "user2",
            caption: "Another example caption for the second video.",
            likes: 456,
            comments: 78,
            views: 910,
            timestamp: "4:15"
        ),
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4692/stream_videos/post_media_9d08dfda-1ff4-44da-874b-78a3d19a6303.m3u8")!,
            userProfileImage: "profile2", // Replace with your image asset
            username: "user2",
            caption: "Another example caption for the second video.",
            likes: 456,
            comments: 78,
            views: 910,
            timestamp: "4:15"
        ),
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/4050/posts/4700/stream_videos/post_media_d146690e-b09f-43ec-b266-694284c12f75.m3u8")!,
            userProfileImage: "profile2", // Replace with your image asset
            username: "user2",
            caption: "Another example caption for the second video.",
            likes: 456,
            comments: 78,
            views: 910,
            timestamp: "4:15"
        ),
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/4267/posts/4675/stream_videos/post_media_4e7b5e5a-0d6f-4df1-b73f-a52b5db0d96c.m3u8")!,
            userProfileImage: "profile2", // Replace with your image asset
            username: "user2",
            caption: "Another example caption for the second video.",
            likes: 456,
            comments: 78,
            views: 910,
            timestamp: "4:15"
        ),
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/3688/posts/4690/stream_videos/post_media_8a8568f5-a6b6-4525-aef0-64a4b3409f60.m3u8")!,
            userProfileImage: "profile2", // Replace with your image asset
            username: "user2",
            caption: "Another example caption for the second video.",
            likes: 456,
            comments: 78,
            views: 910,
            timestamp: "4:15"
        ),
        Video(
            url: URL(string: "https://tootisabz.com:4090/storage/uploads/1495/posts/4676/stream_videos/post_media_d0745a7c-33cd-491e-92f6-0fc373aee1a1.m3u8")!,
            userProfileImage: "profile2", // Replace with your image asset
            username: "user2",
            caption: "Another example caption for the second video.",
            likes: 456,
            comments: 78,
            views: 910,
            timestamp: "4:15"
        ),
    ]

    var body: some View {
        VideoReelView(videos: videos)
            .edgesIgnoringSafeArea(.all)
    }
}


