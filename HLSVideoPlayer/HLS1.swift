////
////  HLS1.swift
////  HLSVideoPlayer
////
////  Created by TOTI SABZ on 1/30/25.
////
//
//import SwiftUI
//import AVKit
//
//struct VideoPlayerView1: UIViewControllerRepresentable {
//    let videoURL: URL
//
//    func makeUIViewController(context: Context) -> AVPlayerViewController {
//        let player = AVPlayer(url: videoURL)
//        let playerViewController = AVPlayerViewController()
//        playerViewController.player = player
//        return playerViewController
//    }
//
//    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
//        // Update the player if needed
//    }
//}
//
//struct HLS1: View {
//    let videoURL = URL(string: "https://tootisabz.com:4090/storage/uploads/4269/posts/4710/stream_videos/post_media_e0c128ce-ad99-4621-8b85-20a116a02e05.m3u8")!
//
//    var body: some View {
//        VideoPlayerView(videoURL: videoURL)
//            .edgesIgnoringSafeArea(.all)
//    }
//}
//
