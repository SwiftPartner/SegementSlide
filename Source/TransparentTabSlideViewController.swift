//
//  TransparentTabSlideViewController.swift
//  SegementSlide
//
//  Created by Jiar on 2018/12/7.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit

///
/// 在 viewWillAppear 中设置 navigationBar 的一般属性
/// 在 viewDidAppear 中再一次重新设置 titleTextAttributes 属性
///
/// 为什么在 viewWillAppear 中设置一般属性，而不在 viewDidLoad 中设置？
/// 当从一个 RecoverViewController(A) 进入另一个 RecoverViewController(B) 时，
/// B 中的 viewDidLoad 会优先于 A 中 viewWillDisappear 调用，这样会导致无法在显示 B 前恢复状态。
///
/// 修改 navigationBar 的 titleTextAttributes，不一定能立刻生效，故改用调整自定义 titleView 的 attributedText。
///
open class TransparentTabSlideViewController: SegementSlideViewController {
    
    public typealias DisplayEmbed<T> = (display: T, embed: T)
    
    private weak var parentScrollView: UIScrollView? = nil
    private var addedShadow: Bool = false
    private var hasEmbed: Bool = false
    private var hasDisplay: Bool = false
    
    private let titleLabel = UILabel()
    private var titleLabelWidthConstraint: NSLayoutConstraint?
    private var titleLabelHeightConstraint: NSLayoutConstraint?
    
    public weak var storedNavigationController: UINavigationController? = nil
    public var storedNavigationBarIsTranslucent: Bool? = nil
    public var storedNavigationBarBarStyle: UIBarStyle? = nil
    public var storedNavigationBarBarTintColor: UIColor? = nil
    public var storedNavigationBarTintColor: UIColor? = nil
    public var storedNavigationBarShadowImage: UIImage? = nil
    public var storedNavigationBarBackgroundImage: UIImage? = nil
    
    public override var headerStickyHeight: CGFloat {
        return innerHeaderHeight-(statusBarHeight+navigationBarHeight)
    }
    public override var contentViewHeight: CGFloat {
        return view.bounds.height-statusBarHeight-navigationBarHeight-switcherHeight
    }
    
    open var isTranslucents: DisplayEmbed<Bool> {
        return (display: true, embed: false)
    }
    
    open var attributedTexts: DisplayEmbed<NSAttributedString?> {
        return (display: nil, embed: nil)
    }
    
    open var barStyles: DisplayEmbed<UIBarStyle> {
        return (display: .black, embed: .default)
    }
    
    open var barTintColors: DisplayEmbed<UIColor?> {
        return (display: nil, embed: .white)
    }
    
    open var tintColors: DisplayEmbed<UIColor> {
        return (display: .white, embed: .black)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupTitleLabel()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTitleLabel()
    }
    
