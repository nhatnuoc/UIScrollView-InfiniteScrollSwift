// MARK: - public methods
extension UIScrollView {
    public enum InfiniteScrollDirection: Int {
        case vertical
        case horizontal
    }
    
    public var infiniteScrollDirection: InfiniteScrollDirection  {
        get {
            return self.infiniteScrollState?.direction ?? .vertical
        }
        set {
            self.infiniteScrollState?.direction = newValue
        }
    }
    public var isAnimatingInfiniteScroll: Bool {
        get {
            return self.infiniteScrollState?.isLoading ?? false
        }
        set {
            self.infiniteScrollState?.isLoading = newValue
        }
    }
    public var infiniteScrollIndicatorView: UIView? {
        get {
            if let v = self.infiniteScrollState?.indicatorView, self.infiniteScrollState?.indicatorView?.superview == nil {
                self.addSubview(v)
            }
            return self.infiniteScrollState?.indicatorView
        }
        set {
            self.infiniteScrollState?.indicatorView = newValue
        }
    }
    public var infiniteScrollIndicatorStyle: UIActivityIndicatorView.Style {
        get {
            return self.infiniteScrollState?.indicatorStyle ?? .gray
        }
        set {
            self.infiniteScrollState?.indicatorStyle = newValue
        }
    }
    public var infiniteScrollIndicatorMargin: CGFloat {
        get {
            return self.infiniteScrollState?.indicatorMargin ?? 0
        }
        set {
            self.infiniteScrollState?.indicatorMargin = newValue
        }
    }
    public var infiniteScrollTriggerOffset: CGFloat {
        get {
            return self.infiniteScrollState?.triggerOffset ?? 0
        }
        set {
            self.infiniteScrollState?.triggerOffset = newValue
        }
    }
    
    public func addInfiniteScroll(_ handler: @escaping ((_ scrollView: UIScrollView) -> Void)) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        let state = InfiniteScrollState()
        state.infiniteScrollHandler = handler
        state.panGestureRecognizer = panGesture
        state.isInitialized = true
        state.contentSizeObservation = self.observe(\.contentSize, options: [.new, .old]) { scrollView, changed in
            if let newValue = changed.newValue {
                scrollView.setContentSize(newValue)
            }
        }
        state.contentOffsetObservation = self.observe(\.contentOffset, options: [.new, .old]) { scrollView, changed in
            if let newValue = changed.newValue {
                scrollView.setContentOffset(newValue)
            }
        }
        self.infiniteScrollState = state
    }

    public func setShouldShowInfiniteScroll(_ handler: @escaping ((_ scrollView: UIScrollView) -> Bool)) {
        let state = self.infiniteScrollState
        state?.shouldShowInfiniteScrollHandler = handler
    }

    public func removeInfiniteScroll() {
        if !(self.infiniteScrollState?.isInitialized ?? false) {
            return
        }
        self.infiniteScrollState?.panGestureRecognizer?.removeTarget(self, action: #selector(handlePanGesture(_:)))
        self.infiniteScrollState?.indicatorView?.removeFromSuperview()
        self.infiniteScrollState?.indicatorView = nil
        self.infiniteScrollState?.infiniteScrollHandler = nil
        self.infiniteScrollState?.isInitialized = false
        self.infiniteScrollState?.contentSizeObservation?.invalidate()
        self.infiniteScrollState?.contentOffsetObservation?.invalidate()
        self.infiniteScrollState?.contentSizeObservation = nil
        self.infiniteScrollState?.contentOffsetObservation = nil
        self.infiniteScrollState = nil
    }

    public func beginInfiniteScroll(_ forceScroll: Bool) {
        self.beginInfiniteScroll(ifNeeded: forceScroll)
    }
    
    public func finishInfiniteScroll() {
        self.finishInfiniteScroll(withCompletion: nil)
    }
}

