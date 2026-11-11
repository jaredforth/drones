// Usage: screenshot <out.png>. Renders the main view offscreen (C playing) for the README.
import SwiftUI
import AppKit

MainActor.assumeIsolated {
    let m = Model()
    m.toggle(0)
    let v = CircleView(model: m).frame(width: 700, height: 700).background(Color(white: 0.12)).environment(\.colorScheme, .dark)
    let r = ImageRenderer(content: v)
    r.scale = 2
    try! NSBitmapImageRep(cgImage: r.cgImage!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    exit(0)
}
