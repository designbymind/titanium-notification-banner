//
//  TiNotificationbannerModule.swift
//  titanium-notification-banner
//
//  Modernized for scene-based UIKit and iOS 27 compatibility.
//

import UIKit
import TitaniumKit

@objc(TiNotificationbannerModule)
class TiNotificationbannerModule: TiModule {

  public let testProperty: String = "Hello World"

  func moduleGUID() -> String {
    return "cccc9652-8055-43e0-a933-5cc76acd00be"
  }

  override func moduleId() -> String! {
    return "ti.notificationbanner"
  }

  @objc(show:)
  func show(arguments: Array<Any>?) {
    guard let arguments = arguments,
          let params = arguments.first as? [String: Any] else {
      return
    }

    let title = params["title"] as? String
    let subtitle = params["subtitle"] as? String
    let duration = (params["duration"] as? NSNumber)?.doubleValue
    let image = params["image"] as? String
    let titleColor = params["titleColor"]
    let backgroundColor = params["backgroundColor"]
    let minimumHeight = (params["minimumHeight"] as? NSNumber)?.doubleValue ?? 80
    let onClickCallback = params["onClick"] as? KrollCallback

    let resolvedImage = TiUtils.toImage(image, proxy: self)
    let resolvedBackgroundColor = TiUtils.colorValue(backgroundColor)?.color ?? UIColor.black
    let resolvedTextColor = TiUtils.colorValue(titleColor)?.color ?? UIColor.white

    DispatchQueue.main.async {
      let banner = TiNotificationBannerView(
        title: title,
        subtitle: subtitle,
        image: resolvedImage,
        backgroundColor: resolvedBackgroundColor,
        textColor: resolvedTextColor,
        minimumHeight: CGFloat(minimumHeight)
      )

      banner.dismissesOnTap = true
      banner.dismissesOnSwipe = true

      banner.didTapBlock = { [weak self] in
        guard let self = self, let onClickCallback = onClickCallback else { return }
        onClickCallback.call([[:]], thisObject: self)
      }

      banner.show(duration: duration)
    }
  }
}

private final class TiNotificationBannerView: UIView {

  private let backgroundView = UIView()
  private let contentView = UIView()
  private let titleLabel = UILabel()
  private let detailLabel = UILabel()
  private let imageView = UIImageView()
  private let textStack = UIStackView()

  private var hideWorkItem: DispatchWorkItem?
  private var isDismissing = false

  var animationDuration: TimeInterval = 0.4
  var dismissesOnTap = true
  var dismissesOnSwipe = true
  var didTapBlock: (() -> Void)?
  var didDismissBlock: (() -> Void)?

  private let configuredMinimumHeight: CGFloat

  init(title: String?,
       subtitle: String?,
       image: UIImage?,
       backgroundColor: UIColor,
       textColor: UIColor,
       minimumHeight: CGFloat) {

    self.configuredMinimumHeight = max(44, minimumHeight)
    super.init(frame: .zero)

    translatesAutoresizingMaskIntoConstraints = false
    clipsToBounds = false

    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.25
    layer.shadowOffset = CGSize(width: 0, height: 2)
    layer.shadowRadius = 5

    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.backgroundColor = backgroundColor
    backgroundView.alpha = 0.97
    addSubview(backgroundView)

    NSLayoutConstraint.activate([
      backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
      backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
      backgroundView.topAnchor.constraint(equalTo: topAnchor),
      backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    contentView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.addSubview(contentView)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0
    titleLabel.textColor = textColor
    titleLabel.text = title
    titleLabel.isHidden = (title?.isEmpty ?? true)

    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    detailLabel.numberOfLines = 0
    detailLabel.textColor = textColor
    detailLabel.text = subtitle
    detailLabel.isHidden = (subtitle?.isEmpty ?? true)

    textStack.translatesAutoresizingMaskIntoConstraints = false
    textStack.axis = .vertical
    textStack.alignment = .fill
    textStack.distribution = .fill
    textStack.spacing = 0
    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(detailLabel)
    contentView.addSubview(textStack)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.image = image?.withRenderingMode(.alwaysTemplate)
    imageView.tintColor = textColor

    if image != nil {
      contentView.addSubview(imageView)

      NSLayoutConstraint.activate([
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
        imageView.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
        imageView.widthAnchor.constraint(equalToConstant: 25),
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        textStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 15)
      ])
    } else {
      textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
    }

    NSLayoutConstraint.activate([
      textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
      textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      contentView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
    ])

    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))

