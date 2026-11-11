import SwiftUI

// An infinity curve (lemniscate of Bernoulli) with a dot (note head) in its right loop.
struct Infinity: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        for i in 0...200 {
            let t = Double(i) / 200 * 2 * .pi
            let d = 1 + sin(t) * sin(t)
            let pt = CGPoint(x: r.midX + r.width / 2 * cos(t) / d, y: r.midY + r.width / 2 * sin(t) * cos(t) / d * 1.4)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

struct Logo: View {
    var size: CGFloat
    var body: some View {
        let w = size * 0.06
        ZStack {
            Infinity().stroke(style: StrokeStyle(lineWidth: w, lineJoin: .round))
            // One filled dot in the right loop: a note head, a held drone.
            Circle().frame(width: size * 0.16).offset(x: size * 0.3)
        }
        .frame(width: size, height: size / 2)
    }
}
