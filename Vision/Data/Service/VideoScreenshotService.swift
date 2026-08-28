import Foundation
import AVFoundation
import UIKit
import CoreImage

enum VideoScreenshotError: LocalizedError {
    case invalidPercentage
    case invalidDuration
    case frameExtractionFailed(Error?)
    case imageConversionFailed
    case directoryCreationFailed(Error)
    case fileSaveFailed(Error)
    case timedOut
    
    var errorDescription: String? {
        switch self {
        case .invalidPercentage:
            return "The requested percentage is invalid. It must be between 0.0 and 1.0 (or 0 and 100)."
        case .invalidDuration:
            return "Unable to determine video duration."
        case .frameExtractionFailed(let error):
            return "Failed to extract frame from video: \(error?.localizedDescription ?? "unknown error")."
        case .imageConversionFailed:
            return "Failed to convert extracted frame to image data."
        case .directoryCreationFailed(let error):
            return "Failed to create target directory: \(error.localizedDescription)."
        case .fileSaveFailed(let error):
            return "Failed to save screenshot to disk: \(error.localizedDescription)."
        case .timedOut:
            return "Timed out waiting for video frame from stream."
        }
    }
}

protocol VideoScreenshotServiceProtocol: Sendable {
    func extractFrame(
        from videoURL: URL,
        atPercentage percentage: Double
    ) async throws -> UIImage

    func captureAndSaveScreenshot(
        from videoURL: URL,
        atPercentage percentage: Double,
        fileName: String?,
        saveDirectory: URL?
    ) async throws -> (image: UIImage, savedURL: URL)
}

extension VideoScreenshotServiceProtocol {
    func captureAndSaveScreenshot(
        from videoURL: URL,
        atPercentage percentage: Double
    ) async throws -> (image: UIImage, savedURL: URL) {
        try await captureAndSaveScreenshot(
            from: videoURL,
            atPercentage: percentage,
            fileName: nil,
            saveDirectory: nil
        )
    }
}

final class VideoScreenshotService: VideoScreenshotServiceProtocol, @unchecked Sendable {
    private let ciContext = CIContext(options: nil)

    init() {}
    
    func extractFrame(
        from videoURL: URL,
        atPercentage percentage: Double
    ) async throws -> UIImage {
        let normalizedPercentage = normalizePercentage(percentage)
        let isHLS = videoURL.pathExtension.lowercased() == "m3u8" || videoURL.absoluteString.contains(".m3u8")

        if isHLS {
            return try await extractFrameUsingVideoOutput(from: videoURL, atPercentage: normalizedPercentage)
        }

        do {
            return try await extractFrameUsingImageGenerator(from: videoURL, atPercentage: normalizedPercentage)
        } catch {
            // Fallback to AVPlayerItemVideoOutput if AVAssetImageGenerator fails
            return try await extractFrameUsingVideoOutput(from: videoURL, atPercentage: normalizedPercentage)
        }
    }
    
    func captureAndSaveScreenshot(
        from videoURL: URL,
        atPercentage percentage: Double,
        fileName: String? = nil,
        saveDirectory: URL? = nil
    ) async throws -> (image: UIImage, savedURL: URL) {
        let normalizedPercentage = normalizePercentage(percentage)
        let image = try await extractFrame(from: videoURL, atPercentage: normalizedPercentage)

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw VideoScreenshotError.imageConversionFailed
        }

        let targetDirectory = saveDirectory ?? defaultSaveDirectory()