    let swipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
    swipe.direction = .up
    addGestureRecognizer(swipe)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func didTap(_ recognizer: UITapGestureRecognizer) {
    if dismissesOnTap {
      dismiss()
    }
    didTapBlock?()
  }

  @objc private func didSwipe(_ recognizer: UISwipeGestureRecognizer) {
    if dismissesOnSwipe {
      dismiss()
    }
  }

  func show(duration: TimeInterval?) {
    guard let window = Self.presentationWindow() else {
      print("[TiNotificationBanner]: Could not find an active presentation window. Aborting.")
      return
    }

    window.addSubview(self)

    let safeTop = Self.topSafeAreaInset(for: window)

    NSLayoutConstraint.activate([
      leadingAnchor.constraint(equalTo: window.leadingAnchor),
      trailingAnchor.constraint(equalTo: window.trailingAnchor),
      topAnchor.constraint(equalTo: window.topAnchor),
      heightAnchor.constraint(greaterThanOrEqualToConstant: configuredMinimumHeight),
      contentView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: safeTop)
    ])

    window.layoutIfNeeded()

    let hiddenOffset = -(bounds.height + 8)
    transform = CGAffineTransform(translationX: 0, y: hiddenOffset)

    UIView.animate(
      withDuration: animationDuration,
      delay: 0,
      usingSpringWithDamping: 0.78,
      initialSpringVelocity: 1.25,
      options: [.allowUserInteraction, .beginFromCurrentState],
      animations: {
        self.transform = .identity
      },
      completion: nil
    )

    if let duration = duration, duration > 0 {
      let workItem = DispatchWorkItem { [weak self] in
        self?.dismiss()
      }
      hideWorkItem = workItem
      DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
  }

  func dismiss() {
    guard !isDismissing else { return }
    isDismissing = true
    hideWorkItem?.cancel()
    hideWorkItem = nil

    superview?.layoutIfNeeded()
    let hiddenOffset = -(bounds.height + 8)

    UIView.animate(
      withDuration: animationDuration,
      delay: 0,
      usingSpringWithDamping: 0.9,
      initialSpringVelocity: 1.0,
      options: [.allowUserInteraction, .beginFromCurrentState],
      animations: {
        self.transform = CGAffineTransform(translationX: 0, y: hiddenOffset)
      },
      completion: { _ in
        self.removeFromSuperview()
        self.didDismissBlock?()
      }
    )
  }

  private static func presentationWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .filter { $0.activationState == .foregroundActive }

      for scene in scenes {
        if let keyWindow = scene.windows.first(where: {
          $0.isKeyWindow && !$0.isHidden && $0.alpha > 0 && $0.windowLevel == .normal
        }) {
          return keyWindow
        }

        if let visibleWindow = scene.windows.first(where: {
          !$0.isHidden && $0.alpha > 0 && $0.windowLevel == .normal
        }) {
          return visibleWindow
        }
      }
    }

    return UIApplication.shared.keyWindow
  }

  private static func topSafeAreaInset(for window: UIWindow) -> CGFloat {
    window.layoutIfNeeded()

    let safeAreaTop = window.safeAreaInsets.top
    if safeAreaTop.isFinite && safeAreaTop > 0 {
      return safeAreaTop
    }

    if #available(iOS 13.0, *),
       let statusBarManager = window.windowScene?.statusBarManager,
       !statusBarManager.isStatusBarHidden {
      let statusBarHeight = statusBarManager.statusBarFrame.height
      if statusBarHeight.isFinite && statusBarHeight > 0 {
        return statusBarHeight
      }
    }

    return 0
  }
}
