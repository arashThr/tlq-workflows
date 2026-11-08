import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 4 else {
    fputs("usage: cover-number TEMPLATE OUTPUT EPISODE\n", stderr)
    exit(1)
}

let templateURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])
let episode = args[3]

guard episode.range(of: #"^\d{1,3}$"#, options: .regularExpression) != nil else {
    fputs("episode number must be 0–999\n", stderr)
    exit(1)
}

guard let source = CGImageSourceCreateWithURL(templateURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fputs("could not read \(templateURL.path)\n", stderr)
    exit(1)
}

let width = image.width
let height = image.height
guard width == 1408, height == 1408 else {
    fputs("cover template must be 1408×1408, this one is \(width)×\(height)\n", stderr)
    exit(1)
}

// Measured on assets/EP02.png. The digit sits to the right of EPISODE.
let digitCenterX: CGFloat = 818.5
let digitCenterFromTop: CGFloat = 1075.5
let digitHeight: CGFloat = 61
let safeLeft: CGFloat = 776
let safeRight: CGFloat = 1300
let safeTop: CGFloat = 1000
let safeBottom: CGFloat = 1160

func line(size: CGFloat) -> CTLine {
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil)
    let attrs = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: CGColor(gray: 1, alpha: 1),
    ] as CFDictionary
    let text = CFAttributedStringCreate(nil, episode as CFString, attrs)!
    return CTLineCreateWithAttributedString(text)
}

func inkSize(_ size: CGFloat) -> CGSize {
    CTLineGetImageBounds(line(size: size), nil).size
}

var low: CGFloat = 40
var high: CGFloat = 160
var fontSize: CGFloat = 80
for _ in 0..<16 {
    let mid = (low + high) / 2
    fontSize = mid
    if inkSize(mid).height > digitHeight {
        high = mid
    } else {
        low = mid
    }
}

let drawn = line(size: fontSize)
let ink = CTLineGetImageBounds(drawn, nil)
guard ink.width > 0, ink.height > 0 else {
    fputs("could not measure the episode number\n", stderr)
    exit(1)
}

// Core Graphics y grows upward. Image bounds are relative to the baseline.
let targetCenterY = CGFloat(height) - digitCenterFromTop
var baselineX = digitCenterX - ink.origin.x - ink.width / 2
let baselineY = targetCenterY - ink.origin.y - ink.height / 2
var inkLeft = baselineX + ink.origin.x
if inkLeft < safeLeft {
    baselineX += safeLeft - inkLeft
    inkLeft = safeLeft
}
let inkRight = inkLeft + ink.width
if inkRight > safeRight {
    fputs("episode number does not fit on the cover\n", stderr)
    exit(1)
}

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
    fputs("could not create the cover\n", stderr)
    exit(1)
}

ctx.interpolationQuality = .high
ctx.setAllowsAntialiasing(true)
ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

// Top-left origin. Cover the old digit and the new one, and stay clear of the other lines.
let inkTop = CGFloat(height) - (baselineY + ink.origin.y + ink.height)
let inkBottom = CGFloat(height) - (baselineY + ink.origin.y)
let eraseLeft = max(safeLeft, min(790, inkLeft - 4))
let eraseRight = min(safeRight, max(848, inkRight + 4))
let eraseTop = max(safeTop, min(1038, inkTop - 4))
let eraseBottom = min(safeBottom, max(1114, inkBottom + 4))
ctx.setFillColor(CGColor(gray: 0, alpha: 1))
ctx.fill(CGRect(
    x: eraseLeft,
    y: CGFloat(height) - eraseBottom,
    width: min(eraseRight, safeRight) - eraseLeft,
    height: eraseBottom - eraseTop
))

ctx.textPosition = CGPoint(x: baselineX, y: baselineY)
CTLineDraw(drawn, ctx)

guard let result = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("could not write \(outputURL.path)\n", stderr)
    exit(1)
}
CGImageDestinationAddImage(dest, result, nil)
guard CGImageDestinationFinalize(dest) else {
    fputs("could not write \(outputURL.path)\n", stderr)
    exit(1)
}
