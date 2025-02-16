import UIKit

protocol TTDBottomPagerDelegate: class {
    func pagerScrollViewDidScroll(_ scrollView: UIScrollView)
    func pagerDidSelectController(_ vc: UIViewController)
}
open class TTDBottomPager: UIViewController, UIScrollViewDelegate {
    
    weak var delegate: TTDBottomPagerDelegate?
    var controllers = [UIViewController]() { didSet { reload() } }
    
    var v = TTDBottomPagerView()
    
    var currentPage = 0
    
    var currentController: UIViewController {
        return controllers[currentPage]
    }
    
    override open func loadView() {
        v.scrollView.contentInsetAdjustmentBehavior = .never
        v.scrollView.delegate = self
        view = v
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.pagerScrollViewDidScroll(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !v.header.menuItems.isEmpty {
            let menuIndex = (targetContentOffset.pointee.x + v.frame.size.width) / v.frame.size.width
            let selectedIndex = Int(round(menuIndex)) - 1
            if selectedIndex != currentPage {
                selectPage(selectedIndex)
            }
        }
    }
    
    func reload() {
        let viewWidth: CGFloat = UIScreen.main.bounds.width
        for (index, c) in controllers.enumerated() {
            c.willMove(toParent: self)
            addChild(c)
            let x: CGFloat = CGFloat(index) * viewWidth
            c.view.translatesAutoresizingMaskIntoConstraints = false
            v.scrollView.addSubview(c.view)
            NSLayoutConstraint.activate([
                c.view.heightAnchor.constraint(equalTo: v.scrollView.heightAnchor),
                c.view.widthAnchor.constraint(equalToConstant: viewWidth),
                c.view.topAnchor.constraint(equalTo: v.scrollView.topAnchor),
                c.view.leadingAnchor.constraint(equalTo: v.scrollView.leadingAnchor, constant: x)
            ])
            c.didMove(toParent: self)
        }
        
        let scrollableWidth: CGFloat = CGFloat(controllers.count) * CGFloat(viewWidth)
        v.scrollView.contentSize = CGSize(width: scrollableWidth, height: 0)
        
        // Build headers
        for (index, c) in controllers.enumerated() {
            let menuItem = TTDImageMenuItem()
            menuItem.selectedImage = c.tabBarItem.selectedImage
            menuItem.unselectedImage = c.tabBarItem.image
            menuItem.button.tag = index
            menuItem.button.addTarget(self,
                                      action: #selector(tabTapped(_:)),
                                      for: .touchUpInside)
            v.header.menuItems.append(menuItem)
        }
        
        let currentMenuItem = v.header.menuItems[0]
        currentMenuItem.select()
        v.header.refreshMenuItems()
    }
    
    @objc
    func tabTapped(_ b: UIButton) {
        showPage(b.tag)
    }
    
    func showPage(_ page: Int, animated: Bool = true) {
        let x = CGFloat(page) * UIScreen.main.bounds.width
        v.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
        selectPage(page)
    }

    func selectPage(_ page: Int) {
        guard page != currentPage && page >= 0 && page < controllers.count else {
            return
        }
        currentPage = page
        //select menu item and deselect others
        for (i, mi) in v.header.menuItems.enumerated() {
            if (i == page) {
                mi.select()
            } else {
                mi.deselect()
            }
        }
        delegate?.pagerDidSelectController(controllers[page])
    }
    
    func startOnPage(_ page: Int) {
        currentPage = page
        let x = CGFloat(page) * UIScreen.main.bounds.width
        v.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
        //select menut item and deselect others
        for mi in v.header.menuItems {
            mi.deselect()
        }
        let currentMenuItem = v.header.menuItems[page]
        currentMenuItem.select()
    }
}
