# Custom Background Sounds

I really enjoyed Apple's Background Sounds Accessibility feature, but the sound options were limited and I wanted to use custom audio files. So, I built this app which copies the UI/UX from Apple but is modified to support importing and playing your own audio files.  

This app plays customizable background sounds to mask environmental noise, improve focus, or aid relaxation. Supports importing audio files, adjusting volume, and fine-tuning playback behavior when other media is active.

## Features

- Play looping background sounds to mask unwanted noise.
- Import your own audio files (MP3, WAV, M4A).
- Adjust main volume and media-relative volume.
- Toggle Use When Media Is Playing to automatically lower volume when other media plays.
- Play an in-app sample sound at media-relative volume without affecting main background sounds.
- Option to stop background sounds when the device is locked.
- Fully SwiftUI-based interface with clean dark-themed GroupBoxes.

## Screenshots

<div style="display: flex; gap: 20px; align-items: flex-start;">
  <div style="text-align: center;">
    <p>Apple Settings:</p>
    <img src="https://github.com/user-attachments/assets/45f8785c-06d0-4a2e-a6c8-a57e460cd8f9" alt="IMG_4034" width="200"/>
  </div>
  <div style="text-align: center;">
    <p>This App:</p>
    <img src="https://github.com/user-attachments/assets/ba66a2c7-0698-43c2-ad53-96fb410ecaa3" alt="IMG_4035" width="200"/>
  </div>
</div>

## Requirements

- iOS 17+  
- Swift 5.9+  
- Xcode 15+  

## Installation

1. Clone the repository:
```bash
git clone https://github.com/alexlim7/Custom-Background-Sounds.git
```
2. Open CustomBackgroundSounds.xcodeproj in Xcode.
3. Build and run on your simulator or device.

## Notes

- Sample.mp3 is included for in-app testing.
- App icon sourced from shmector.com
