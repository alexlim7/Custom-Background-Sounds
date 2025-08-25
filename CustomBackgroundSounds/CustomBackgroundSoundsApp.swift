import SwiftUI

@main
struct CustomBackgroundSoundsApp: App {
    @StateObject private var audio = AudioManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    audio.configureAudioSession()
                }
        }
    }
}
