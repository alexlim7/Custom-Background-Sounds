import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var audio = AudioManager.shared
    @State private var showingPicker = false

    var body: some View {
        ZStack {
            // Background color
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Title
                    Text("Custom Background Sounds")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top, -10)

                    // Background sounds toggle box
                    GroupBox {
                        VStack(spacing: 6) {
                            // Toggle for enabling/disabling background sounds
                            Toggle(isOn: $audio.isPlaying) {
                                Text("Background Sounds")
                                    .foregroundColor(.white)
                            }
                            .tint(.blue)
                            .onChange(of: audio.isPlaying) { _, newValue in
                                newValue ? audio.play() : audio.pause()
                            }
                        }
                    }
                    .groupBoxStyle(DarkGroupBoxStyle())
                    
                    // Background sounds toggle box description
                    Text("Plays background sounds to mask unwanted environmental noise. These sounds can minimize distractions and help you to focus, calm, or rest.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .padding(.top, -20)
                        .lineSpacing(1)

                    // File selection box
                    GroupBox {
                        VStack(spacing: 8) {
                            // Display currently selected file
                            Text(audio.selectedFileName ?? "No file selected")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)

                            // Button to open file picker
                            Button(action: { showingPicker = true }) {
                                Label("Choose File", systemImage: "doc")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .groupBoxStyle(DarkGroupBoxStyle())
                    .padding(.top, -10)

                    // Volume selection box
                    GroupBox {
                        VStack(spacing: 6) {
                            // Volume label with current value
                            HStack {
                                Text("\(audio.selectedFileName ?? "File") Volume")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(audio.volume * 100))")
                                    .foregroundColor(.gray)
                            }

                            // Volume slider
                            HStack {
                                Image(systemName: "speaker.fill").foregroundColor(.white)
                                Slider(value: $audio.volume, in: 0...1)
                                    // Call AudioManager to update volume when slider changes
                                    .onChange(of: audio.volume) { oldValue, newValue in
                                        audio.setVolume(newValue)
                                    }
                                Image(systemName: "speaker.wave.3.fill").foregroundColor(.white)
                            }
                        }
                    }
                    .groupBoxStyle(DarkGroupBoxStyle())

                    // Use when media is playing box
                    GroupBox {
                        VStack(spacing: 10) {
                            // Use when media is playing toggle
                            Toggle(isOn: $audio.useWhenMediaPlaying) {
                                Text("Use When Media Is Playing")
                                    .foregroundColor(.white)
                            }
                            .tint(.blue)
                            .onChange(of: audio.useWhenMediaPlaying) { _, newValue in
                                audio.toggleUseWhenMediaPlaying(newValue)
                            }

                            Divider().background(Color.gray.opacity(0.5))

                            // Media-relative volume label
                            HStack {
                                Text("Volume with Media")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(audio.mediaVolume * 100))")
                                    .foregroundColor(.gray)
                            }

                            // Media-relative volume slider
                            HStack {
                                Image(systemName: "speaker.fill").foregroundColor(.white)
                                Slider(value: $audio.mediaVolume, in: 0...1)
                                    .onChange(of: audio.mediaVolume) { _, newValue in
                                        audio.setMediaVolume(newValue)
                                    }
                                Image(systemName: "speaker.wave.3.fill").foregroundColor(.white)
                            }

                            Divider().background(Color.gray.opacity(0.5))

                            // Play sample/stop button
                            // Toggles the in-app sample sound
                            Button(action: {
                                if audio.isSamplePlaying {
                                    audio.stopSample()
                                } else {
                                    audio.playSample()
                                }
                            }) {
                                Text(audio.isSamplePlaying ? "Stop" : "Play Sample")
                                    .foregroundColor(.blue)
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .groupBoxStyle(DarkGroupBoxStyle())

                    // Stop when locked box
                    GroupBox {
                        VStack(spacing: 6) {
                            // Toggle for stopping sounds when device is locked
                            Toggle(isOn: $audio.stopWhenLocked) {
                                Text("Stop Sounds When Locked")
                                    .foregroundColor(.white)
                            }
                            .tint(.blue)
                            .onChange(of: audio.stopWhenLocked) { _, newValue in
                                audio.toggleStopWhenLocked(newValue)
                            }
                        }
                    }
                    .groupBoxStyle(DarkGroupBoxStyle())
                    
                    // Stop when locked box description
                    Text("When enabled, background sounds will stop when iPhone is locked.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .padding(.top, -20)
                        .lineSpacing(1)

                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        // File importer for selecting audio files from device
        .fileImporter(
            isPresented: $showingPicker,
            allowedContentTypes: [UTType.audio, UTType.mp3, UTType.wav, UTType.mpeg4Audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let picked = urls.first {
                    audio.importFile(from: picked)
                }
            case .failure(let error):
                print("File import failed: \(error)")
            }
        }
    }
}

// Custom dark GroupBox style
// Applies a dark background and rounded corners for all GroupBoxes
struct DarkGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            configuration.content
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}
