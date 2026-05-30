import AVFoundation
import MediaPlayer
import Observation
import UIKit

enum RepeatMode: String, CaseIterable {
    case off, all, one

    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    var label: String {
        switch self {
        case .off: return "关闭"
        case .all: return "列表循环"
        case .one: return "单曲循环"
        }
    }
}

@Observable
final class AudioPlayerManager {
    private(set) var currentTrack: Track?
    private(set) var queue: [Track] = []
    private(set) var queueIndex: Int = 0
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    var isShuffled = false
    var repeatMode: RepeatMode = .off
    var showNowPlaying = false
    var playbackRate: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(playbackRate, forKey: "playbackRate")
            if isPlaying { player?.rate = playbackRate }
        }
    }
    var sleepTimerMinutes: Int?
    private(set) var sleepTimerRemaining: TimeInterval?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var sleepEndTask: DispatchWorkItem?
    private var sleepTickTimer: Timer?

    init() {
        playbackRate = UserDefaults.standard.object(forKey: "playbackRate") as? Float ?? 1.0
        configureAudioSession()
        setupRemoteCommands()
    }

    deinit {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        sleepTickTimer?.invalidate()
        sleepEndTask?.cancel()
    }

    var hasQueue: Bool { !queue.isEmpty }

    func play(tracks: [Track], startingAt index: Int = 0) {
        guard !tracks.isEmpty, index < tracks.count else { return }
        queue = tracks
        queueIndex = index
        loadAndPlay(tracks[index])
    }

    func playAlbum(_ album: AlbumGroup, from track: Track? = nil) {
        let idx = track.flatMap { t in album.tracks.firstIndex(where: { $0.id == t.id }) } ?? 0
        play(tracks: album.tracks, startingAt: idx)
    }

    func togglePlayPause() {
        guard let player else { return }
        Haptics.tap()
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.playImmediately(atRate: playbackRate)
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    func setSleepTimer(minutes: Int?) {
        sleepEndTask?.cancel()
        sleepTickTimer?.invalidate()
        sleepEndTask = nil
        sleepTickTimer = nil
        sleepTimerMinutes = minutes
        sleepTimerRemaining = nil

        guard let minutes, minutes > 0 else { return }

        sleepTimerRemaining = TimeInterval(minutes * 60)
        sleepTickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, var remaining = sleepTimerRemaining else { return }
            remaining -= 1
            if remaining <= 0 {
                fireSleepTimer()
            } else {
                sleepTimerRemaining = remaining
            }
        }

        let work = DispatchWorkItem { [weak self] in self?.fireSleepTimer() }
        sleepEndTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(minutes * 60), execute: work)
    }

    private func fireSleepTimer() {
        Haptics.impact()
        setSleepTimer(minutes: nil)
        player?.pause()
        isPlaying = false
        showNowPlaying = false
        updateNowPlayingInfo()
    }

    func skipForward() {
        guard !queue.isEmpty else { return }
        Haptics.tap()
        if queueIndex + 1 < queue.count {
            queueIndex += 1
            loadAndPlay(queue[queueIndex])
        } else if repeatMode == .all {
            queueIndex = 0
            loadAndPlay(queue[0])
        }
    }

    func skipBackward() {
        guard let player, !queue.isEmpty else { return }
        Haptics.tap()
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if queueIndex > 0 {
            queueIndex -= 1
            loadAndPlay(queue[queueIndex])
        } else if repeatMode == .all {
            queueIndex = queue.count - 1
            loadAndPlay(queue[queueIndex])
        } else {
            seek(to: 0)
            player.playImmediately(atRate: playbackRate)
            isPlaying = true
        }
    }

    func seek(to time: TimeInterval) {
        let cm = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateNowPlayingInfo()
    }

    func cycleRepeatMode() {
        Haptics.select()
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    func toggleShuffle() {
        Haptics.select()
        isShuffled.toggle()
        guard isShuffled, let current = currentTrack else { return }
        var rest = queue.filter { $0.id != current.id }.shuffled()
        queue = [current] + rest
        queueIndex = 0
    }

    func moveQueue(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        if let current = currentTrack, let idx = queue.firstIndex(where: { $0.id == current.id }) {
            queueIndex = idx
        }
    }

    func removeFromQueue(at offsets: IndexSet) {
        let removingCurrent = offsets.contains(queueIndex)
        queue.remove(atOffsets: offsets)
        if queue.isEmpty {
            stop()
            return
        }
        if removingCurrent {
            queueIndex = min(queueIndex, queue.count - 1)
            loadAndPlay(queue[queueIndex])
        } else if let current = currentTrack, let idx = queue.firstIndex(where: { $0.id == current.id }) {
            queueIndex = idx
        }
    }

    private func loadAndPlay(_ track: Track) {
        teardownPlayer()
        currentTrack = track
        let item = AVPlayerItem(url: track.fileURL)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.automaticallyWaitsToMinimizeStalling = true
        player = avPlayer
        duration = track.duration

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            currentTime = CMTimeGetSeconds(time)
            if let d = player?.currentItem?.duration, d.isNumeric {
                let secs = CMTimeGetSeconds(d)
                if secs.isFinite, secs > 0 { duration = secs }
            }
            updateNowPlayingInfo()
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handleTrackEnded()
        }

        player?.playImmediately(atRate: playbackRate)
        isPlaying = true
        updateNowPlayingInfo()
        updateArtworkOnLockScreen(track)
    }

    private func handleTrackEnded() {
        if repeatMode == .one, let track = currentTrack {
            seek(to: 0)
            player?.playImmediately(atRate: playbackRate)
            isPlaying = true
            return
        }
        if queueIndex + 1 < queue.count {
            queueIndex += 1
            loadAndPlay(queue[queueIndex])
        } else if repeatMode == .all, !queue.isEmpty {
            queueIndex = 0
            loadAndPlay(queue[0])
        } else {
            isPlaying = false
            currentTime = duration
        }
    }

    private func stop() {
        teardownPlayer()
        currentTrack = nil
        queue = []
        queueIndex = 0
        isPlaying = false
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func teardownPlayer() {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        self.timeObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        self.endObserver = nil
        player?.pause()
        player = nil
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: e.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.displayArtist,
            MPMediaItemPropertyAlbumTitle: track.displayAlbum,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackRate) : 0.0
        ]
        if let image = track.artworkImage {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateArtworkOnLockScreen(_ track: Track) {
        updateNowPlayingInfo()
    }
}
