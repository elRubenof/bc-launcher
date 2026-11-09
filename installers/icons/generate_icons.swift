// Generates the app icons of every platform: the face on its rounded square,
// drawn from the vector at each size.
//
// The face is pixel art on a 14 × 14 grid.
// - Windows and Linux use assets/img/icon.svg, the same face the launcher shows
//   (corners of 2 cells, 14.3 %: the curve ends where the outer tentacles of
//   its animation start). The square takes 14 of 16 parts of the icon, so at
//   16, 32, 48 px… each grid cell is a whole number of pixels and stays sharp.
// - macOS uses assets/img/icon_macos.svg, the same face with the system's
//   corners (22.5 %), inside 824 of 1024 px like the other icons in the Dock.
//
// macOS only (AppKit reads the SVG). From the repo's root:
//
//   swift installers/icons/generate_icons.swift
//
// Writes:
//   windows/runner/resources/app_icon.ico            16 to 256 px
//   macos/Runner/Assets.xcassets/AppIcon.appiconset   16 to 1024 px
//   installers/macos/AppIcon.icns                     16 to 1024 px
//   installers/linux/app_icon.png                     512 px

import AppKit

func load(_ path: String) -> NSImage {
  guard let image = NSImage(contentsOfFile: path) else {
    fatalError("Run it from the repo's root: \(path) not found")
  }
  return image
}

let icon = load("assets/img/icon.svg")
let macIcon = load("assets/img/icon_macos.svg")

/// The margin around the square, as a share of the icon's side.
let pixelMargin = 1.0 / 16
let macMargin = 100.0 / 1024

/// [image] at [size] px, with [margin] around the square.
func render(_ image: NSImage, _ size: Int, margin: Double) -> Data {
  guard
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
  else { fatalError("Could not create a \(size) px bitmap") }
  bitmap.size = NSSize(width: size, height: size)

  NSGraphicsContext.saveGraphicsState()
  let context = NSGraphicsContext(bitmapImageRep: bitmap)!
  NSGraphicsContext.current = context
  context.shouldAntialias = true

  let inset = Double(size) * margin
  let side = Double(size) - 2 * inset
  image.draw(in: NSRect(x: inset, y: inset, width: side, height: side))

  NSGraphicsContext.restoreGraphicsState()
  guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the \(size) px icon")
  }
  return png
}

func write(_ data: Data, to path: String) {
  let url = URL(fileURLWithPath: path)
  try! FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  try! data.write(to: url)
  print("wrote \(path)")
}

/// A .ico holding one PNG per size (read by Windows Vista and later).
func ico(_ sizes: [Int]) -> Data {
  let images = sizes.map { render(icon, $0, margin: pixelMargin) }
  var data = Data()
  func le16(_ v: Int) { data.append(contentsOf: [UInt8(v & 0xff), UInt8(v >> 8 & 0xff)]) }
  func le32(_ v: Int) { for shift in [0, 8, 16, 24] { data.append(UInt8(v >> shift & 0xff)) } }

  le16(0)
  le16(1)
  le16(sizes.count)
  var offset = 6 + 16 * sizes.count
  for (size, png) in zip(sizes, images) {
    data.append(UInt8(size >= 256 ? 0 : size))
    data.append(UInt8(size >= 256 ? 0 : size))
    data.append(0)
    data.append(0)
    le16(1)
    le16(32)
    le32(png.count)
    le32(offset)
    offset += png.count
  }
  for png in images { data.append(png) }
  return data
}

write(
  ico([16, 20, 24, 32, 40, 48, 64, 96, 128, 256]),
  to: "windows/runner/resources/app_icon.ico")

for size in [16, 32, 64, 128, 256, 512, 1024] {
  write(
    render(macIcon, size, margin: macMargin),
    to: "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_\(size).png")
}

let tempIconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: tempIconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
  let p1x = render(macIcon, size, margin: macMargin)
  let p2x = render(macIcon, size * 2, margin: macMargin)
  try? p1x.write(to: tempIconset.appendingPathComponent("icon_\(size)x\(size).png"))
  try? p2x.write(to: tempIconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", tempIconset.path, "-o", "installers/macos/AppIcon.icns"]
try? iconutil.run()
iconutil.waitUntilExit()
try? FileManager.default.removeItem(at: tempIconset)
print("wrote installers/macos/AppIcon.icns")

write(render(icon, 512, margin: pixelMargin), to: "installers/linux/app_icon.png")