    private func setupTitleLabel() {
        let titleSize = CGSize(width: view.bounds.width-112, height: 44)
        if #available(iOS 11, *) {
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabelWidthConstraint = titleLabel.widthAnchor.constraint(equalToConstant: titleSize.width)
            titleLabelHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: titleSize.height)
            titleLabelWidthConstraint?.isActive = true
            titleLabelHeightConstraint?.isActive = true
        } else {
            titleLabel.bounds = CGRect(origin: .zero, size: titleSize)
        }
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .top
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let titleSize: CGSize
        if let navigationController = navigationController {
            titleSize = CGSize(width: navigationController.navigationBar.bounds.size.width-112, height: navigationController.navigationBar.bounds.size.height)
        } else {
            titleSize = CGSize(width: view.bounds.width-112, height: 44)
        }
        if #available(iOS 11, *) {
            titleLabelWidthConstraint?.isActive = false
            titleLabelHeightConstraint?.isActive = false
            titleLabelWidthConstraint = titleLabel.widthAnchor.constraint(equalToConstant: titleSize.width)
            titleLabelHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: titleSize.height)
            titleLabelWidthConstraint?.isActive = true
            titleLabelHeightConstraint?.isActive = true
        } else {
            titleLabel.bounds = CGRect(origin: .zero, size: titleSize)
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        storeDefaultNavigationBarStyle()
        reloadNavigationBarStyle()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recoverStoredNavigationBarStyle()
    }
    
    open override func scrollViewDidScroll(_ scrollView: UIScrollView, isParent: Bool) {
        guard isParent else { return }
        guard parentScrollView != nil else {
            parentScrollView = scrollView
            return
        }
        updateNavigationBarStyle(scrollView)
    }
    
    open func storeDefaultNavigationBarStyle() {
        storedNavigationController = navigationController
        guard let navigationController = navigationController else { return }
        guard storedNavigationBarIsTranslucent == nil, storedNavigationBarBarStyle == nil,
            storedNavigationBarBarTintColor == nil, storedNavigationBarTintColor == nil,
            storedNavigationBarShadowImage == nil, storedNavigationBarBackgroundImage == nil else { return }
        storedNavigationBarIsTranslucent = navigationController.navigationBar.isTranslucent
        storedNavigationBarBarStyle = navigationController.navigationBar.barStyle
        storedNavigationBarBarTintColor = navigationController.navigationBar.barTintColor
        storedNavigationBarTintColor = navigationController.navigationBar.tintColor
        storedNavigationBarBackgroundImage = navigationController.navigationBar.backgroundImage(for: .default)
        storedNavigationBarShadowImage = navigationController.navigationBar.shadowImage
    }
    
    open func recoverStoredNavigationBarStyle() {
        guard let navigationController = navigationController else { return }
        navigationController.navigationBar.isTranslucent = storedNavigationBarIsTranslucent ?? false
        navigationController.navigationBar.barStyle = storedNavigationBarBarStyle ?? .default
        navigationController.navigationBar.barTintColor = storedNavigationBarBarTintColor
        navigationController.navigationBar.tintColor = storedNavigationBarTintColor
        navigationController.navigationBar.shadowImage = storedNavigationBarShadowImage
        navigationController.navigationBar.setBackgroundImage(storedNavigationBarBackgroundImage, for: .default)
    }
    
    public func reloadNavigationBarStyle() {
        guard let parentScrollView = parentScrollView else { return }
        hasDisplay = false
        hasEmbed = false
        updateNavigationBarStyle(parentScrollView)
    }
    
}

extension TransparentTabSlideViewController {
    
    private func updateNavigationBarStyle(_ scrollView: UIScrollView) {
        guard let navigationController = navigationController else { return }
        if scrollView.contentOffset.y >= headerStickyHeight {
            guard !hasEmbed else { return }
            hasEmbed = true
            hasDisplay = false
            titleLabel.attributedText = attributedTexts.embed
            titleLabel.layer.add(generateFadeAnimation(), forKey: "reloadTitleLabel")
            navigationController.navigationBar.isTranslucent = isTranslucents.embed
            navigationController.navigationBar.barStyle = barStyles.embed
            navigationController.navigationBar.tintColor = tintColors.embed
            navigationController.navigationBar.barTintColor = barTintColors.embed
            navigationController.navigationBar.layer.add(generateFadeAnimation(), forKey: "reloadNavigationBar")
        } else {
            guard !hasDisplay else { return }
            hasDisplay = true
            hasEmbed = false
            titleLabel.attributedText = attributedTexts.display
            titleLabel.layer.add(generateFadeAnimation(), forKey: "reloadTitleLabel")
            navigationController.navigationBar.isTranslucent = isTranslucents.display
            navigationController.navigationBar.barStyle = barStyles.display
            navigationController.navigationBar.tintColor = tintColors.display
            navigationController.navigationBar.barTintColor = barTintColors.display
            navigationController.navigationBar.layer.add(generateFadeAnimation(), forKey: "reloadNavigationBar")
        }
    }
    
    private func generateFadeAnimation() -> CATransition {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = 0.25
        fadeTextAnimation.type = .fade
        return fadeTextAnimation
    }
    
}

extension TransparentTabSlideViewController {
    
    public var statusBarHeight: CGFloat {
        if let navigationController = navigationController {
            return navigationController.navigationBar.frame.origin.y
        } else {
            return 0
        }
    }
    
    public var navigationBarHeight: CGFloat {
        if let navigationController = navigationController {
            return navigationController.navigationBar.frame.height
        } else {
            return 0
        }
    }
    
}