extension UIScrollView {
    class InfiniteScrollState {
        var isInitialized: Bool = false
        var isLoading: Bool = false
        var direction: InfiniteScrollDirection = .vertical
        lazy var indicatorView: UIView? = {
            let activityIndicator = UIActivityIndicatorView(style: self.indicatorStyle)
            activityIndicator.color = UIColor.black
            return activityIndicator
        }()
        var indicatorStyle: UIActivityIndicatorView.Style = .white
        var scrollToStartWhenFinished: Bool = false
        var extraEndInset: CGFloat = 0
        var indicatorInset: CGFloat = 0
        var indicatorMargin: CGFloat = 11
        var triggerOffset: CGFloat = 0
        var infiniteScrollHandler: ((_ scrollView: UIScrollView) -> Void)!
        var shouldShowInfiniteScrollHandler: ((_ scrollView: UIScrollView) -> Bool)?
        var panGestureRecognizer: UIPanGestureRecognizer?
        var contentSizeObservation, contentOffsetObservation: NSKeyValueObservation?

        fileprivate init() {
            self.isInitialized = true
        }
        
        deinit {
            
        }
    }

    func finishInfiniteScroll(withCompletion completion: ((_ scrollView: UIScrollView) -> Void)?) {
        let state = self.infiniteScrollState
        if state?.isLoading ?? false {
            self.stopAnimatingInfiniteScroll(withCompletion: completion)
        }
    }

    private var infiniteScrollState: InfiniteScrollState? {
        get {
            return infiniteScrollStates[self]
        }
        set {
            infiniteScrollStates[self] = newValue
            if newValue == nil, let index = infiniteScrollStates.firstIndex(where: { $0.key == self as AnyHashable }) {
                infiniteScrollStates.remove(at: index)
            }
        }
    }

