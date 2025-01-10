import SwiftUI

struct DownwardTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startPoint = CGPoint(x: rect.midX, y: rect.maxY)
        let leftPoint = CGPoint(x: rect.minX, y: rect.minY)
        let rightPoint = CGPoint(x: rect.maxX, y: rect.minY)

        path.move(to: startPoint)
        path.addLine(to: leftPoint)
        path.addLine(to: rightPoint)
        path.addLine(to: startPoint)

        return path
    }
}
