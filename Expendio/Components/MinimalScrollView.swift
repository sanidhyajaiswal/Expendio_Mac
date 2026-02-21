import SwiftUI

struct MinimalScrollView<Content: View>: View {
    let axes: Axis.Set
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var isHovering = false
    @State private var isScrolling = false
    @State private var timer: Timer?

    init(_ axes: Axis.Set = .vertical, @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(axes, showsIndicators: false) {
                content
                    .background(
                        GeometryReader { g -> Color in
                            let newOffset = g.frame(in: .named("MinimalScroll_\(axes.rawValue)")).minY
                            let newHeight = g.size.height
                            DispatchQueue.main.async {
                                if abs(self.offset - newOffset) > 0.5 {
                                    self.offset = newOffset
                                    self.isScrolling = true
                                    self.timer?.invalidate()
                                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            self.isScrolling = false
                                        }
                                    }
                                }
                                if self.contentHeight != newHeight {
                                    self.contentHeight = newHeight
                                }
                            }
                            return Color.clear
                        }
                    )
            }
            .coordinateSpace(name: "MinimalScroll_\(axes.rawValue)")
            .onAppear { self.viewHeight = proxy.size.height }
            .onChange(of: proxy.size.height) { oldViewHeight, newViewHeight in self.viewHeight = newViewHeight }
            .overlay(scrollbarIndicator, alignment: .trailing)
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hover
                    if hover { isScrolling = true } 
                    else {
                        // Let it fade out naturally if not scrolling
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.isScrolling = false
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scrollbarIndicator: some View {
        if axes == .vertical && contentHeight > viewHeight && viewHeight > 0 {
            let proportion = viewHeight / contentHeight
            let barHeight = max(viewHeight * proportion, 20)
            
            let maxScroll = max(contentHeight - viewHeight, 1)
            let scrollProgress = min(max(-offset / maxScroll, 0), 1)
            
            let indicatorRange = viewHeight - barHeight
            let barYOffset = scrollProgress * indicatorRange
            
            Capsule()
                .fill(Color.white.opacity(0.18)) // Minimal Dark style (subtle white track on dark bg)
                .frame(width: 4, height: barHeight)
                .offset(y: barYOffset)
                .padding(.trailing, 4)
                .padding(.vertical, 2)
                .frame(maxHeight: .infinity, alignment: .top)
                .opacity((isHovering || isScrolling) ? 1 : 0)
        }
    }
}
