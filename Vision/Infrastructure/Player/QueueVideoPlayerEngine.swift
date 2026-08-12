import Foundation
import AVFoundation

@MainActor
final class QueueVideoPlayerEngine {
    typealias URLProvider = (Int) async -> URL?

    let player = AVPlayer()

    nonisolated(unsafe) var onItemChanged: ((VideoQueueItem, Int) -> Void)?
    nonisolated(unsafe) var onPlaybackStateChanged: ((Bool) -> Void)?
    nonisolated(unsafe) var onTimeUpdate: ((Double, Double) -> Void)?
    nonisolated(unsafe) var onPlaybackFinished: (() -> Void)?
    nonisolated(unsafe) var onTracksAvailable: ((AVMediaSelectionGroup, [AVMediaSelectionOption], AVMediaSelectionGroup?, [AVMediaSelectionOption]) -> Void)?

    private(set) var queue: [VideoQueueItem] = []
    private(set) var currentIndex: Int = 0

    var urlProvider: URLProvider?

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    func configure(queue: [VideoQueueItem], startIndex: Int) {
        self.queue = queue
        self.currentIndex = max(0, min(startIndex, max(0, queue.count - 1)))
        bindPlayerObserversIfNeeded()

        if let item = self.queue[safe: self.currentIndex] {
            onItemChanged?(item, self.currentIndex)
        }
    }

    func playCurrent() async {
        await play(at: currentIndex)
    }

    func play(at index: Int) async {
        guard queue.indices.contains(index) else { return }
        guard let url = await urlProvider?(index) else { return }

        let item = AVPlayerItem(url: url)
        currentIndex = index
        player.replaceCurrentItem(with: item)
        player.play()

        if let queueItem = queue[safe: currentIndex] {
            onItemChanged?(queueItem, currentIndex)
        }
        onPlaybackStateChanged?(true)
        observeTracksAvailability()
    }

    func play(url: URL) {
        bindPlayerObserversIfNeeded()

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
        onPlaybackStateChanged?(true)
        observeTracksAvailability()
    }

    func prepare(url: URL) {
        bindPlayerObserversIfNeeded()

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.pause()
        onPlaybackStateChanged?(false)
        observeTracksAvailability()
    }

    func playNext() async {
        guard currentIndex + 1 < queue.count else { return }
        await play(at: currentIndex + 1)
    }

    func playPrevious() async {
        guard currentIndex - 1 >= 0 else { return }
        await play(at: currentIndex - 1)
    }

    func togglePlayPause() {
        if player.timeControlStatus == .playing {
            player.pause()
            onPlaybackStateChanged?(false)
        } else {
            player.play()
            onPlaybackStateChanged?(true)
        }
    }

    func seek(seconds: Double) {
        guard let currentItem = player.currentItem else { return }
        let duration = currentItem.duration.seconds
        let target: Double

        if duration.isFinite, duration > 0 {
            target = min(max(seconds, 0), duration)
        } else {
            target = max(seconds, 0)
        }

        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekBy(delta: Double) {
        let current = player.currentTime().seconds
        let base = current.isFinite ? current : 0
        seek(seconds: base + delta)
    }

    func selectAudioOption(_ option: AVMediaSelectionOption, in group: AVMediaSelectionGroup) {
        player.currentItem?.select(option, in: group)
    }

    func selectSubtitleOption(_ option: AVMediaSelectionOption?, in group: AVMediaSelectionGroup) {
        player.currentItem?.select(option, in: group)
    }

    // MARK: - Private

    private func observeTracksAvailability() {
        guard let item = player.currentItem else { return }

        Task {
            async let audioGroup = try? item.asset.loadMediaSelectionGroup(for: .audible)
            async let subtitleGroup = try? item.asset.loadMediaSelectionGroup(for: .legible)

            let (audio, subtitles) = await (audioGroup, subtitleGroup)

            guard let audio else { return }

            await MainActor.run {
                self.onTracksAvailable?(
                    audio, audio.options,
                    subtitles, subtitles?.options ?? []
                )
            }
        }
    }

    private func bindPlayerObserversIfNeeded() {
        if timeObserver == nil {
            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                queue: .main
            ) { [weak self] time in
                guard let self else { return }
                let current = time.seconds
                let duration = self.player.currentItem?.duration.seconds ?? 0
                self.onTimeUpdate?(current.isFinite ? current : 0, duration.isFinite ? duration : 0)
            }
        }

        if endObserver == nil {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.onPlaybackFinished?()
                Task { @MainActor in
                    await self.playNext()
                }
            }
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
