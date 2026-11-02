import SwiftUI

struct ProductDiscoveryView: View {
    let product: Product
    var isBackdrop: Bool = false
    var onSwipeFinished: (() -> Void)? = nil
    var onRefresh: (() -> Void)? = nil
    @Binding var isFeedRefreshing: Bool

    @State private var selectedNavTab: NavTab = .home
    @State private var saved = false
    @State private var showDetails = false
    @State private var detailsReveal: CGFloat = 0
    @State private var measuredDetailsHeight: CGFloat = 0
    @State private var dragTranslation: CGSize = .zero
    @State private var dragLock: DragLock? = nil
    @State private var isSwipeAnimating = false
    @State private var skipProductChangeReset = false
    @State private var pullHapticStep = 0
    @State private var pullOffsetDisplay: CGFloat = 0
    @State private var latchedSwipeFeedback: SwipeAction? = nil
    @State private var screenWidth: CGFloat = 390
    @State private var screenHeight: CGFloat = 844

    init(
        product: Product,
        isBackdrop: Bool = false,
        onSwipeFinished: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        isFeedRefreshing: Binding<Bool> = .constant(false)
    ) {
        self.product = product
        self.isBackdrop = isBackdrop
        self.onSwipeFinished = onSwipeFinished
        self.onRefresh = onRefresh
        _isFeedRefreshing = isFeedRefreshing
    }

    private enum DragLock {
        case horizontal
        case pullDown
        case detailsAdjust
    }

    @State private var detailsRevealAtDragStart: CGFloat = 0

    private let expandSpring = Animation.spring(response: 0.52, dampingFraction: 0.86)
    private let swipeSpring = Animation.interactiveSpring(response: 0.42, dampingFraction: 0.88, blendDuration: 0.15)
    private let swipeExitSpring = Animation.interactiveSpring(response: 0.48, dampingFraction: 0.92, blendDuration: 0.1)
    private let bottomNavBarHeight: CGFloat = 44
    private let actionNavGap: CGFloat = 20
    private let chromeLift: CGFloat = 14
    private var navTabLift: CGFloat { (actionNavGap + 12) / 2 }

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
                if isBackdrop {
                    WishlistTheme.background
                }

                if !isBackdrop {
                    swipeFeedbackBackground
                        .opacity(detailsReveal < 0.05 ? 1 : 0)
                }

                let bottomNavReserve =
                    bottomNavBarHeight + geo.safeAreaInsets.bottom + actionNavGap + 12

                swipeableCard(
                    screenWidth: geo.size.width,
                    bottomNavReserve: bottomNavReserve,
                    safeTop: geo.safeAreaInsets.top
                )
                    .padding(.bottom, bottomNavReserve)
                    .zIndex(1)

