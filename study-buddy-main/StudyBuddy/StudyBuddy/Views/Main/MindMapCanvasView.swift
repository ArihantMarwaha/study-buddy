import SwiftUI

struct MindMapCanvasView: View {
    @Binding var canvasOffset: CGPoint
    @Binding var isDraggingCanvas: Bool
    @Binding var lastDragPosition: CGPoint
    let onDoubleClick: (CGPoint) -> Void
    let zoomScale: CGFloat
    let showGrid: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showGrid {
                    MindMapGridBackground(offset: canvasOffset, zoomScale: zoomScale)
                }
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isDraggingCanvas {
                                        isDraggingCanvas = true
                                        lastDragPosition = value.startLocation
                                    }
                                    let delta = CGPoint(
                                        x: value.location.x - lastDragPosition.x,
                                        y: value.location.y - lastDragPosition.y
                                    )
                                    canvasOffset = CGPoint(
                                        x: canvasOffset.x + delta.x,
                                        y: canvasOffset.y + delta.y
                                    )
                                    lastDragPosition = value.location
                                }
                                .onEnded { _ in
                                    isDraggingCanvas = false
                                }
                        )
                        .onTapGesture(count: 2) { location in
                            onDoubleClick(location)
                        }
                }
                .scaleEffect(zoomScale)
                .animation(.easeInOut(duration: 0.15), value: zoomScale)
            }
        }
    }
}

struct MindMapGridBackground: View {
    let offset: CGPoint
    let zoomScale: CGFloat
    let gridSize: CGFloat = 20
    var body: some View {
        Canvas { context, size in
            let scaledGridSize = gridSize * zoomScale
            let adjustedOffset = CGPoint(
                x: offset.x.truncatingRemainder(dividingBy: scaledGridSize),
                y: offset.y.truncatingRemainder(dividingBy: scaledGridSize)
            )
            let extraLines: CGFloat = 100
            var x = adjustedOffset.x - scaledGridSize * extraLines
            while x < size.width + scaledGridSize * extraLines {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(.gray.opacity(0.3)),
                    lineWidth: 0.5
                )
                x += scaledGridSize
            }
            var y = adjustedOffset.y - scaledGridSize * extraLines
            while y < size.height + scaledGridSize * extraLines {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(.gray.opacity(0.3)),
                    lineWidth: 0.5
                )
                y += scaledGridSize
            }
        }
    }
} 