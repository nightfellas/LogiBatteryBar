import AppKit

func createIconImage(size: CGFloat) -> NSImage {
    let img = NSImage(size: CGSize(width: size, height: size))
    img.lockFocus()
    
    guard let context = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }
    
    // Scale coordinate space so we can design in 1024x1024
    let scale = size / 1024.0
    context.scaleBy(x: scale, y: scale)
    
    // Canvas: 1024 x 1024
    // Standard macOS squircle rect:
    let bodyRect = NSRect(x: 100, y: 100, width: 824, height: 824)
    let cornerRadius: CGFloat = 185
    let squirclePath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Draw Drop Shadow
    context.saveGState()
    let shadowColor = NSColor.black.withAlphaComponent(0.35).cgColor
    context.setShadow(offset: CGSize(width: 0, height: -24), blur: 36, color: shadowColor)
    NSColor.black.setFill()
    squirclePath.fill()
    context.restoreGState()
    
    // Draw Squircle Background Gradient
    context.saveGState()
    squirclePath.addClip()
    
    let baseGradient = NSGradient(colors: [
        NSColor(red: 0.12, green: 0.15, blue: 0.24, alpha: 1.0), // top slate navy
        NSColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 1.0)  // bottom dark obsidian
    ])
    baseGradient?.draw(in: bodyRect, angle: -90)
    
    // Subtle radial highlight from top center
    let highlightGradient = NSGradient(colors: [
        NSColor(red: 0.35, green: 0.50, blue: 0.85, alpha: 0.25),
        NSColor(red: 0.10, green: 0.20, blue: 0.40, alpha: 0.0)
    ])
    highlightGradient?.draw(fromCenter: CGPoint(x: 512, y: 800), radius: 0,
                            toCenter: CGPoint(x: 512, y: 800), radius: 450,
                            options: [])
    context.restoreGState()
    
    // Squircle Border (Glass stroke)
    context.saveGState()
    let borderPath = NSBezierPath(roundedRect: bodyRect.insetBy(dx: 2, dy: 2), xRadius: cornerRadius - 2, yRadius: cornerRadius - 2)
    NSColor(white: 1.0, alpha: 0.15).setStroke()
    borderPath.lineWidth = 4
    borderPath.stroke()
    context.restoreGState()
    
    // Inner Card / Floating Surface
    let cardRect = NSRect(x: 180, y: 220, width: 664, height: 584)
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 50, yRadius: 50)
    
    context.saveGState()
    let cardShadow = NSColor.black.withAlphaComponent(0.4).cgColor
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 24, color: cardShadow)
    NSColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 0.85).setFill()
    cardPath.fill()
    context.restoreGState()
    
    // Card border
    context.saveGState()
    NSColor(white: 1.0, alpha: 0.12).setStroke()
    cardPath.lineWidth = 3
    cardPath.stroke()
    context.restoreGState()
    
    // Center Icons:
    // Left side: Computer Mouse (SF Symbol)
    let mouseConfig = NSImage.SymbolConfiguration(pointSize: 180, weight: .medium)
    if let mouseImg = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: nil)?.withSymbolConfiguration(mouseConfig) {
        let mouseRect = NSRect(x: 240, y: 440, width: 220, height: 260)
        NSColor(red: 0.88, green: 0.92, blue: 0.98, alpha: 0.95).set()
        mouseImg.draw(in: mouseRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    
    // Right side: Keyboard (SF Symbol)
    let kbConfig = NSImage.SymbolConfiguration(pointSize: 170, weight: .medium)
    if let kbImg = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: nil)?.withSymbolConfiguration(kbConfig) {
        let kbRect = NSRect(x: 530, y: 450, width: 240, height: 240)
        NSColor(red: 0.88, green: 0.92, blue: 0.98, alpha: 0.95).set()
        kbImg.draw(in: kbRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    
    // Bottom: Battery Bar with glowing Bolt
    let barBgRect = NSRect(x: 240, y: 310, width: 544, height: 64)
    let barBgPath = NSBezierPath(roundedRect: barBgRect, xRadius: 32, yRadius: 32)
    NSColor(white: 0.05, alpha: 0.8).setFill()
    barBgPath.fill()
    
    // Filled Battery Progress (e.g. 80%)
    let fillWidth: CGFloat = 544.0 * 0.82
    let barFillRect = NSRect(x: 240, y: 310, width: fillWidth, height: 64)
    let barFillPath = NSBezierPath(roundedRect: barFillRect, xRadius: 32, yRadius: 32)
    
    context.saveGState()
    let greenGlow = NSColor(red: 0.13, green: 0.85, blue: 0.45, alpha: 0.6).cgColor
    context.setShadow(offset: .zero, blur: 16, color: greenGlow)
    
    let greenGradient = NSGradient(colors: [
        NSColor(red: 0.20, green: 0.88, blue: 0.50, alpha: 1.0),
        NSColor(red: 0.10, green: 0.75, blue: 0.40, alpha: 1.0)
    ])
    greenGradient?.draw(in: barFillPath, angle: 0)
    context.restoreGState()
    
    // Lightning Bolt inside the battery bar
    let boltConfig = NSImage.SymbolConfiguration(pointSize: 32, weight: .bold)
    if let boltImg = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)?.withSymbolConfiguration(boltConfig) {
        let boltRect = NSRect(x: 495, y: 322, width: 36, height: 40)
        NSColor.white.set()
        boltImg.draw(in: boltRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    
    img.unlockFocus()
    return img
}

let fileManager = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (ptSize, scale) in sizes {
    let pxSize = ptSize * scale
    let img = createIconImage(size: CGFloat(pxSize))
    
    guard let tiffData = img.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG for size \(pxSize)")
        continue
    }
    
    let filename: String
    if scale == 1 {
        filename = "icon_\(ptSize)x\(ptSize).png"
    } else {
        filename = "icon_\(ptSize)x\(ptSize)@2x.png"
    }
    
    let outPath = "\(iconsetDir)/\(filename)"
    try pngData.write(to: URL(fileURLWithPath: outPath))
}

print("Generated iconset successfully.")
