import AppKit
import Foundation

struct IconSlot {
    let pointSize: Int
    let scale: Int
    let filename: String

    var pixelSize: Int {
        pointSize * scale
    }
}

let slots: [IconSlot] = [
    IconSlot(pointSize: 16, scale: 1, filename: "icon_16x16.png"),
    IconSlot(pointSize: 16, scale: 2, filename: "icon_16x16@2x.png"),
    IconSlot(pointSize: 32, scale: 1, filename: "icon_32x32.png"),
    IconSlot(pointSize: 32, scale: 2, filename: "icon_32x32@2x.png"),
    IconSlot(pointSize: 128, scale: 1, filename: "icon_128x128.png"),
    IconSlot(pointSize: 128, scale: 2, filename: "icon_128x128@2x.png"),
    IconSlot(pointSize: 256, scale: 1, filename: "icon_256x256.png"),
    IconSlot(pointSize: 256, scale: 2, filename: "icon_256x256@2x.png"),
    IconSlot(pointSize: 512, scale: 1, filename: "icon_512x512.png"),
    IconSlot(pointSize: 512, scale: 2, filename: "icon_512x512@2x.png")
]

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift tools/GenerateAppIcon.swift <AppIcon.appiconset>\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for slot in slots {
    let image = drawIcon(pixelSize: slot.pixelSize)
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        fputs("Failed to render \(slot.filename)\n", stderr)
        exit(1)
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(slot.filename), options: .atomic)
}

func drawIcon(pixelSize: Int) -> NSImage {
    let side = CGFloat(pixelSize)
    let image = NSImage(size: NSSize(width: side, height: side))

    image.lockFocus()
    defer { image.unlockFocus() }

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: side, height: side).fill()

    let baseInset = side * 0.065
    let baseRect = NSRect(
        x: baseInset,
        y: baseInset,
        width: side - baseInset * 2,
        height: side - baseInset * 2
    )
    let baseRadius = side * 0.19
    let basePath = NSBezierPath(roundedRect: baseRect, xRadius: baseRadius, yRadius: baseRadius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
    shadow.shadowBlurRadius = side * 0.045
    shadow.shadowOffset = NSSize(width: 0, height: -side * 0.018)
    shadow.set()

    NSGradient(
        colors: [
            NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.13, alpha: 1),
            NSColor(calibratedRed: 0.06, green: 0.21, blue: 0.25, alpha: 1)
        ]
    )?.draw(in: basePath, angle: 125)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    basePath.addClip()

    NSGradient(
        colors: [
            NSColor(calibratedRed: 0.10, green: 0.58, blue: 0.57, alpha: 0.92),
            NSColor(calibratedRed: 0.32, green: 0.73, blue: 0.54, alpha: 0.82)
        ]
    )?.draw(
        in: NSRect(x: baseRect.minX, y: baseRect.midY, width: baseRect.width, height: baseRect.height * 0.54),
        angle: 35
    )

    NSColor.white.withAlphaComponent(0.10).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: side * 0.48,
        y: side * 0.55,
        width: side * 0.42,
        height: side * 0.30
    )).fill()
    NSGraphicsContext.restoreGraphicsState()

    let boardRect = NSRect(
        x: side * 0.245,
        y: side * 0.215,
        width: side * 0.51,
        height: side * 0.58
    )
    let boardPath = NSBezierPath(
        roundedRect: boardRect,
        xRadius: side * 0.055,
        yRadius: side * 0.055
    )

    NSColor.white.withAlphaComponent(0.13).setFill()
    boardPath.fill()

    NSColor.white.withAlphaComponent(0.90).setStroke()
    boardPath.lineWidth = max(1.2, side * 0.030)
    boardPath.stroke()

    let clipRect = NSRect(
        x: side * 0.365,
        y: side * 0.710,
        width: side * 0.27,
        height: side * 0.115
    )
    let clipPath = NSBezierPath(
        roundedRect: clipRect,
        xRadius: side * 0.035,
        yRadius: side * 0.035
    )

    NSColor(calibratedRed: 0.95, green: 0.82, blue: 0.42, alpha: 1).setFill()
    clipPath.fill()

    NSColor.black.withAlphaComponent(0.14).setStroke()
    clipPath.lineWidth = max(0.8, side * 0.012)
    clipPath.stroke()

    let lineWidth = max(1.0, side * 0.026)
    let lineRadius = lineWidth * 0.55
    let lineColor = NSColor.white.withAlphaComponent(0.82)
    let shortLineColor = NSColor(calibratedRed: 0.95, green: 0.82, blue: 0.42, alpha: 0.96)
    let lineRects = [
        NSRect(x: side * 0.335, y: side * 0.585, width: side * 0.33, height: lineWidth),
        NSRect(x: side * 0.335, y: side * 0.485, width: side * 0.25, height: lineWidth),
        NSRect(x: side * 0.335, y: side * 0.385, width: side * 0.32, height: lineWidth)
    ]

    for (index, rect) in lineRects.enumerated() {
        (index == 1 ? shortLineColor : lineColor).setFill()
        NSBezierPath(roundedRect: rect, xRadius: lineRadius, yRadius: lineRadius).fill()
    }

    if pixelSize >= 64 {
        NSColor.white.withAlphaComponent(0.22).setStroke()
        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: side * 0.23, y: side * 0.78))
        highlight.curve(
            to: NSPoint(x: side * 0.47, y: side * 0.89),
            controlPoint1: NSPoint(x: side * 0.28, y: side * 0.86),
            controlPoint2: NSPoint(x: side * 0.38, y: side * 0.90)
        )
        highlight.lineWidth = max(1, side * 0.018)
        highlight.stroke()
    }

    return image
}
