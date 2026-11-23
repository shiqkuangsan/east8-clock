// Renders the East8 Clock app icon and packages it as Resources/AppIcon.icns.
// Usage: swift scripts/make-icon.swift [theme]       (default theme: blue)
//        swift scripts/make-icon.swift sheet <out.png>  (compare all themes)
import AppKit
import ImageIO
import UniformTypeIdentifiers

let projectDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconsetDir = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
let outputICNS = projectDir.appendingPathComponent("Resources/AppIcon.icns")
let previewPNG = projectDir.appendingPathComponent("Resources/AppIcon-1024.png")

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

struct Theme {
    let name: String
    let top: CGColor
    let bottom: CGColor
    let accent: CGColor
}

let themes = [
    Theme(name: "blue", top: rgb(0x4DB0FF), bottom: rgb(0x0A63E0), accent: rgb(0xFF9500)),
    Theme(name: "indigo", top: rgb(0x7D7BFF), bottom: rgb(0x3F35C8), accent: rgb(0xFF9F0A)),
    Theme(name: "purple", top: rgb(0xD17BFF), bottom: rgb(0x7A2BD9), accent: rgb(0xFF9F0A)),
    Theme(name: "teal", top: rgb(0x4FD8D0), bottom: rgb(0x0B8F9A), accent: rgb(0xFF9500)),
    Theme(name: "green", top: rgb(0x6BE08A), bottom: rgb(0x1E9E48), accent: rgb(0xFF9500)),
    Theme(name: "graphite", top: rgb(0x6E6E73), bottom: rgb(0x1C1C1E), accent: rgb(0x0A84FF)),
]

let faceTop = rgb(0xFFFFFF)
let faceBottom = rgb(0xEEF1F5)
let graphite = rgb(0x1D1D1F)

/// Point on the clock at `fraction` of a full turn clockwise from 12, `radius` from the center.
func clockPoint(_ fraction: CGFloat, _ radius: CGFloat, center: CGPoint) -> CGPoint {
    let angle = fraction * 2 * .pi
    return CGPoint(x: center.x + sin(angle) * radius, y: center.y - cos(angle) * radius)
}

func strokeLine(_ ctx: CGContext, from a: CGPoint, to b: CGPoint, width: CGFloat, color: CGColor) {
    ctx.setStrokeColor(color)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.move(to: a)
    ctx.addLine(to: b)
    ctx.strokePath()
}

func circleRect(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
    CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
}

func fillCircle(_ ctx: CGContext, _ center: CGPoint, _ radius: CGFloat, _ color: CGColor) {
    ctx.setFillColor(color)
    ctx.fillEllipse(in: circleRect(center, radius))
}

