import UIKit

enum PlaceholderArt {
    static func generate(for movie: Movie, size: CGSize = CGSize(width: 440, height: 626)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        let accent = movie.accentColor
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        accent.getRed(&r, green: &g, blue: &b, alpha: nil)

        let topColor = UIColor(red: r * 0.9 + 0.05, green: g * 0.9 + 0.03, blue: b * 0.9 + 0.05, alpha: 1).cgColor
        let midColor = UIColor(red: r * 0.5 + 0.04, green: g * 0.5 + 0.03, blue: b * 0.5 + 0.06, alpha: 1).cgColor
        let botColor = UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1).cgColor
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [topColor, midColor, botColor] as CFArray, locations: [0, 0.5, 1.0])!
        ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: size.width * 0.3, y: size.height), options: [])

        ctx.saveGState()
        let orbRect = CGRect(x: -size.width * 0.1, y: -size.height * 0.05, width: size.width * 0.9, height: size.height * 0.65)
        let orbGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [UIColor(red: r, green: g, blue: b, alpha: 0.30).cgColor,
                                          UIColor(red: r, green: g, blue: b, alpha: 0.0).cgColor] as CFArray,
                                 locations: [0, 1])!
        ctx.addEllipse(in: orbRect); ctx.clip()
        ctx.drawRadialGradient(orbGrad,
                               startCenter: CGPoint(x: orbRect.midX, y: orbRect.midY), startRadius: 0,
                               endCenter: CGPoint(x: orbRect.midX, y: orbRect.midY),
                               endRadius: max(orbRect.width, orbRect.height) / 2, options: [])
        ctx.restoreGState()

        ctx.setStrokeColor(UIColor(white: 1, alpha: 0.04).cgColor); ctx.setLineWidth(1)
        let step: CGFloat = size.width / 6
        for i in 0...6 { ctx.move(to: CGPoint(x: step * CGFloat(i), y: 0)); ctx.addLine(to: CGPoint(x: step * CGFloat(i), y: size.height)) }
        ctx.strokePath()

        ctx.saveGState()
        let smallOrb = CGRect(x: size.width * 0.55, y: size.height * 0.6, width: size.width * 0.8, height: size.width * 0.8)
        let sg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: [UIColor(red: r * 0.7, green: g * 0.7, blue: b * 0.7, alpha: 0.18).cgColor, UIColor.clear.cgColor] as CFArray,
                            locations: [0, 1])!
        ctx.addEllipse(in: smallOrb); ctx.clip()
        ctx.drawRadialGradient(sg, startCenter: CGPoint(x: smallOrb.midX, y: smallOrb.midY), startRadius: 0,
                               endCenter: CGPoint(x: smallOrb.midX, y: smallOrb.midY), endRadius: max(smallOrb.width, smallOrb.height) / 2, options: [])
        ctx.restoreGState()
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
