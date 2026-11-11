import SwiftUI
import AVFoundation

// Calibration knob: reference pitch for A4.
let A4 = 440.0
let keys = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]

// Semitone 0 = C. Octave 2 (C2 ≈ 65 Hz .. B2 ≈ 123 Hz).
func droneFreq(_ semitone: Int) -> Double { A4 * pow(2, Double(semitone - 9) / 12 - 2) }

// One oscillator per key (sine + 2 harmonics), all summable. Per-sample amplitude smoothing avoids clicks.
// Audio thread reads `target` racily; fine for Doubles on arm64/x86_64.
final class Drone {
    private let engine = AVAudioEngine()
    let target = UnsafeMutablePointer<Double>.allocate(capacity: 12)

    init() {
        target.initialize(repeating: 0, count: 12)
        var phase = [Double](repeating: 0, count: 12), amp = [Double](repeating: 0, count: 12)
        let freqs = (0..<12).map(droneFreq)
        let rate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let node = AVAudioSourceNode { [target] _, _, frames, abl in
            for buf in UnsafeMutableAudioBufferListPointer(abl) {
                let out = buf.mData!.assumingMemoryBound(to: Float.self)
                for i in 0..<Int(frames) {
                    var sum = 0.0
                    for k in 0..<12 {
                        amp[k] += (target[k] - amp[k]) * 0.0005
                        if amp[k] < 1e-5 && target[k] == 0 { continue }
                        phase[k] = (phase[k] + freqs[k] / rate).truncatingRemainder(dividingBy: 1)
                        let x = 2 * Double.pi * phase[k]
                        sum += amp[k] * (sin(x) + 0.5 * sin(2 * x) + 0.25 * sin(3 * x)) / 1.75
                    }
                    out[i] = Float(tanh(sum)) // soft clip when many keys play
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1))
        try? engine.start()
    }
}

final class Model: ObservableObject {
    @Published var active = Set<Int>()
    @Published var cursor = 0 // position on the circle (0 = C at top), not the key number
    private let drone = Drone()

    // Arrows move the cursor around the circle (left/up = counterclockwise); space/return toggles.
    init() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] e in
            switch e.keyCode {
            case 123, 126: cursor = (cursor + 11) % 12
            case 124, 125: cursor = (cursor + 1) % 12
            case 49, 36: toggle(cursor * 7 % 12)
            default: return e
            }
            return nil
        }
    }

    // Only one drone at a time: picking a key replaces the current one; picking it again stops it.
    func toggle(_ k: Int) {
        let was = active.contains(k)
        active = was ? [] : [k]
        for j in 0..<12 { drone.target[j] = active.contains(j) ? 0.3 : 0 }
    }
}

@main
struct DronesApp: App {
    // ObservableObject, not @State: the @State macro needs Xcode's plugin, absent with Command Line Tools only.
    @StateObject private var model = Model()

    var body: some Scene {
        WindowGroup {
            GeometryReader { g in
                let r = min(g.size.width, g.size.height) / 2 - 48
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 2 * r, height: 2 * r)
                    // Circle of fifths: clockwise from the top, each step up a fifth (7 semitones).
                    ForEach(0..<12, id: \.self) { i in
                        let k = i * 7 % 12
                        let on = model.active.contains(k)
                        let here = model.cursor == i
                        let a = Double(i) * .pi / 6 - .pi / 2
                        Button { model.cursor = i; model.toggle(k) } label: {
                            Text(keys[k]).font(.system(size: 22, weight: .medium))
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(on ? Color.orange : Color.gray.opacity(0.35)))
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: here ? 4 : 0))
                                .foregroundColor(on ? .black : .primary)
                        }
                        .buttonStyle(.plain)
                        .offset(x: r * cos(a), y: r * sin(a)) // not .position: that makes each button's frame fill the window
                    }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
            .frame(minWidth: 700, minHeight: 700)
        }
    }
}