                if !isBackdrop {
                    bottomNavScrim(safeAreaBottom: geo.safeAreaInsets.bottom)

                    bottomNavChrome(safeBottom: geo.safeAreaInsets.bottom)
                        .offset(y: -navTabLift)
                        .zIndex(50)
                }
            }
            .onAppear {
                screenWidth = geo.size.width
                screenHeight = geo.size.height
            }
            .onChange(of: geo.size.width) { _, width in
                screenWidth = width
            }
            .onChange(of: geo.size.height) { _, height in
                screenHeight = height
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WishlistTheme.background)
        .preferredColorScheme(.dark)
        .onChange(of: product.id) { _, _ in
            dragLock = nil
            showDetails = false
            detailsReveal = 0

            if skipProductChangeReset {
                return
            }

            dragTranslation = .zero
            isSwipeAnimating = false
            saved = false
            pullHapticStep = 0
            pullOffsetDisplay = 0
            latchedSwipeFeedback = nil
        }
    }

    private func swipeableCard(screenWidth: CGFloat, bottomNavReserve: CGFloat, safeTop: CGFloat) -> some View {
        GeometryReader { cardGeo in
            let topInset = cardGeo.safeAreaInsets.top + 12
            let actionBarHeight: CGFloat = 64
            let bottomBarHeight = actionBarHeight + 8
            let expandedPanelHeight = max(cardGeo.size.height - topInset - bottomBarHeight, 200)
            let summaryClearance: CGFloat = 168

            Group {
                if isBackdrop {
                    ZStack {
                        heroBackground(bottomNavReserve: bottomNavReserve)
                        bottomContentFade(
                            cardHeight: cardGeo.size.height,
                            bottomNavReserve: bottomNavReserve
                        )
                    }
                } else {
                    ZStack(alignment: .top) {
                        WishlistTheme.background

                        pullRefreshHeader(safeTop: safeTop)

                        cardChromeLayer(
                            topInset: topInset,
                            expandedPanelHeight: expandedPanelHeight,
                            summaryClearance: summaryClearance
                        )
                        .opacity(swipeChromeOpacity)

                        heroSwipeLayer(
                            cardGeo: cardGeo,
                            bottomNavReserve: bottomNavReserve
                        )
                    }
                }
            }
            .frame(width: cardGeo.size.width, height: cardGeo.size.height)
            .gesture(isBackdrop ? nil : cardDragGesture(screenWidth: screenWidth))
            .allowsHitTesting(!isBackdrop && !isSwipeAnimating)
        }
    }

    @ViewBuilder
    private func cardChromeLayer(
        topInset: CGFloat,
        expandedPanelHeight: CGFloat,
        summaryClearance: CGFloat
    ) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                productSummaryHeader
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                bottomBar
                    .padding(.bottom, actionNavGap)
            }
            .padding(.top, topInset)
            .offset(y: -chromeLift)

            detailsDrawer(maxHeight: expandedPanelHeight, bottomClearance: summaryClearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func heroSwipeLayer(cardGeo: GeometryProxy, bottomNavReserve: CGFloat) -> some View {
        ZStack {
            heroBackground(bottomNavReserve: bottomNavReserve)

            bottomContentFade(
                cardHeight: cardGeo.size.height,
                bottomNavReserve: bottomNavReserve
            )
        }
        .frame(width: cardGeo.size.width, height: cardGeo.size.height)
        .offset(x: dragTranslation.width, y: heroVerticalNudge)
        .rotationEffect(.degrees(cardRotation))
        .offset(y: pullOffsetDisplay)
        .modifier(SwipeCardMorphModifier(progress: swipeMorphProgress))
    }

    private var swipeChromeOpacity: Double {
        if pullOffsetDisplay > 1 { return 1 }
        if isSwipeAnimating { return 0.06 }
        let width = abs(dragTranslation.width)
        if width < 6 { return 1 }
        return max(0.05, 1 - swipeRevealProgress(for: width) * 0.96)
    }

    private var heroVerticalNudge: CGFloat {
        if pullOffsetDisplay > 0.5 { return 0 }
        return dragTranslation.height * 0.12
    }

    private var likeBackgroundOpacity: Double {
        if isSwipeAnimating, latchedSwipeFeedback == .like { return 1 }
        if isSwipeAnimating, latchedSwipeFeedback == .dismiss { return 0 }
        guard dragTranslation.width > 0 else { return 0 }
        return swipeRevealProgress(for: dragTranslation.width)
    }

    private var nopeBackgroundOpacity: Double {
        if isSwipeAnimating, latchedSwipeFeedback == .dismiss { return 1 }
        if isSwipeAnimating, latchedSwipeFeedback == .like { return 0 }
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

    private func pullRefreshHeader(safeTop: CGFloat) -> some View {
        let ready = pullRefreshProgress >= 0.58
        let showHeader = pullRefreshProgress > 0.01 || isFeedRefreshing

        return HStack(spacing: 8) {
            if isFeedRefreshing || pullRefreshProgress > 0.02 {
                ProgressView()
                    .tint(.white)
            }
            Text(isFeedRefreshing ? "Refreshing…" : (ready ? "Release to refresh" : "Refresh"))
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.top, safeTop + 36)
        .padding(.bottom, 12)
        .background(WishlistTheme.background)
        .allowsHitTesting(false)
        .accessibilityHidden(!showHeader && !isFeedRefreshing)
    }

    private var cardRotation: Double {
        Double(dragTranslation.width / 22)
    }

    private var pullDownLimit: CGFloat {
        screenHeight * 0.20
    }

    private var pullRefreshProgress: Double {
        guard pullOffsetDisplay > 0, pullDownLimit > 0 else { return 0 }
        return min(Double(pullOffsetDisplay / pullDownLimit), 1)
    }

    private func resistedPullDown(raw: CGFloat) -> CGFloat {
        let limit = pullDownLimit
        guard raw > 0, limit > 0 else { return 0 }
        let softCap = limit * (1 - exp(-raw / (limit * 0.75)))
        return min(raw * 0.68, softCap)
    }

    private func updatePullHaptics(for progress: Double) {
        let step = min(4, Int(progress * 4.0) + (progress >= 0.98 ? 1 : 0))
        guard step != pullHapticStep else { return }
        pullHapticStep = step
        switch step {
        case 1:
            WishlistHaptics.selection()
        case 2, 3:
            WishlistHaptics.light()
        case 4...:
            WishlistHaptics.medium()
        default:
            break
        }
    }

    private var swipeMorphProgress: CGFloat {
        guard dragLock != .pullDown else { return 0 }
        return CGFloat(swipeRevealProgress(for: dragTranslation.width))
    }

    private func swipeRevealProgress(for width: CGFloat) -> Double {
        smoothStep(min(max(abs(width) / 140, 0), 1))
    }

    private func resetSwipeInteraction(animated: Bool) {
        pullHapticStep = 0
        pullOffsetDisplay = 0
        latchedSwipeFeedback = nil
        if animated {
            withAnimation(swipeSpring) {
                dragTranslation = .zero
            }
        } else {
            dragTranslation = .zero
        }
    }

    private func smoothStep(_ t: CGFloat) -> Double {
        let x = Double(min(max(t, 0), 1))
        return x * x * (3 - 2 * x)
    }

    private func cardDragGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard !isSwipeAnimating else { return }

                if dragLock == nil {
                    let w = abs(value.translation.width)
                    let h = abs(value.translation.height)
                    if w > 28 || h > 28 {
                        if detailsReveal < 0.05, w > h * 1.65 {
                            dragLock = .horizontal
                            latchedSwipeFeedback = value.translation.width >= 0 ? .like : .dismiss
                        } else if h > w * 1.25, value.translation.height > 12, detailsReveal < 0.05 {
                            dragLock = .pullDown
                        } else if h > w * 1.15, abs(value.translation.height) > 14 {
                            dragLock = .detailsAdjust
                            detailsRevealAtDragStart = detailsReveal
                        }
                    }
                }

                switch dragLock {
                case .horizontal:
                    guard detailsReveal < 0.05 else { return }
                    dragTranslation = CGSize(width: value.translation.width, height: value.translation.height * 0.06)
                    pullOffsetDisplay = 0
                    if value.translation.width > 8 {
                        latchedSwipeFeedback = .like
                    } else if value.translation.width < -8 {
                        latchedSwipeFeedback = .dismiss
                    }
                case .detailsAdjust:
                    let delta = -value.translation.height / 300
                    let next = min(1, max(0, detailsRevealAtDragStart + delta))
                    detailsReveal = next
                    showDetails = next > 0.04
                case .pullDown:
                    guard detailsReveal < 0.05 else { return }
                    latchedSwipeFeedback = nil
                    let resisted = resistedPullDown(raw: max(value.translation.height, 0))
                    dragTranslation = CGSize(width: value.translation.width * 0.12, height: resisted)
                    pullOffsetDisplay = resisted
                    updatePullHaptics(for: pullRefreshProgress)
                case nil:
                    if detailsReveal < 0.05,
                       value.translation.height > max(abs(value.translation.width), 10),
                       value.translation.height > 0 {
                        latchedSwipeFeedback = nil
                        let resisted = resistedPullDown(raw: value.translation.height)
                        pullOffsetDisplay = resisted
                        dragTranslation = CGSize(
                            width: value.translation.width * 0.12,
                            height: resisted
                        )
                    } else {
                        pullOffsetDisplay = 0
                        dragTranslation = value.translation
                    }
                }
            }
            .onEnded { value in
                let endedLock = dragLock
                defer { dragLock = nil }

                if endedLock == .detailsAdjust {
                    withAnimation(expandSpring) {
                        if detailsReveal > 0.32 {
                            detailsReveal = 1
                            showDetails = true
                        } else {
                            detailsReveal = 0
                            showDetails = false
                        }
                    }
                    return
                }

                guard detailsReveal < 0.05, !isSwipeAnimating else {
                    resetSwipeInteraction(animated: true)
                    return
                }

                let threshold = screenWidth * 0.42
                let predictedW = value.predictedEndTranslation.width
                let width = value.translation.width
                let height = value.translation.height
                let resistedEnd = resistedPullDown(raw: max(height, 0))
                let endPullProgress = pullDownLimit > 0 ? min(Double(resistedEnd / pullDownLimit), 1) : 0
                let isPullRelease = endedLock == .pullDown
                    || (height > 28 && height > abs(width) * 1.1)

                if isPullRelease {
                    if endPullProgress >= 0.58 {
                        commitRefresh()
                    } else {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                            pullHapticStep = 0
                            pullOffsetDisplay = 0
                            latchedSwipeFeedback = nil
                            dragTranslation = .zero
                        }
                    }
                    return
                }

                guard endedLock == .horizontal || abs(width) > abs(height) * 1.85 else {
                    resetSwipeInteraction(animated: true)
                    return
                }

                if width > threshold || predictedW > 720 {
                    commitSwipe(.like, screenWidth: screenWidth)
                } else if width < -threshold || predictedW < -720 {
                    commitSwipe(.dismiss, screenWidth: screenWidth)
                } else {
                    resetSwipeInteraction(animated: true)
                }
            }
    }

    private func commitRefresh() {
        guard !isSwipeAnimating, !isFeedRefreshing else { return }
        WishlistHaptics.success()
        onRefresh?()
        pullHapticStep = 0

        withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
            dragTranslation = .zero
            pullOffsetDisplay = 0
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

        let direction: CGFloat = action == .like ? 1 : -1
        latchedSwipeFeedback = action
        let exitX = direction * (screenWidth * 1.35)
        let cardExitSpring = Animation.spring(response: 0.44, dampingFraction: 0.92)
        let cardEnterSpring = Animation.spring(response: 0.5, dampingFraction: 0.9)

        withAnimation(cardExitSpring) {
            dragTranslation = CGSize(width: exitX, height: 12)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            setDetailsExpanded(false)
            saved = action == .like

            skipProductChangeReset = true
            let enterX = -direction * (screenWidth * 1.08)
            dragTranslation = CGSize(width: enterX, height: 0)

            onSwipeFinished?()

            withAnimation(cardEnterSpring) {
                dragTranslation = .zero
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                skipProductChangeReset = false
                isSwipeAnimating = false
                latchedSwipeFeedback = nil
            }
        }
    }

    private func heroBackground(bottomNavReserve: CGFloat) -> some View {
        GeometryReader { geo in
            let heroHeight = max(geo.size.height - bottomNavReserve * 0.35, geo.size.height * 0.88)

            ZStack {
                ProductImageView(source: product.heroImage, highQuality: true)
                    .scaledToFill()
                    .frame(width: geo.size.width, height: heroHeight)
                    .scaleEffect(1 - (0.02 * detailsReveal))
                    .frame(width: geo.size.width, height: heroHeight, alignment: .top)
                    .clipped()

                Color.black
                    .opacity(0.58 * detailsReveal)
                    .allowsHitTesting(false)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.2),
                        .init(color: .black.opacity(0.06 + (0.08 * detailsReveal)), location: 0.42),
                        .init(color: .black.opacity(0.22 + (0.12 * detailsReveal)), location: 0.58),
                        .init(color: .clear, location: 0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: heroHeight, alignment: .top)
                .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    private func bottomContentFade(cardHeight: CGFloat, bottomNavReserve: CGFloat) -> some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black.opacity(0.08), location: 0.22),
                .init(color: .black.opacity(0.32), location: 0.48),
                .init(color: .black.opacity(0.62), location: 0.68),
                .init(color: .black.opacity(0.86), location: 0.84),
                .init(color: .black, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: min(cardHeight * 0.58, 460) + bottomNavReserve * 0.25)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }

    private func bottomNavScrim(safeAreaBottom: CGFloat) -> some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black.opacity(0.2), location: 0.35),
                .init(color: .black.opacity(0.55), location: 0.65),
                .init(color: .black.opacity(0.88), location: 0.88),
                .init(color: .black, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: safeAreaBottom + bottomNavBarHeight + 96)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }

    // MARK: - Bottom tab bar

    private func bottomNavChrome(safeBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            bottomNavBar
                .padding(.top, 8)
                .padding(.bottom, safeBottom + 8)
        }
        .frame(maxWidth: .infinity)
        .background(WishlistTheme.background)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var bottomNavBar: some View {
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
                        .frame(height: bottomNavBarHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Product info

    private func detailsDrawer(maxHeight: CGFloat, bottomClearance: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            expandedDetails
                .background { ViewHeightReader() }
        }
        .onPreferenceChange(DetailsSectionHeightKey.self) { height in
            if height > 0 {
                measuredDetailsHeight = height
            }
        }
        .frame(maxHeight: max(measuredDetailsHeight, maxHeight * 0.72) * detailsReveal, alignment: .bottom)
        .clipped()
        .padding(.horizontal, 20)
        .padding(.bottom, bottomClearance)
        .allowsHitTesting(detailsReveal > 0.08)
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
                    .lineLimit(3)
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
                .lineLimit(2)
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
                        ForEach(Array(product.galleryImages.enumerated()), id: \.offset) { _, source in
                            ProductImageView(source: source, highQuality: true)
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

    private var bottomBar: some View {
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
        .padding(.top, 4)
        .padding(.bottom, 4)
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
            .scaleEffect(1 - (0.08 * progress), anchor: .center)
            .shadow(color: .black.opacity(0.3 * progress), radius: 16 * progress, y: 7 * progress)
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