        if !FileManager.default.fileExists(atPath: targetDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
            } catch {
                throw VideoScreenshotError.directoryCreationFailed(error)
            }
        }

        let percentInt = Int(round(normalizedPercentage * 100))
        let timestamp = Int(Date().timeIntervalSince1970)
        let name = fileName ?? "screenshot_\(timestamp)_\(percentInt)pct.jpg"
        let fileURL = targetDirectory.appendingPathComponent(name)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw VideoScreenshotError.fileSaveFailed(error)
        }

        return (image, fileURL)
    }

    // MARK: - Image Extraction Strategies

    private func extractFrameUsingImageGenerator(
        from videoURL: URL,
        atPercentage percentage: Double
    ) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)

        let duration: CMTime
        do {
            duration = try await asset.load(.duration)
        } catch {
            throw VideoScreenshotError.invalidDuration
        }

        let durationSeconds = duration.seconds
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            throw VideoScreenshotError.invalidDuration
        }

        let targetSeconds = durationSeconds * percentage
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .positiveInfinity
        generator.requestedTimeToleranceAfter = .positiveInfinity

        do {
            let (cgImage, _) = try await generator.image(at: targetTime)
            return UIImage(cgImage: cgImage)
        } catch {
            throw VideoScreenshotError.frameExtractionFailed(error)
        }
    }

    private func extractFrameUsingVideoOutput(
        from videoURL: URL,
        atPercentage percentage: Double
    ) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)

        let duration: CMTime
        do {
            duration = try await asset.load(.duration)
        } catch {
            throw VideoScreenshotError.invalidDuration
        }

        let durationSeconds = duration.seconds
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            throw VideoScreenshotError.invalidDuration
        }

        let targetSeconds = durationSeconds * percentage
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)

        let playerItem = AVPlayerItem(asset: asset)
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let videoOutput = AVPlayerItemVideoOutput(outputSettings: outputSettings)
        playerItem.add(videoOutput)

        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true

        defer {
            player.pause()
            playerItem.remove(videoOutput)
        }

        try await waitForPlayerItemReady(playerItem)
        await playerItem.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)

        // Poll for pixel buffer availability
        for _ in 0..<40 {
            if videoOutput.hasNewPixelBuffer(forItemTime: targetTime) {
                var displayTime = CMTime.zero
                if let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: targetTime, itemTimeForDisplay: &displayTime),
                   let cgImage = createCGImage(from: pixelBuffer) {
                    return UIImage(cgImage: cgImage)
                }
            }

            var displayTime = CMTime.zero
            if let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: playerItem.currentTime(), itemTimeForDisplay: &displayTime),
               let cgImage = createCGImage(from: pixelBuffer) {
                return UIImage(cgImage: cgImage)
            }

            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        throw VideoScreenshotError.timedOut
    }

    private func waitForPlayerItemReady(_ item: AVPlayerItem) async throws {
        if item.status == .readyToPlay { return }

        final class Box: @unchecked Sendable {
            var observation: NSKeyValueObservation?
        }
        let box = Box()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var hasResumed = false

            box.observation = item.observe(\.status, options: [.new, .initial]) { observedItem, _ in
                guard !hasResumed else { return }
                switch observedItem.status {
                case .readyToPlay:
                    hasResumed = true
                    box.observation = nil
                    continuation.resume()
                case .failed:
                    hasResumed = true
                    box.observation = nil
                    let err = observedItem.error ?? VideoScreenshotError.frameExtractionFailed(nil)
                    continuation.resume(throwing: err)
                default:
                    break
                }
            }
        }
    }

    private func createCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return ciContext.createCGImage(ciImage, from: ciImage.extent)
    }

    // MARK: - Helper Methods

    func normalizePercentage(_ percentage: Double) -> Double {
        var value = percentage
        if value > 1.0 {
            value /= 100.0
        }
        return min(max(value, 0.0), 1.0)
    }

    private func defaultSaveDirectory() -> URL {
        let sourceURL = URL(fileURLWithPath: #filePath)
        let resourcesURL = sourceURL
            .deletingLastPathComponent() // Data/Service
            .deletingLastPathComponent() // Data
            .deletingLastPathComponent() // Vision
            .appendingPathComponent("Resources")

        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: resourcesURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue,
           FileManager.default.isWritableFile(atPath: resourcesURL.path) {
            return resourcesURL
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fallbackURL = documentsURL.appendingPathComponent("Screenshots", isDirectory: true)
        return fallbackURL
    }
}

//        let screenshotService: VideoScreenshotServiceProtocol = container.videoScreenshotService
//        Task {
//            guard let videoURL = URL(string: "https://nl221.werkecdn.me/s/FHfOKQSldi5ZRDZfqUjb7frkFBQUFBQUFBQUFBUmRlR2hRZm9BRlV6Qk9SVk13VGxE.0FbfsdAG51zQaUeCn_tuz4TMxzFyV22r5Yz-Sg/HD_45/Ya.est.gnev.2016.DUB.BDRip.1080p_480.mp4") else { return }
//
//            do {
//                // Извлекаем кадр на 25% (или 0.25) длительности видео и сохраняем
//                let result = try await screenshotService.captureAndSaveScreenshot(
//                    from: videoURL,
//                    atPercentage: 0.25 // 25% длительности
//                )
//
//                print("Скриншот успешно сохранен:")
//                print("URL файла: \(result.savedURL.path)")
//                print("Размер изображения: \(result.image.size)")
//            } catch {
//                print("Ошибка получения скриншота: \(error.localizedDescription)")
//            }
//        }