/// Fills the current clip with a vertical gradient between y0 and y1.
func verticalGradient(_ ctx: CGContext, _ top: CGColor, _ bottom: CGColor, from y0: CGFloat, to y1: CGFloat) {
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                              colors: [top, bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: y0), end: CGPoint(x: 0, y: y1),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

/// Superellipse ("squircle") close to the continuous-corner shape of macOS app icons.
func squirclePath(in rect: CGRect, exponent n: CGFloat = 5) -> CGPath {
    let path = CGMutablePath()
    let a = rect.width / 2, b = rect.height / 2
    let steps = 720
    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let c = cos(t), s = sin(t)
        let x = rect.midX + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = rect.midY + b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

/// Draws the icon on a 1024-unit canvas (top-left origin), at `pixels` output size.
func renderIcon(pixels: Int, theme: Theme) -> CGImage {
    let accent = theme.accent
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let k = CGFloat(pixels) / 1024
    ctx.translateBy(x: 0, y: CGFloat(pixels))
    ctx.scaleBy(x: k, y: -k)
    ctx.interpolationQuality = .high
    let detailed = pixels > 32

    // Body on Apple's macOS icon grid: 824pt inside the 1024 canvas, with a soft drop shadow.
    let bodyPath = squirclePath(in: CGRect(x: 100, y: 100, width: 824, height: 824))
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 22, color: rgb(0x000000, 0.28))
    ctx.addPath(bodyPath)
    ctx.setFillColor(theme.bottom)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    verticalGradient(ctx, theme.top, theme.bottom, from: 100, to: 924)
    ctx.restoreGState()

    let center = CGPoint(x: 512, y: 512)
    let faceRadius: CGFloat = 318

    // Raised white face.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -16), blur: 36, color: rgb(0x000000, 0.30))
    fillCircle(ctx, center, faceRadius, faceTop)
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addEllipse(in: circleRect(center, faceRadius))
    ctx.clip()
    verticalGradient(ctx, faceTop, faceBottom, from: center.y - faceRadius, to: center.y + faceRadius)
    ctx.restoreGState()

    // Minute and hour ticks; the 8 o'clock position carries the accent "8".
    if detailed {
        for minute in 0..<60 where minute % 5 != 0 && !(37...43).contains(minute) {
            strokeLine(ctx,
                       from: clockPoint(CGFloat(minute) / 60, 284, center: center),
                       to: clockPoint(CGFloat(minute) / 60, 268, center: center),
                       width: 5, color: rgb(0x1D1D1F, 0.28))
        }
    }
    for hour in 0..<12 where hour != 8 && (detailed || hour % 3 == 0) {
        let fraction = CGFloat(hour) / 12
        strokeLine(ctx,
                   from: clockPoint(fraction, 284, center: center),
                   to: clockPoint(fraction, detailed ? 240 : 232, center: center),
                   width: detailed ? 14 : 24, color: graphite)
    }

    let eightPosition = clockPoint(8.0 / 12, 232, center: center)
    if detailed {
        let font = NSFont.systemFont(ofSize: 132, weight: .semibold)
        let text = NSAttributedString(string: "8", attributes: [
            .font: font,
            .foregroundColor: NSColor(cgColor: accent)!,
        ])
        let line = CTLineCreateWithAttributedString(text)
        let bounds = CTLineGetImageBounds(line, ctx)
        ctx.saveGState()
        ctx.translateBy(x: eightPosition.x - bounds.midX, y: eightPosition.y + bounds.midY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    } else {
        fillCircle(ctx, eightPosition, 40, accent)
    }

    // Hands set to 8:00, with a soft shadow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 14, color: rgb(0x000000, 0.22))
    let thick: CGFloat = detailed ? 1 : 1.5
    strokeLine(ctx, from: clockPoint(8.0 / 12, -24, center: center), to: clockPoint(8.0 / 12, 140, center: center),
               width: 30 * thick, color: graphite)
    strokeLine(ctx, from: clockPoint(0, -30, center: center), to: clockPoint(0, 284, center: center),
               width: 18 * thick, color: graphite)
    fillCircle(ctx, center, 26, graphite)
    ctx.restoreGState()
    fillCircle(ctx, center, 11, accent)

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "Could not write \(url.path)")
}

/// Lays every theme out in a labeled grid for side-by-side comparison.
func renderSheet() -> CGImage {
    let cell = 420, label = 60, columns = 3
    let rows = (themes.count + columns - 1) / columns
    let width = cell * columns, height = (cell + label) * rows
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(rgb(0xF5F5F7))
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    for (index, theme) in themes.enumerated() {
        let x = (index % columns) * cell
        let top = (index / columns) * (cell + label)
        let y = height - top - cell  // CoreGraphics origin is bottom-left.
        ctx.draw(renderIcon(pixels: cell, theme: theme), in: CGRect(x: x, y: y, width: cell, height: cell))
        let text = NSAttributedString(string: "\(index + 1). \(theme.name)", attributes: [
            .font: NSFont.systemFont(ofSize: 30, weight: .medium),
            .foregroundColor: NSColor(white: 0.2, alpha: 1),
        ])
        let line = CTLineCreateWithAttributedString(text)
        let bounds = CTLineGetImageBounds(line, ctx)
        ctx.textPosition = CGPoint(x: CGFloat(x) + (CGFloat(cell) - bounds.width) / 2, y: CGFloat(y - label + 18))
        CTLineDraw(line, ctx)
    }
    return ctx.makeImage()!
}

let arguments = CommandLine.arguments.dropFirst()
if arguments.first == "sheet" {
    let out = URL(fileURLWithPath: arguments.dropFirst().first ?? "icon-themes.png")
    writePNG(renderSheet(), to: out)
    print(out.path)
    exit(0)
}

let themeName = arguments.first ?? "blue"
guard let theme = themes.first(where: { $0.name == themeName }) else {
    fatalError("Unknown theme \(themeName); choose from \(themes.map(\.name).joined(separator: ", "))")
}

try? FileManager.default.removeItem(at: iconsetDir)
try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 1 ? "" : "@2x"
        writePNG(renderIcon(pixels: points * scale, theme: theme),
                 to: iconsetDir.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}
writePNG(renderIcon(pixels: 1024, theme: theme), to: previewPNG)

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetDir.path, "-o", outputICNS.path]
try iconutil.run()
iconutil.waitUntilExit()
precondition(iconutil.terminationStatus == 0, "iconutil failed")
print(outputICNS.path)
