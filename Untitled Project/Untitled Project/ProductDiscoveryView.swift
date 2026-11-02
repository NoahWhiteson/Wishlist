import SwiftUI

struct ProductDiscoveryView: View {
    let product: Product

    @State private var selectedNavTab: NavTab = .home
    @State private var saved = false
    @State private var showDetails = false
    @State private var detailsReveal: CGFloat = 0
    @State private var measuredDetailsHeight: CGFloat = 0
    @State private var dragTranslation: CGSize = .zero
    @State private var isSwipeAnimating = false
    @State private var screenWidth: CGFloat = 390

    private let expandSpring = Animation.spring(response: 0.52, dampingFraction: 0.86)
    private let swipeSpring = Animation.interactiveSpring(response: 0.38, dampingFraction: 0.82, blendDuration: 0.12)

    private enum NavTab: CaseIterable {
        case home
        case wishlist
        case profile

        var icon: String {
            switch self {
            case .home: "house.fill"
            case .wishlist: "heart.text.square.fill"
            case .profile: "person.crop.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .home: "Home"
            case .wishlist: "My Wishlist"
            case .profile: "Profile"
            }
        }
    }

    private enum SwipeAction {
        case like
        case dismiss
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WishlistTheme.background

                swipeFeedbackBackground
                    .opacity(detailsReveal < 0.05 ? 1 : 0)

                swipeableCard(screenWidth: geo.size.width)

                topNavScrim(safeAreaTop: geo.safeAreaInsets.top)

                topBar
                    .padding(.top, geo.safeAreaInsets.top + 34)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .onAppear { screenWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, width in
                screenWidth = width
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WishlistTheme.background)
        .preferredColorScheme(.dark)
    }

