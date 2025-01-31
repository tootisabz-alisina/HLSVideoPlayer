//import SwiftUI
//import AVKit
//import Foundation
//
//// MARK: - ResourceLoaderDelegate
//class ResourceLoaderDelegate3: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate {
//    private var urlSession: URLSession!
//    private var pendingRequests = [AVAssetResourceLoadingRequest]()
//    private var cachedData: Data?
//    private var url: URL
//    private var cacheFileURL: URL?
//
//    init(url: URL) {
//        self.url = url
//        super.init()
//        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//        self.cacheFileURL = getCacheFileURL(for: url)
//        loadCachedDataFromDisk()
//    }
//
//    // MARK: - AVAssetResourceLoaderDelegate
//    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//        if let data = cachedData {
//            // Serve the cached data if available
//            loadingRequest.dataRequest?.respond(with: data)
//            loadingRequest.finishLoading()
//            return true
//        } else {
//            // Add the request to the pending list and start downloading
//            pendingRequests.append(loadingRequest)
//            if pendingRequests.count == 1 {
//                startDownload()
//            }
//            return true
//        }
//    }
//
//    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//        if let index = pendingRequests.firstIndex(of: loadingRequest) {
//            pendingRequests.remove(at: index)
//        }
//    }
//
//    // MARK: - Download Logic
//    private func startDownload() {
//        let task = urlSession.dataTask(with: url)
//        task.resume()
//    }
//
//    // MARK: - URLSessionDataDelegate
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//        if cachedData == nil {
//            cachedData = Data()
//        }
//        cachedData?.append(data)
//
//        // Respond to pending requests with the new data
//        for request in pendingRequests {
//            if let dataRequest = request.dataRequest {
//                dataRequest.respond(with: data)
//                request.finishLoading()
//            }
//        }
//        pendingRequests.removeAll()
//
//        // Save the downloaded data to disk
//        saveDataToDisk(data: data)
//    }
//
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        if let error = error {
//            print("Download failed: \(error.localizedDescription)")
//        }
//    }
//
//    // MARK: - Disk Caching
//    private func getCacheFileURL(for url: URL) -> URL {
//        let fileManager = FileManager.default
//        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
//        let fileName = url.lastPathComponent
//        return cacheDirectory.appendingPathComponent(fileName)
//    }
//
//    private func loadCachedDataFromDisk() {
//        if let cacheFileURL = cacheFileURL,
//           let data = try? Data(contentsOf: cacheFileURL) {
//            cachedData = data
//            print("Loaded cached data from disk: \(cacheFileURL)")
//        }
//    }
//
//    private func saveDataToDisk(data: Data) {
//        if let cacheFileURL = cacheFileURL {
//            do {
//                try data.write(to: cacheFileURL)
//                print("Data cached to disk at: \(cacheFileURL)")
//            } catch {
//                print("Failed to cache data to disk: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//// MARK: - VideoPlayerView with Offline Caching
//struct VideoPlayerView: UIViewControllerRepresentable {
//    let videoURL: URL
//
//    func makeUIViewController(context: Context) -> AVPlayerViewController {
//        let asset = AVURLAsset(url: videoURL)
//        let resourceLoaderDelegate = ResourceLoaderDelegate2(url: videoURL)
//        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.global(qos: .userInitiated))
//
//        let playerItem = AVPlayerItem(asset: asset)
//        let player = AVPlayer(playerItem: playerItem)
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
//// MARK: - ContentView
//struct HLS3: View {
//    let videoURL = URL(string: "https://tootisabz.com:4090/storage/uploads/4269/posts/4710/stream_videos/post_media_e0c128ce-ad99-4621-8b85-20a116a02e05.m3u8")!
//
//    var body: some View {
//        VideoPlayerView(videoURL: videoURL)
//            .edgesIgnoringSafeArea(.all)
//            .onAppear {
//                checkIfCachedVideoExists()
//            }
//    }
//
//    private func checkIfCachedVideoExists() {
//        let fileManager = FileManager.default
//        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
//        let fileName = videoURL.lastPathComponent
//        let cacheFileURL = cacheDirectory.appendingPathComponent(fileName)
//
//        if fileManager.fileExists(atPath: cacheFileURL.path) {
//            print("Cached video exists at: \(cacheFileURL)")
//        } else {
//            print("No cached video found.")
//        }
//    }
//}
