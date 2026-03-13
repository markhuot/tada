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

func makeBalloonImage(width: CGFloat, height: CGFloat, color: NSColor) -> CGImage? {
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

    let bodyRect = CGRect(x: 2, y: 10, width: width - 4, height: height - 14)

    let horizontalSign: CGFloat = Bool.random() ? -1.0 : 1.0
    let horizontalMagnitude = CGFloat.random(in: bodyRect.width * 0.04...bodyRect.width * 0.18)
    let centerX = bodyRect.midX + (horizontalSign * horizontalMagnitude)
    let centerY = bodyRect.midY + CGFloat.random(in: bodyRect.height * 0.10...bodyRect.height * 0.28)
    let gradientCenter = CGPoint(x: centerX, y: centerY)
    let gradientRadius = max(bodyRect.width, bodyRect.height) * 0.95

    let core = color.blended(withFraction: 0.35, of: .white) ?? color
    let edge = color.blended(withFraction: 0.35, of: .black) ?? color

    if let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [core.cgColor, color.cgColor, edge.cgColor] as CFArray,
        locations: [0.0, 0.55, 1.0]
    ) {
        ctx.saveGState()
        ctx.addEllipse(in: bodyRect)
        ctx.clip()
        ctx.drawRadialGradient(
            gradient,
            startCenter: gradientCenter,
            startRadius: 1.0,
            endCenter: CGPoint(x: bodyRect.midX, y: bodyRect.midY),
            endRadius: gradientRadius,
            options: [.drawsAfterEndLocation]
        )
        ctx.restoreGState()
    } else {
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: bodyRect)
    }

    ctx.setFillColor(color.blended(withFraction: 0.2, of: .black)?.cgColor ?? color.cgColor)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: width / 2 - 2, y: 10))
    ctx.addLine(to: CGPoint(x: width / 2 + 2, y: 10))
    ctx.addLine(to: CGPoint(x: width / 2, y: 6))
    ctx.closePath()
    ctx.fillPath()

    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.45).cgColor)
    ctx.setLineWidth(1.0)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: width / 2, y: 6))
    ctx.addCurve(
        to: CGPoint(x: width / 2 - 3, y: 0),
        control1: CGPoint(x: width / 2 + 2, y: 4),
        control2: CGPoint(x: width / 2 - 4, y: 2)
    )
    ctx.strokePath()

    return ctx.makeImage()
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: ConfettiWindow!
    var exitTimer: Timer?

    enum ParticleMode {
        case confetti
        case balloons
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let args = Set(CommandLine.arguments.dropFirst())
        let mode: ParticleMode
        if args.contains("--random") {
            mode = Bool.random() ? .balloons : .confetti
        } else if args.contains("--confetti") {
            mode = .confetti
        } else if args.contains("--balloons") {
            mode = .balloons
        } else {
            mode = .confetti
        }

        let launchBalloons = mode == .balloons

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

        let emissionDuration: CGFloat = 1.5
        let numColors: CGFloat = 8
        var cells: [CAEmitterCell] = []

        if launchBalloons {
            let numShapes: CGFloat = 1
            let totalCells = numColors * numShapes
            let targetParticles = frame.width / 12
            let birthRatePerCell = Float(targetParticles / (emissionDuration * totalCells))

            for (r, g, b) in colors {
                let color = NSColor(calibratedRed: r, green: g, blue: b, alpha: 0.7)
                if let image = makeBalloonImage(width: 120, height: 180, color: color) {
                    let cell = CAEmitterCell()
                    cell.birthRate = birthRatePerCell
                    cell.lifetime = 7.0
                    cell.lifetimeRange = 1.5
                    cell.velocity = 990
                    cell.velocityRange = 810
                    cell.emissionLongitude = CGFloat.pi
                    cell.emissionRange = CGFloat.pi / 12
                    cell.spin = 0.0
                    cell.spinRange = 1.8
                    cell.scale = 1.0
                    cell.scaleRange = 0.35
                    cell.color = CGColor.white
                    cell.alphaSpeed = -0.03
                    cell.yAcceleration = 110
                    cell.contents = image
                    cells.append(cell)
                }
            }
        } else {
            // Calculate physics values so confetti peaks at ~75% of screen height.
            let targetHeight = frame.height * 0.75
            let gravity: CGFloat = 3200
            let baseVelocity = sqrt(2.0 * gravity * targetHeight)

            let numShapes: CGFloat = 2
            let totalCells = numColors * numShapes
            let targetParticles = frame.width / 2
            let birthRatePerCell = Float(targetParticles / (emissionDuration * totalCells))

            for (r, g, b) in colors {
                let color = NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0)

                if let image = makeConfettiImage(width: 12, height: 8, color: color) {
                    let cell = CAEmitterCell()
                    cell.birthRate = birthRatePerCell
                    cell.lifetime = 5.0
                    cell.lifetimeRange = 1.5
                    cell.velocity = baseVelocity * 0.7
                    cell.velocityRange = baseVelocity * 0.6
                    cell.emissionLongitude = CGFloat.pi
                    cell.emissionRange = CGFloat.pi / 8
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

                if let image = makeConfettiImage(width: 8, height: 8, color: color) {
                    let cell = CAEmitterCell()
                    cell.birthRate = birthRatePerCell
                    cell.lifetime = 5.0
                    cell.lifetimeRange = 1.5
                    cell.velocity = baseVelocity * 0.6
                    cell.velocityRange = baseVelocity * 0.55
                    cell.emissionLongitude = CGFloat.pi
                    cell.emissionRange = CGFloat.pi / 6
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

        let exitDelay = launchBalloons ? 8.0 : 5.0
        exitTimer = Timer.scheduledTimer(withTimeInterval: exitDelay, repeats: false) { _ in
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
