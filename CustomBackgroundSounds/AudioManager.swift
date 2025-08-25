import SwiftUI
import AVFoundation
import AppIntents

final class AudioManager: NSObject, ObservableObject {
    
    // Singleton instance
    static let shared = AudioManager()
    
    // Published properties for UI binding
    @Published var isPlaying: Bool = false
    @Published var selectedFileName: String? = nil
    @Published var volume: Float = 0.6
    @Published var autostart: Bool = true
    @Published var useWhenMediaPlaying: Bool = true
    @Published var mediaVolume: Float = 0.2
    @Published var stopWhenLocked: Bool = false
    @Published var isSamplePlaying: Bool = false
    
    // Private audio properties
    private var player: AVAudioPlayer?
    private var samplePlayer: AVAudioPlayer?
    private let docsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    // Monitoring other media
    private var audioCheckTimer: Timer?
    private var lastOtherAudioState: Bool = false
    
    // UserDefaults keys
    private let lastFileKey = "lastAudioFileURL"
    private let volumeKey = "volume"
    private let autostartKey = "autostart"
    private let useMediaKey = "useWhenMediaPlaying"
    private let mediaVolumeKey = "mediaVolume"
    private let stopWhenLockedKey = "stopWhenLocked"
    
    // Initialization and notification setup
    override private init() {
        super.init()
        restoreSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppLock), name: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    // Audio session configuration
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
        }
        
        // Autostart last saved file if enabled
        if autostart, let url = lastSavedFileURL(), FileManager.default.fileExists(atPath: url.path) {
            prepareAndPlay(url: url)
        }
    }
    
    // Start timer to monitor external media
    private func startMonitoringOtherAudio() {
        audioCheckTimer?.invalidate()
        audioCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            let session = AVAudioSession.sharedInstance()
            let current = session.isOtherAudioPlaying
            if current != self.lastOtherAudioState {
                self.lastOtherAudioState = current
                self.updatePlayerVolume()
            }
        }
    }
    
    // Stop monitoring external media
    private func stopMonitoringOtherAudio() {
        audioCheckTimer?.invalidate()
        audioCheckTimer = nil
    }
    
    // Import audio file into app
    func importFile(from sourceURL: URL) {
        let isAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if isAccessing { sourceURL.stopAccessingSecurityScopedResource() } }
        
        let targetURL = docsURL.appendingPathComponent(sourceURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
            UserDefaults.standard.set(targetURL.path, forKey: lastFileKey)
            selectedFileName = targetURL.lastPathComponent
            prepareAndPlay(url: targetURL)
            print("File imported successfully: \(selectedFileName ?? "nil")")
        } catch {
            print("File import error: \(error)")
        }
    }
    
    // Prepare and start playing audio
    private func prepareAndPlay(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            updatePlayerVolume()
            player?.prepareToPlay()
            try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            isPlaying = player?.play() ?? false
            selectedFileName = url.lastPathComponent
            
            if isPlaying { startMonitoringOtherAudio() }
        } catch {
            print("AVAudioPlayer error: \(error)")
            isPlaying = false
        }
    }
    
    // Playback controls
    func play() {
        if player == nil, let url = lastSavedFileURL() { prepareAndPlay(url: url) }
        updatePlayerVolume()
        isPlaying = player?.play() ?? false
        if isPlaying { startMonitoringOtherAudio() }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopMonitoringOtherAudio()
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
        stopMonitoringOtherAudio()
    }
    
    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }
    
    // Volume controls
    func setVolume(_ v: Float) {
        volume = clamped(v)
        updatePlayerVolume()
        UserDefaults.standard.set(volume, forKey: volumeKey)
    }
    
    func setMediaVolume(_ v: Float) {
        mediaVolume = clamped(v)
        updatePlayerVolume()
        UserDefaults.standard.set(mediaVolume, forKey: mediaVolumeKey)
    }
    
    func toggleUseWhenMediaPlaying(_ on: Bool) {
        useWhenMediaPlaying = on
        UserDefaults.standard.set(useWhenMediaPlaying, forKey: useMediaKey)
        updatePlayerVolume()
    }
    
    func toggleStopWhenLocked(_ on: Bool) {
        stopWhenLocked = on
        UserDefaults.standard.set(stopWhenLocked, forKey: stopWhenLockedKey)
    }
    
    // Clamp function for volume values
    private func clamped(_ value: Float) -> Float {
        max(0, min(1, value))
    }
    
    // Update player volume based on media state
    private func updatePlayerVolume(forSample: Bool = false) {
        let session = AVAudioSession.sharedInstance()
        let otherMediaActive = session.isOtherAudioPlaying || isSamplePlaying
        
        if forSample {
            samplePlayer?.volume = volume
            if let p = player {
                if useWhenMediaPlaying {
                    p.volume = mediaVolume
                } else {
                    p.volume = 0.0 // temporarily silence background audio
                }
            }
            return
        }
        
        guard let p = player else { return }
        if otherMediaActive {
            if useWhenMediaPlaying {
                p.volume = mediaVolume
            } else {
                p.volume = 0.0 // temporarily silence background audio
            }
        } else {
            p.volume = volume
        }
    }
    
    // Sample playback
    func playSample() {
        guard let sampleURL = Bundle.main.url(forResource: "Sample", withExtension: "mp3") else {
            print("Sample.mp3 not found in bundle"); return
        }
        
        if samplePlayer == nil {
            do {
                samplePlayer = try AVAudioPlayer(contentsOf: sampleURL)
                samplePlayer?.numberOfLoops = -1
                samplePlayer?.prepareToPlay()
            } catch {
                print("Error playing sample: \(error)")
                return
            }
        }
        
        samplePlayer?.play()
        isSamplePlaying = true
        updatePlayerVolume(forSample: true)
    }
    
    func stopSample() {
        samplePlayer?.stop()
        isSamplePlaying = false
        updatePlayerVolume()
    }
    
    // Helper function to get last saved file
    private func lastSavedFileURL() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: lastFileKey) else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    // Restore saved settings from UserDefaults
    private func restoreSettings() {
        if let path = UserDefaults.standard.string(forKey: lastFileKey) {
            selectedFileName = URL(fileURLWithPath: path).lastPathComponent
        }
        if let savedVolume = UserDefaults.standard.object(forKey: volumeKey) as? Float {
            volume = savedVolume
        }
        if let savedAutostart = UserDefaults.standard.object(forKey: autostartKey) as? Bool {
            autostart = savedAutostart
        }
        if let savedUseMedia = UserDefaults.standard.object(forKey: useMediaKey) as? Bool {
            useWhenMediaPlaying = savedUseMedia
        }
        if let savedMediaVolume = UserDefaults.standard.object(forKey: mediaVolumeKey) as? Float {
            mediaVolume = savedMediaVolume
        }
        if let savedStopWhenLocked = UserDefaults.standard.object(forKey: stopWhenLockedKey) as? Bool {
            stopWhenLocked = savedStopWhenLocked
        }
    }
    
    // Handle audio interruptions
    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
        
        switch type {
        case .began: isPlaying = false
        case .ended:
            let optsVal = info[AVAudioSessionInterruptionOptionKey] as? UInt
            let shouldResume = optsVal.map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) } ?? false
            if shouldResume { player?.play(); isPlaying = true }
        @unknown default: break
        }
    }
    
    // Stop playback when device is locked if required
    @objc private func handleAppLock() {
        if stopWhenLocked {
            player?.stop()
            isPlaying = false
            stopMonitoringOtherAudio()
        }
    }
    
    // Stop sample when app goes to background
    @objc private func handleAppBackground() {
        if isSamplePlaying {
            stopSample()
        }
    }
}

// Siri Shortcut to toggle background noise
struct ToggleNoiseIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Background Noise"
    func perform() async throws -> some IntentResult {
        await MainActor.run { AudioManager.shared.togglePlayPause() }
        return .result()
    }
}