    func beginInfiniteScroll(ifNeeded force: Bool) {
        guard let state = self.infiniteScrollState, !state.isLoading else { return }
        if self.shouldShowInfiniteScroll {
            self.startAnimatingInfiniteScroll(force)
//            self.perform(#selector(callInfiniteScrollHandler), with: self, afterDelay: 0.1, inModes: [RunLoop.Mode.default])
//            self.infiniteScrollState?.infiniteScrollHandler?(self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.callInfiniteScrollHandler()
            }
        }
    }

    func startAnimatingInfiniteScroll(_ forceScroll: Bool) {
        let state = self.infiniteScrollState
        let activityIndicator = self.infiniteScrollIndicatorView
        self.positionInfiniteScrollIndicator(with: self.contentSize)
        activityIndicator?.isHidden = false
        if activityIndicator?.responds(to: #selector(UIActivityIndicatorView.startAnimating)) ?? false {
            activityIndicator?.perform(#selector(UIActivityIndicatorView.startAnimating))
        }
        let indicatorInset = self.infiniteIndicatorRowSize
        var contentInset = self.contentInset
        if state?.direction == .vertical {
            contentInset.bottom += indicatorInset
        } else {
            contentInset.right += indicatorInset
        }
        let adjustedContentSize = self.clampContentSizeToFitVisibleBounds(self.contentSize)
        if state?.direction == .vertical {
            let extraBottomInset = adjustedContentSize - self.contentSize.height
            contentInset.bottom += extraBottomInset
            state?.extraEndInset = extraBottomInset
        } else {
            let extraRightInset = adjustedContentSize - self.contentSize.width
            contentInset.right += extraRightInset
            state?.extraEndInset = extraRightInset
        }
        state?.indicatorInset = indicatorInset
        state?.isLoading = true
        state?.scrollToStartWhenFinished = !self.hasContent
        self.setScrollViewContentInset(contentInset, animated: true, completion: { finished in
            if finished {
                self.scrollToInfiniteIndicatorIfNeeded(true, force: forceScroll)
            }
        })
    }

    func stopAnimatingInfiniteScroll(withCompletion handler: ((_ scrollView: UIScrollView) -> Void)?) {
        guard let state = self.infiniteScrollState, let activityIndicator = self.infiniteScrollIndicatorView else { return }
        var contentInset = self.contentInset
        if let tblv = self as? UITableView {
            tblv.forceUpdateTableViewContentSize()
        }
        if state.direction == .vertical {
            contentInset.bottom -= state.indicatorInset
            contentInset.bottom -= state.extraEndInset
        } else {
            contentInset.right -= state.indicatorInset
            contentInset.right -= state.extraEndInset
        }
        state.indicatorInset = 0
        state.extraEndInset = 0
        self.setScrollViewContentInset(contentInset, animated: true, completion: { [weak self] finished in
            guard let self = self else { return }
            if finished {
                if state.scrollToStartWhenFinished {
                    self.scrollToStart()
                } else {
                    self.scrollToInfiniteIndicatorIfNeeded(false, force: false)
                }
            }
            if activityIndicator.responds(to: #selector(UIActivityIndicatorView.stopAnimating)) {
                activityIndicator.perform(#selector(UIActivityIndicatorView.stopAnimating))
            }
            activityIndicator.isHidden = true
            state.isLoading = false
            handler?(self)
        })
    }

    func scrollToStart() {
        let adjustInset = self.nn_adjustedContentInset
        var pt = CGPoint.zero
        if self.infiniteScrollState?.direction == .vertical {
            pt.x = self.contentOffset.x
            pt.y = adjustInset.top * -1
        } else {
            pt.x = adjustInset.left * -1
            pt.y = self.contentOffset.y
        }
        self.setContentOffset(pt, animated: true)
    }

    func scrollToInfiniteIndicatorIfNeeded(_ reveal: Bool, force: Bool) {
        if self.isDragging {
            return
        }
        guard let state = self.infiniteScrollState else { return }
        if !state.isLoading {
            return
        }
        if let tblv = self as? UITableView {
            tblv.forceUpdateTableViewContentSize()
        }
        let contentSize = self.clampContentSizeToFitVisibleBounds(self.contentSize)
        let indicatorRowSize = self.infiniteIndicatorRowSize
        if state.direction == .vertical {
            let minY = contentSize - self.bounds.height + self.originalEndInset
            let maxY = minY + indicatorRowSize
            if (self.contentOffset.y > minY && self.contentOffset.y < maxY) || force {
                if let tblv = self as? UITableView {
                    let numSections = tblv.numberOfSections
                    let lastSection = numSections - 1
                    let numRows = lastSection < 0 ? 0 : tblv.numberOfRows(inSection: lastSection)
                    let lastRow = numRows - 1
                    if lastSection >= 0 && lastRow >= 0 {
                        let indexPath = IndexPath(row: lastRow, section: lastSection)
                        let scrollPos = reveal ? UITableView.ScrollPosition.top : UITableView.ScrollPosition.bottom
                        tblv.scrollToRow(at: indexPath, at: scrollPos, animated: true)
                        return
                    }
                }
                self.setContentOffset(CGPoint(x: self.contentOffset.x, y: reveal ? maxY : minY), animated: true)
            }
        } else {
            let minX = contentSize - self.bounds.width + self.originalEndInset
            let maxX = minX + indicatorRowSize
            if (self.contentOffset.x > minX && self.contentOffset.x < maxX) || force {
                self.setContentOffset(CGPoint(x: reveal ? maxX : minX, y: self.contentOffset.y), animated: true)
            }
        }
    }

    func setScrollViewContentInset(_ contentInset: UIEdgeInsets, animated: Bool, completion: ((_ finished: Bool) -> Void)?) {
        let animations: (() -> Void) = { [weak self] in
            self?.contentInset = contentInset
        }
        if animated {
            UIView.animate(withDuration: 0.35, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: animations, completion: completion)
        } else {
            UIView.performWithoutAnimation(animations)
            completion?(true)
        }
    }

    func positionInfiniteScrollIndicator(with contentSize: CGSize) {
        let activityIndicator = self.infiniteScrollIndicatorView
        let contentLength = self.clampContentSizeToFitVisibleBounds(contentSize)
        let indicatorRowSize = self.infiniteIndicatorRowSize
        let center: CGPoint
        if self.infiniteScrollState?.direction == .vertical {
            center = CGPoint(x: contentSize.width * 0.5, y: contentLength + indicatorRowSize * 0.5)
        } else {
            center = CGPoint(x: contentLength + indicatorRowSize * 0.5, y: contentSize.height * 0.5)
        }
        if let activityIndicatorCenter = activityIndicator?.center, !activityIndicatorCenter.equalTo(center) {
            self.infiniteScrollIndicatorView?.center = center
        }
    }

    func clampContentSizeToFitVisibleBounds(_ contentSize: CGSize) -> CGFloat {
        let adjustContentInset = self.nn_adjustedContentInset
        if self.infiniteScrollState?.direction == .vertical {
            let minHeight = self.bounds.size.height - adjustContentInset.top - self.originalEndInset
            return max(contentSize.height, minHeight)
        }
        let minWidth = self.bounds.size.width - adjustContentInset.left - self.originalEndInset
        return max(contentSize.width, minWidth)
    }

    func scrollViewDidScroll(contentOffset: CGPoint) {
        guard self.isDragging, let state = self.infiniteScrollState else {
            return
        }
        let contentSize = self.clampContentSizeToFitVisibleBounds(self.contentSize)
        if state.direction == .vertical {
            var actionOffset = CGPoint(x: 0, y: contentSize - self.bounds.height + self.originalEndInset)
            actionOffset.y -= state.triggerOffset
            if let velocity = state.panGestureRecognizer?.velocity(in: self), self.contentOffset.y > actionOffset.y && velocity.y <= 0 {
                self.beginInfiniteScroll(ifNeeded: false)
            }
        } else {
            var actionOffset = CGPoint(x: contentSize - self.bounds.width + self.originalEndInset, y: 0)
            actionOffset.x -= state.triggerOffset
            if let velocity = state.panGestureRecognizer?.velocity(in: self), self.contentOffset.x > actionOffset.x && velocity.x <= 0 {
                self.beginInfiniteScroll(ifNeeded: false)
            }
        }
    }

    func setContentSize(_ contentSize: CGSize) {
        if self.infiniteScrollState?.isInitialized ?? false {
            self.positionInfiniteScrollIndicator(with: contentSize)
        }
    }

    func setContentOffset(_ contentOffset: CGPoint) {
        if self.infiniteScrollState?.isInitialized ?? false {
            self.scrollViewDidScroll(contentOffset: contentOffset)
        }
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .ended {
            self.scrollToInfiniteIndicatorIfNeeded(true, force: false)
        }
    }
    
    func callInfiniteScrollHandler() {
        self.infiniteScrollState?.infiniteScrollHandler?(self)
    }
    
    var shouldShowInfiniteScroll: Bool {
        let state = self.infiniteScrollState
        return state?.shouldShowInfiniteScrollHandler?(self) ?? true
    }
    var hasContent: Bool {
        let constant: CGFloat = self is UITableView ? 1 : 0
        if self.infiniteScrollState?.direction == .vertical {
            return self.contentSize.height > constant
        }
        return self.contentSize.width > constant
    }
    var originalEndInset: CGFloat {
        guard let state = self.infiniteScrollState else { return 0 }
        let adjustedContentInset = self.nn_adjustedContentInset
        if state.direction == .vertical {
            return adjustedContentInset.bottom - state.extraEndInset - state.indicatorInset
        }
        return adjustedContentInset.right - state.extraEndInset - state.indicatorInset
    }
    var nn_adjustedContentInset: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.adjustedContentInset
        } else {
            return self.contentInset
        }
    }
    var infiniteIndicatorRowSize: CGFloat {
        guard let state = self.infiniteScrollState, let activityIndicator = state.indicatorView else { return 0 }
        if state.direction == .vertical {
            let indicatorHeight = activityIndicator.bounds.height
            return indicatorHeight + self.infiniteScrollIndicatorMargin * 2
        }
        let indicatorWidth = activityIndicator.bounds.width
        return indicatorWidth + self.infiniteScrollIndicatorMargin * 2
    }
    
}

extension UITableView {
    func forceUpdateTableViewContentSize() {
        self.contentSize = self.sizeThatFits(CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
    }
    
    func forceUpdateWithoutAnimation() {
        UIView.performWithoutAnimation { [weak self] in
            guard let self = self else { return }
            if #available(iOS 11.0, *) {
                self.performBatchUpdates(nil)
            } else {
                self.beginUpdates()
                self.endUpdates()
            }
        }
    }
}

fileprivate var infiniteScrollStates: [AnyHashable: UIScrollView.InfiniteScrollState] = [:] {
    didSet {
        print(infiniteScrollStates.count)
    }
}
