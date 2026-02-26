import Cocoa
import QuartzCore

class ConfettiWindow: NSWindow {
    override var canBecomeKey: Bool { return false }
    override var canBecomeMain: Bool { return false }
}

class ConfettiView: NSView {
    override var isFlipped: Bool { return false }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.backgroundColor = NSColor.clear.cgColor
        return layer
    }
}

func makeConfettiImage(width: CGFloat, height: CGFloat, color: NSColor) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: Int(width),
        height: Int(height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    ctx.setFillColor(color.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return ctx.makeImage()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: ConfettiWindow!
    var exitTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let screen = NSScreen.main!
        let frame = screen.frame

        window = ConfettiWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let contentView = ConfettiView(frame: NSRect(origin: .zero, size: frame.size))
        window.contentView = contentView

        guard let layer = contentView.layer else {
            NSApp.terminate(nil)
            return
        }

        // Calculate physics values so confetti peaks at ~75% of screen height.
        //
        // In this coordinate system (determined experimentally):
        //   emissionLongitude = π  → upward
        //   emissionLongitude = 0  → downward
        //   negative yAcceleration → pulls particles downward (gravity)
        //
        // Kinematics: peak height h = v² / (2 * |a|)
        // So: v = sqrt(2 * |a| * h)
        let targetHeight = frame.height * 0.75
        let gravity: CGFloat = 3200  // acceleration magnitude (pts/s²)
        let baseVelocity = sqrt(2.0 * gravity * targetHeight)  // ~1200 for a 1440p screen

        // Calculate birth rate so total particles ≈ screen width (1 particle per pixel)
        // Total cells = 8 colors × 2 shapes = 16
        // Total particles = birthRate × emissionDuration × numCells
        // birthRate = totalParticles / (emissionDuration × numCells)
        let emissionDuration: CGFloat = 1.5
        let numColors: CGFloat = 8
        let numShapes: CGFloat = 2
        let totalCells = numColors * numShapes
        let targetParticles = frame.width / 2  // 1 particle per 2 pixels of width
        let birthRatePerCell = Float(targetParticles / (emissionDuration * totalCells))

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: frame.width / 2, y: -20)  // Slightly below screen
        emitter.emitterSize = CGSize(width: frame.width, height: 1)
        emitter.emitterShape = .line
        emitter.renderMode = .oldestLast
        emitter.frame = CGRect(origin: .zero, size: frame.size)
        emitter.beginTime = CACurrentMediaTime()  // Start fresh, no pre-simulation

        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (1.0, 0.2, 0.3),   // Red
            (1.0, 0.6, 0.1),   // Orange
            (1.0, 0.9, 0.2),   // Yellow
            (0.2, 0.8, 0.4),   // Green
            (0.2, 0.6, 1.0),   // Blue
            (0.6, 0.3, 1.0),   // Purple
            (1.0, 0.4, 0.7),   // Pink
            (0.0, 0.9, 0.9),   // Cyan
        ]

        var cells: [CAEmitterCell] = []

        for (r, g, b) in colors {
            let color = NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)

            // Rectangle confetti
            if let image = makeConfettiImage(width: 12, height: 8, color: color) {
                let cell = CAEmitterCell()
                cell.birthRate = birthRatePerCell
                cell.lifetime = 5.0
                cell.lifetimeRange = 1.5
                cell.velocity = baseVelocity * 0.7   // Center the range
                cell.velocityRange = baseVelocity * 0.6  // Wide range: ~10% to ~75% screen height
                cell.emissionLongitude = CGFloat.pi  // Upward
                cell.emissionRange = CGFloat.pi / 8  // Tight cone
                cell.spin = 2.0
                cell.spinRange = 4.0
                cell.scale = 1.0
                cell.scaleRange = 0.5
                cell.color = CGColor.white
                cell.alphaSpeed = -0.2
                cell.yAcceleration = -gravity
                cell.contents = image
                cells.append(cell)
            }

            // Smaller square confetti
            if let image = makeConfettiImage(width: 8, height: 8, color: color) {
                let cell = CAEmitterCell()
                cell.birthRate = birthRatePerCell
                cell.lifetime = 5.0
                cell.lifetimeRange = 1.5
                cell.velocity = baseVelocity * 0.6
                cell.velocityRange = baseVelocity * 0.55  // Wide range for variety
                cell.emissionLongitude = CGFloat.pi  // Upward
                cell.emissionRange = CGFloat.pi / 6  // Slightly wider cone
                cell.spin = 3.0
                cell.spinRange = 5.0
                cell.scale = 0.8
                cell.scaleRange = 0.4
                cell.color = CGColor.white
                cell.alphaSpeed = -0.15
                cell.yAcceleration = -gravity * 0.85
                cell.contents = image
                cells.append(cell)
            }
        }

        emitter.emitterCells = cells
        layer.addSublayer(emitter)

        window.orderFrontRegardless()

        // Gradually reduce the emitter's birthRate multiplier for a soft ending.
        // Use an exponential curve so most particles stop early, but a few linger.
        let steps = 12
        let rampStart = 0.1
        let rampEnd = 0.8
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            // Exponential: most of the reduction happens early
            let rate = Float(pow(1.0 - t, 2.5))
            let delay = rampStart + (rampEnd - rampStart) * t
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                emitter.birthRate = rate
            }
        }

        // Exit after particles settle
        exitTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
