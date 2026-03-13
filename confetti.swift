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

func makeSnowImage(diameter: CGFloat, color: NSColor) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: Int(diameter),
        height: Int(diameter),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
    ctx.setFillColor(color.cgColor)
    ctx.fillEllipse(in: rect)
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

func makeFlamePath(width: CGFloat, height: CGFloat) -> CGPath {
    let tipX = width * CGFloat.random(in: 0.44...0.56)
    let baseLeftX = width * CGFloat.random(in: 0.04...0.16)
    let baseRightX = width * CGFloat.random(in: 0.84...0.96)
    let waistY = height * CGFloat.random(in: 0.36...0.5)

    let path = CGMutablePath()
    path.move(to: CGPoint(x: baseLeftX, y: 0))
    path.addLine(to: CGPoint(x: baseRightX, y: 0))
    path.addCurve(
        to: CGPoint(x: tipX, y: height),
        control1: CGPoint(x: width * CGFloat.random(in: 0.96...1.1), y: height * CGFloat.random(in: 0.24...0.4)),
        control2: CGPoint(x: width * CGFloat.random(in: 0.62...0.74), y: height * CGFloat.random(in: 0.9...1.0))
    )
    path.addCurve(
        to: CGPoint(x: baseLeftX, y: 0),
        control1: CGPoint(x: width * CGFloat.random(in: 0.36...0.48), y: height * CGFloat.random(in: 0.9...1.0)),
        control2: CGPoint(x: width * CGFloat.random(in: -0.1...0.04), y: height * CGFloat.random(in: 0.24...0.4))
    )
    path.closeSubpath()
    return path
}

