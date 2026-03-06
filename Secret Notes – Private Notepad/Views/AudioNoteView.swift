import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    @Binding var audioFilePath: String?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            if let path = audioFilePath {
                AudioPlayerView(filePath: path)
            }

            HStack(spacing: 20) {
                if isRecording {
                    Text(formatTime(recordingTime))
                        .font(.system(.title2, design: .monospaced))
                        .foregroundStyle(.red)

                    Button {
                        stopRecording()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.red)
                    }
                } else {
                    Button {
                        startRecording()
                    } label: {
                        VStack {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.red)
                            Text(audioFilePath == nil ? "Record" : "Re-record")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let url = documentsPath.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingTime = audioRecorder?.currentTime ?? 0
            }
        } catch {
            return
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        audioFilePath = audioRecorder?.url.path
        audioRecorder = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

struct AudioPlayerView: View {
    let filePath: String
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 8) {
            if duration > 0 {
                ProgressView(value: currentTime, total: duration)
                    .tint(.blue)

                HStack {
                    Text(formatTime(currentTime))
                    Spacer()
                    Text(formatTime(duration))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                Button {
                    seekBackward()
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                }

                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                }

                Button {
                    seekForward()
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                }
            }
        }
        .onAppear { loadAudio() }
        .onDisappear { stopPlayback() }
    }

    private func loadAudio() {
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
        } catch {}
    }

    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            timer?.invalidate()
        } else {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {}
            audioPlayer?.play()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                currentTime = audioPlayer?.currentTime ?? 0
                if !(audioPlayer?.isPlaying ?? false) {
                    isPlaying = false
                    timer?.invalidate()
                }
            }
        }
        isPlaying.toggle()
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        timer?.invalidate()
        isPlaying = false
    }

    private func seekBackward() {
        audioPlayer?.currentTime = max(0, (audioPlayer?.currentTime ?? 0) - 10)
        currentTime = audioPlayer?.currentTime ?? 0
    }

    private func seekForward() {
        let newTime = (audioPlayer?.currentTime ?? 0) + 10
        audioPlayer?.currentTime = min(newTime, duration)
        currentTime = audioPlayer?.currentTime ?? 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
