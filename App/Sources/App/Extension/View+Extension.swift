import SwiftUI

enum ScaleType {
    case fill
    case fit
}

extension View {
    func applySize(size: CGSize?, autoHeight: Bool = false) -> some View {
        Group {
            if let size = size {
                if autoHeight {
                    self.frame(width: size.width)
                } else {
                    self.frame(width: abs(size.width), height: abs(size.height))
                }
            } else {
                self.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    func applyClip(isCircle: Bool) -> some View {
        Group {
            if isCircle {
                self.clipShape(Circle())
            } else {
                self.clipped()
            }
        }
    }

    func applyScale(type: ScaleType) -> some View {
        Group {
            switch type {
            case .fill:
                self.scaledToFill()
            case .fit:
                self.scaledToFit()
            }
        }
    }

    func applyBorder(isBorder: Bool, color: Color, width: CGFloat, isCircle: Bool, radius: CGFloat) -> some View {
        Group {
            if isBorder {
                if isCircle {
                    self.overlay(Circle().stroke(color, lineWidth: width))
                } else {
                    self.overlay(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: width))
                }
            } else {
                self
            }
        }
    }

    func applyId(id: Int?) -> some View {
        Group {
            if let id = id {
                self.id(id)
            } else {
                self
            }
        }
    }

    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }

    func applyContents<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }

    func shimmer(
        _ isActive: Bool,
        speed: CGFloat = 1,
        colors: [Color] = [],
        cornerRadius: CGFloat = 5
    ) -> some View {
        modifier(ShimmerModifier(
            isActive: isActive,
            speed: speed,
            colors: colors,
            cornerRadius: cornerRadius
        ))
    }

    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = CGSize(width: 900, height: 1600)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}