func spawnVectorFlame(
    in parentLayer: CALayer,
    x: CGFloat,
    baseY: CGFloat,
    size: CGSize,
    color: NSColor,
    delay: CFTimeInterval
) {
    let beginTime = CACurrentMediaTime() + delay
    let duration = CFTimeInterval(CGFloat.random(in: 1.2...1.8))
    let driftA = CGFloat.random(in: -28...28)
    let driftB = CGFloat.random(in: -46...46)

    let flame = CAShapeLayer()
    flame.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    flame.anchorPoint = CGPoint(x: 0.5, y: 0.0)
    flame.position = CGPoint(x: x, y: baseY)
    flame.fillColor = color.withAlphaComponent(0.72).cgColor
    flame.opacity = 0
    flame.shadowColor = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.05, alpha: 0.8).cgColor
    flame.shadowOpacity = 0.35
    flame.shadowRadius = 8
    flame.shadowOffset = CGSize(width: 0, height: 0)

    let pathA = makeFlamePath(width: size.width, height: size.height)
    let pathB = makeFlamePath(width: size.width, height: size.height)
    let pathC = makeFlamePath(width: size.width, height: size.height)
    let pathD = makeFlamePath(width: size.width, height: size.height)
    flame.path = pathA

    let core = CAShapeLayer()
    core.frame = flame.bounds.insetBy(dx: size.width * 0.2, dy: size.height * 0.14)
    core.fillColor = NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.78, alpha: 0.4).cgColor
    let corePathA = makeFlamePath(width: core.bounds.width, height: core.bounds.height)
    let corePathB = makeFlamePath(width: core.bounds.width, height: core.bounds.height)
    let corePathC = makeFlamePath(width: core.bounds.width, height: core.bounds.height)
    core.path = corePathA

    flame.addSublayer(core)
    parentLayer.addSublayer(flame)

    let positionAnim = CAKeyframeAnimation(keyPath: "position.x")
    positionAnim.values = [x, x + driftA, x + driftB]
    positionAnim.keyTimes = [0, 0.7, 1]
    positionAnim.duration = duration
    positionAnim.beginTime = beginTime
    positionAnim.timingFunctions = [
        CAMediaTimingFunction(name: .easeOut),
        CAMediaTimingFunction(name: .easeIn)
    ]
    positionAnim.fillMode = .forwards
    positionAnim.isRemovedOnCompletion = false

    let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
    opacityAnim.values = [0, 0.78, 0.5, 0]
    opacityAnim.keyTimes = [0, 0.12, 0.62, 1]
    opacityAnim.duration = duration
    opacityAnim.beginTime = beginTime
    opacityAnim.fillMode = .forwards
    opacityAnim.isRemovedOnCompletion = false

    let transformAnim = CAKeyframeAnimation(keyPath: "transform")
    let t0 = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 0.65, tx: 0.0, ty: 0.0))
    let t1 = CATransform3DMakeAffineTransform(CGAffineTransform(a: 0.92, b: 0.0, c: CGFloat.random(in: -0.16...0.16), d: 1.22, tx: 0.0, ty: 0.0))
    let t2 = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1.1, b: 0.0, c: CGFloat.random(in: -0.22...0.22), d: 1.55, tx: 0.0, ty: 0.0))
    let t3 = CATransform3DMakeAffineTransform(CGAffineTransform(a: 0.86, b: 0.0, c: CGFloat.random(in: -0.18...0.18), d: 0.78, tx: 0.0, ty: 0.0))
    transformAnim.values = [
        NSValue(caTransform3D: t0),
        NSValue(caTransform3D: t1),
        NSValue(caTransform3D: t2),
        NSValue(caTransform3D: t3)
    ]
    transformAnim.keyTimes = [0, 0.25, 0.72, 1]
    transformAnim.duration = duration
    transformAnim.beginTime = beginTime
    transformAnim.timingFunctions = [
        CAMediaTimingFunction(name: .easeOut),
        CAMediaTimingFunction(name: .easeInEaseOut),
        CAMediaTimingFunction(name: .easeIn)
    ]
    transformAnim.fillMode = .forwards
    transformAnim.isRemovedOnCompletion = false

    let rotateAnim = CAKeyframeAnimation(keyPath: "transform.rotation.z")
    rotateAnim.values = [0, CGFloat.random(in: -0.14...0.14), CGFloat.random(in: -0.2...0.2)]
    rotateAnim.keyTimes = [0, 0.5, 1]
    rotateAnim.duration = duration
    rotateAnim.beginTime = beginTime
    rotateAnim.fillMode = .forwards
    rotateAnim.isRemovedOnCompletion = false

    let morphAnim = CAKeyframeAnimation(keyPath: "path")
    morphAnim.values = [pathA, pathB, pathC, pathD, pathA]
    morphAnim.keyTimes = [0, 0.25, 0.5, 0.75, 1]
    morphAnim.duration = 0.26
    morphAnim.repeatCount = Float(duration / 0.26) + 1
    morphAnim.beginTime = beginTime
    morphAnim.calculationMode = .linear

    let coreMorphAnim = CAKeyframeAnimation(keyPath: "path")
    coreMorphAnim.values = [corePathA, corePathB, corePathC, corePathA]
    coreMorphAnim.keyTimes = [0, 0.33, 0.66, 1]
    coreMorphAnim.duration = 0.22
    coreMorphAnim.repeatCount = Float(duration / 0.22) + 1
    coreMorphAnim.beginTime = beginTime
    coreMorphAnim.calculationMode = .linear

    flame.add(positionAnim, forKey: "rise")
    flame.add(opacityAnim, forKey: "fade")
    flame.add(transformAnim, forKey: "shape")
    flame.add(rotateAnim, forKey: "rotate")
    flame.add(morphAnim, forKey: "morph")
    core.add(coreMorphAnim, forKey: "coreMorph")

    DispatchQueue.main.asyncAfter(deadline: .now() + delay + duration + 0.1) {
        flame.removeFromSuperlayer()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: ConfettiWindow!
    var exitTimer: Timer?

    enum ParticleMode {
        case confetti
        case balloons
        case fire
        case snow
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let args = Set(CommandLine.arguments.dropFirst())
        let mode: ParticleMode
        if args.contains("--random") {
            let modes: [ParticleMode] = [.confetti, .balloons, .fire, .snow]
            mode = modes.randomElement() ?? .confetti
        } else if args.contains("--snow") {
            mode = .snow
        } else if args.contains("--fire") {
            mode = .fire
        } else if args.contains("--confetti") {
            mode = .confetti
        } else if args.contains("--balloons") {
            mode = .balloons
        } else {
            mode = .confetti
        }

        let launchBalloons = mode == .balloons
        let launchFire = mode == .fire
        let launchSnow = mode == .snow

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
        emitter.emitterPosition = CGPoint(x: frame.width / 2, y: launchSnow ? frame.height + 20 : -20)
        emitter.emitterSize = CGSize(width: frame.width, height: 1)
        emitter.emitterShape = .line
        emitter.renderMode = .oldestLast
        emitter.frame = CGRect(origin: .zero, size: frame.size)
        emitter.beginTime = CACurrentMediaTime()

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
        } else if launchFire {
            let flameColors: [NSColor] = [
                NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.5, alpha: 1.0),
                NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.18, alpha: 1.0),
                NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.08, alpha: 1.0),
                NSColor(calibratedRed: 0.95, green: 0.28, blue: 0.04, alpha: 1.0),
                NSColor(calibratedRed: 0.78, green: 0.08, blue: 0.02, alpha: 0.9),
            ]

            let fireLayer = CALayer()
            fireLayer.frame = CGRect(origin: .zero, size: frame.size)
            layer.addSublayer(fireLayer)

            let emberBed = CAGradientLayer()
            emberBed.frame = CGRect(x: 0, y: -10, width: frame.width, height: 68)
            emberBed.colors = [
                NSColor(calibratedRed: 1.0, green: 0.44, blue: 0.04, alpha: 0.62).cgColor,
                NSColor(calibratedRed: 0.95, green: 0.22, blue: 0.03, alpha: 0.35).cgColor,
                NSColor.clear.cgColor,
            ]
            emberBed.locations = [0.0, 0.38, 1.0]
            emberBed.startPoint = CGPoint(x: 0.5, y: 0.0)
            emberBed.endPoint = CGPoint(x: 0.5, y: 1.0)
            fireLayer.addSublayer(emberBed)

            let emberCore = CALayer()
            emberCore.frame = CGRect(x: 0, y: -3, width: frame.width, height: 12)
            emberCore.backgroundColor = NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.03, alpha: 0.42).cgColor
            fireLayer.addSublayer(emberCore)

            let emberFlicker = CAKeyframeAnimation(keyPath: "opacity")
            emberFlicker.values = [0.75, 0.95, 0.7, 0.88, 0.76]
            emberFlicker.keyTimes = [0, 0.2, 0.45, 0.75, 1]
            emberFlicker.duration = 0.24
            emberFlicker.repeatCount = 18
            emberBed.add(emberFlicker, forKey: "emberFlicker")

            let burstDuration: TimeInterval = 1.0
            let tick: TimeInterval = 1.0 / 20.0
            let startTime = CACurrentMediaTime()
            let columns = max(14, Int(frame.width / 90))

            Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { timer in
                let elapsed = CACurrentMediaTime() - startTime
                if elapsed >= burstDuration {
                    timer.invalidate()
                    return
                }

                let remaining = max(0, 1.0 - (elapsed / burstDuration))
                let intensity = CGFloat(pow(remaining, 0.85))
                let flamesThisTick = max(1, Int(CGFloat(columns) * (0.0375 + intensity * 0.079)))

                for _ in 0..<flamesThisTick {
                    let x = CGFloat.random(in: 0...frame.width)
                    let baseY = CGFloat.random(in: -2...2)
                    let size = CGSize(
                        width: CGFloat.random(in: 144...378),
                        height: CGFloat.random(in: 216...576)
                    )
                    let color = flameColors.randomElement() ?? flameColors[0]
                    let delay = CFTimeInterval(CGFloat.random(in: 0...0.07))

                    spawnVectorFlame(
                        in: fireLayer,
                        x: x,
                        baseY: baseY,
                        size: size,
                        color: color,
                        delay: delay
                    )
                }
            }
        } else if launchSnow {
            let snowColor = NSColor(calibratedWhite: 1.0, alpha: 0.95)
            let targetParticles = frame.width / 5
            let numShapes: CGFloat = 3
            let driftVariants: CGFloat = 3
            let totalCells = numShapes * driftVariants
            let birthRatePerCell = Float(targetParticles / (emissionDuration * totalCells))

            for diameter in [6.0, 9.0, 12.0] as [CGFloat] {
                if let image = makeSnowImage(diameter: diameter, color: snowColor) {
                    for xDrift in [-14.0, 0.0, 14.0] as [CGFloat] {
                        let cell = CAEmitterCell()
                        cell.birthRate = birthRatePerCell
                        cell.lifetime = 12.0
                        cell.lifetimeRange = 2.0
                        cell.velocity = 110
                        cell.velocityRange = 50
                        cell.emissionLongitude = -CGFloat.pi / 2
                        cell.emissionRange = CGFloat.pi / 14
                        cell.xAcceleration = xDrift
                        cell.yAcceleration = -45
                        cell.spin = 0.18
                        cell.spinRange = 0.35
                        cell.scale = 1.0
                        cell.scaleRange = 0.25
                        cell.color = CGColor.white
                        cell.alphaSpeed = -0.12
                        cell.contents = image
                        cells.append(cell)
                    }
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

        if !launchFire {
            emitter.emitterCells = cells
            layer.addSublayer(emitter)
        }

        window.orderFrontRegardless()

        if !launchFire {
            if launchSnow {
                let emissionWindow: TimeInterval = 5.0
                let fadeOutDuration: TimeInterval = 2.0
                let tick: TimeInterval = 0.2
                let startTime = CACurrentMediaTime()
                emitter.birthRate = Float.random(in: 0.45...1.2)

                DispatchQueue.main.asyncAfter(deadline: .now() + emissionWindow) {
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(fadeOutDuration)
                    emitter.opacity = 0
                    CATransaction.commit()
                }

                Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { timer in
                    let elapsed = CACurrentMediaTime() - startTime
                    if elapsed >= emissionWindow {
                        emitter.birthRate = 0
                        timer.invalidate()
                        return
                    }

                    let lull = Int.random(in: 0...4) == 0
                    emitter.birthRate = lull
                        ? Float.random(in: 0.08...0.28)
                        : Float.random(in: 0.45...1.25)
                }
            } else {
                // Gradually reduce the emitter's birthRate multiplier for a soft ending.
                // Use an exponential curve so most particles stop early, but a few linger.
                let steps = 12
                let rampStart = 0.1
                let rampEnd = 0.8
                for i in 0...steps {
                    let t = Double(i) / Double(steps)
                    let rate = Float(pow(1.0 - t, 2.5))
                    let delay = rampStart + (rampEnd - rampStart) * t
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        emitter.birthRate = rate
                    }
                }
            }
        }

        let exitDelay = launchFire ? 3.0 : (launchBalloons ? 8.0 : (launchSnow ? 7.0 : 5.0))
        exitTimer = Timer.scheduledTimer(withTimeInterval: exitDelay, repeats: false) { _ in
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