    private func swipeableCard(screenWidth: CGFloat) -> some View {
        GeometryReader { cardGeo in
            let topInset = cardGeo.safeAreaInsets.top + 88
            let bottomSafeInset = cardGeo.safeAreaInsets.bottom
            let bottomBarHeight: CGFloat = 72 + bottomSafeInset
            let expandedPanelHeight = max(cardGeo.size.height - topInset - bottomBarHeight, 200)
            let isExpanded = detailsReveal > 0.02

            ZStack {
                heroBackground

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    ScrollView(showsIndicators: false) {
                        productInfoContent
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }
                    .scrollDisabled(!isExpanded)
                    .fixedSize(horizontal: false, vertical: !isExpanded)
                    .frame(maxHeight: isExpanded ? expandedPanelHeight : nil, alignment: .bottom)

                    bottomBar(bottomInset: bottomSafeInset)
                }
                .padding(.top, topInset)

                swipeStampOverlay
            }
            .frame(width: cardGeo.size.width, height: cardGeo.size.height)
            .modifier(SwipeCardMorphModifier(progress: swipeMorphProgress))
        }
        .offset(x: dragTranslation.width, y: dragTranslation.height * 0.12)
        .rotationEffect(.degrees(Double(dragTranslation.width / 16)))
        .gesture(cardDragGesture(screenWidth: screenWidth))
        .allowsHitTesting(!isSwipeAnimating)
    }

    private var swipeStampOverlay: some View {
        ZStack {
            swipeStamp(
                title: "NOPE",
                color: .red,
                alignment: .topLeading,
                rotation: 12,
                opacity: nopeStampOpacity
            )

            swipeStamp(
                title: "LIKE",
                color: WishlistTheme.accent,
                alignment: .topTrailing,
                rotation: -12,
                opacity: likeStampOpacity
            )
        }
        .padding(28)
        .allowsHitTesting(false)
    }

    private func swipeStamp(
        title: String,
        color: Color,
        alignment: Alignment,
        rotation: Double,
        opacity: Double
    ) -> some View {
        Text(title)
            .font(.system(size: 34, weight: .heavy))
            .tracking(2)
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color, lineWidth: 4)
            }
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    private var likeStampOpacity: Double {
        Double(min(max((dragTranslation.width - 40) / 100, 0), 1))
    }

    private var nopeStampOpacity: Double {
        Double(min(max((-dragTranslation.width - 40) / 100, 0), 1))
    }

    private var likeBackgroundOpacity: Double {
        guard dragTranslation.width > 0 else { return 0 }
        return swipeRevealProgress(for: dragTranslation.width)
    }

    private var nopeBackgroundOpacity: Double {
        guard dragTranslation.width < 0 else { return 0 }
        return swipeRevealProgress(for: dragTranslation.width)
    }

    private var swipeFeedbackBackground: some View {
        ZStack {
            ZStack {
                Color(red: 0.93, green: 0.18, blue: 0.32)
                Image(systemName: "heart.fill")
                    .font(.system(size: 128, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .scaleEffect(0.72 + (0.28 * likeBackgroundOpacity))
                    .opacity(0.35 + (0.65 * likeBackgroundOpacity))
            }
            .opacity(likeBackgroundOpacity)

            ZStack {
                Color(red: 0.16, green: 0.42, blue: 0.96)
                Image(systemName: "xmark")
                    .font(.system(size: 120, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
                    .scaleEffect(0.72 + (0.28 * nopeBackgroundOpacity))
                    .opacity(0.35 + (0.65 * nopeBackgroundOpacity))
            }
            .opacity(nopeBackgroundOpacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var swipeMorphProgress: CGFloat {
        CGFloat(swipeRevealProgress(for: dragTranslation.width))
    }

    private func swipeRevealProgress(for width: CGFloat) -> Double {
        smoothStep(min(max(abs(width) / 140, 0), 1))
    }

    private func smoothStep(_ t: CGFloat) -> Double {
        let x = Double(min(max(t, 0), 1))
        return x * x * (3 - 2 * x)
    }

    private func cardDragGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard detailsReveal < 0.05, !isSwipeAnimating else { return }
                dragTranslation = value.translation
            }
            .onEnded { value in
                guard detailsReveal < 0.05, !isSwipeAnimating else {
                    withAnimation(swipeSpring) { dragTranslation = .zero }
                    return
                }

                let threshold = screenWidth * 0.28
                let predicted = value.predictedEndTranslation.width

                if value.translation.width > threshold || predicted > 520 {
                    commitSwipe(.like, screenWidth: screenWidth)
                } else if value.translation.width < -threshold || predicted < -520 {
                    commitSwipe(.dismiss, screenWidth: screenWidth)
                } else {
                    withAnimation(swipeSpring) {
                        dragTranslation = .zero
                    }
                }
            }
    }

    private func commitSwipe(_ action: SwipeAction, screenWidth: CGFloat) {
        guard !isSwipeAnimating else { return }
        isSwipeAnimating = true

        switch action {
        case .like:
            WishlistHaptics.success()
        case .dismiss:
            WishlistHaptics.medium()
        }

        let exitX = (action == .like ? 1 : -1) * (screenWidth + 120)

        withAnimation(swipeSpring) {
            dragTranslation = CGSize(width: exitX, height: 36)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            setDetailsExpanded(false)
            saved = action == .like

            withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                dragTranslation = .zero
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isSwipeAnimating = false
            }
        }
    }

    private var heroBackground: some View {
        GeometryReader { geo in
            ZStack {
                Image(product.heroImageName)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(1.02 - (0.02 * detailsReveal))
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                Color.black
                    .opacity(0.58 * detailsReveal)
                    .allowsHitTesting(false)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.12),
                        .init(color: .black.opacity(0.08 + (0.08 * detailsReveal)), location: 0.3),
                        .init(color: .clear, location: 0.45 - (0.13 * detailsReveal)),
                        .init(color: .black.opacity(0.5 + (0.2 * detailsReveal)), location: 0.62),
                        .init(color: .black.opacity(0.82), location: 0.78),
                        .init(color: .black.opacity(0.96), location: 0.92),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    private func topNavScrim(safeAreaTop: CGFloat) -> some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.82), location: 0),
                .init(color: .black.opacity(0.62), location: 0.22),
                .init(color: .black.opacity(0.38), location: 0.48),
                .init(color: .black.opacity(0.12), location: 0.72),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: safeAreaTop + 128)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 0) {
            ForEach(NavTab.allCases, id: \.self) { tab in
                Button {
                    WishlistHaptics.selection()
                    withAnimation(.snappy(duration: 0.22)) {
                        selectedNavTab = tab
                    }
                } label: {
                    Image(systemName: tab.icon)
                        .font(.system(size: 23, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(selectedNavTab == tab ? .white : .white.opacity(0.42))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 6)
    }

    // MARK: - Product info

    private var productInfoContent: some View {
        VStack(alignment: .leading, spacing: 10 + (14 * detailsReveal)) {
            productSummaryHeader

            expandingDetailsSection
        }
    }

    private var expandingDetailsSection: some View {
        expandedDetails
            .background { ViewHeightReader() }
            .onPreferenceChange(DetailsSectionHeightKey.self) { height in
                if height > 0 {
                    measuredDetailsHeight = height
                }
            }
            .frame(height: max(measuredDetailsHeight * detailsReveal, 0), alignment: .top)
            .clipped()
            .allowsHitTesting(detailsReveal > 0.05)
    }

    private func setDetailsExpanded(_ expanded: Bool) {
        withAnimation(expandSpring) {
            showDetails = expanded
            detailsReveal = expanded ? 1 : 0
        }
    }

    private func commitSwipeFromButtons(_ action: SwipeAction) {
        guard detailsReveal < 0.05 else { return }
        commitSwipe(action, screenWidth: screenWidth)
    }

    private var productSummaryHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            if product.isGiftPick {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.caption2)
                    Text("GIFT PICK")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                }
                .foregroundStyle(WishlistTheme.giftGold)
            }

            HStack(alignment: .top, spacing: 12) {
                Text(product.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(detailsReveal > 0.5 ? nil : 3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    WishlistHaptics.light()
                    saved.toggle()
                } label: {
                    Image(systemName: saved ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                Image(systemName: "apple.logo")
                    .font(.caption)
                Text(product.brand)
                    .font(.subheadline)
            }
            .foregroundStyle(WishlistTheme.muted)

            Text(product.descriptor)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(detailsReveal > 0.5 ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)

            Text(product.price)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            FlowLayout(spacing: 8) {
                ForEach(product.quickTags) { tag in
                    TagChip(tag: tag, compact: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            detailBlock(title: "About", body: product.about)

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Why you'll like it")
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(product.highlights, id: \.self) { line in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WishlistTheme.accent)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(WishlistTheme.accent.opacity(0.18)))
                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Tags")
                FlowLayout(spacing: 8) {
                    ForEach(product.detailTags) { tag in
                        TagChip(tag: tag)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Gallery")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(product.galleryImageNames, id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
    }

    private func detailBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(WishlistTheme.muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Bottom bar

    private func bottomBar(bottomInset: CGFloat) -> some View {
        HStack(spacing: 12) {
            Button {
                commitSwipeFromButtons(.dismiss)
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(.white))
            }
            .buttonStyle(.plain)

            Button {
                WishlistHaptics.medium()
                setDetailsExpanded(!showDetails)
            } label: {
                Image(systemName: "info.bubble.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(detailsReveal > 0.5 ? Color.white.opacity(0.28) : Color.white.opacity(0.14))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showDetails ? "Hide product information" : "Show product information")

            Button {
                commitSwipeFromButtons(.like)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(WishlistTheme.accentGradient))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, bottomInset + 10)
    }
}

// MARK: - Tag chip

struct TagChip: View {
    let tag: ProductTag
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tag.systemImage)
                .font(compact ? .caption2 : .caption)
            Text(tag.label)
                .font(compact ? .caption : .subheadline)
                .lineLimit(1)
        }
        .foregroundStyle(tag.emphasized ? WishlistTheme.accentSoft : .white.opacity(0.85))
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 6 : 8)
        .background {
            Capsule().fill(Color.white.opacity(0.1))
        }
    }
}

// MARK: - Flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        return layout(in: width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let limit = max(maxWidth, 1)

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: limit, height: nil))
            if x + size.width > limit, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: limit, height: y + rowHeight), frames)
    }
}

private struct SwipeCardMorphModifier: AnimatableModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: max(24 * progress, 0), style: .continuous))
            .scaleEffect(1 - (0.1 * progress), anchor: .center)
            .shadow(color: .black.opacity(0.35 * progress), radius: 18 * progress, y: 8 * progress)
    }
}

private struct ViewHeightReader: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: DetailsSectionHeightKey.self, value: geo.size.height)
        }
    }
}

private struct DetailsSectionHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ProductDiscoveryView(product: .airPodsPro)
}
