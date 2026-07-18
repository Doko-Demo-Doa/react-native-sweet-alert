//
//  SweetAlert.swift
//  react-native-sweet-alert
//

import Foundation
import UIKit
import QuartzCore

enum AlertStyle {
  case success, error, warning, none
  case progress
}

/// Renders the `success`/`error`/`warning`/`normal`/`progress` alert card.
///
/// Named `SweetAlertView` (not `SweetAlert`) to avoid colliding with the
/// Objective-C++ TurboModule class of the same conceptual name, which the
/// Swift compiler would otherwise refuse to disambiguate within one module.
open class SweetAlertView: UIViewController {
  private let kBackgroundTransparency: CGFloat = 0.7
  private let kHeightMargin: CGFloat = 10.0
  private let kTopMargin: CGFloat = 20.0
  private let kWidthMargin: CGFloat = 10.0
  private let kAnimatedViewHeight: CGFloat = 70.0
  private let kMaxHeight: CGFloat = 300.0
  private var kContentWidth: CGFloat = 300.0
  private let kButtonHeight: CGFloat = 35.0
  private var textViewHeight: CGFloat = 90.0
  private let kTitleHeight: CGFloat = 30.0
  private let kFont = "Helvetica"

  private var strongSelf: SweetAlertView?
  private var contentView = UIView()
  private var titleLabel = UILabel()
  private var buttons: [UIButton] = []
  private var animatedView: AnimatableView?
  private var subTitleTextView = UITextView()
  private var userAction: ((_ isOtherButton: Bool) -> Void)?
  private var cancellable = false

  private static var current: SweetAlertView?

  init() {
    super.init(nibName: nil, bundle: nil)
    view.frame = UIScreen.main.bounds
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    view.backgroundColor = UIColor(white: 0, alpha: kBackgroundTransparency)
    view.addSubview(contentView)
    strongSelf = self
  }

  required public init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static var cardBackgroundColor: UIColor {
    UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1.0) : .white }
  }

  private static var cardBorderColor: UIColor {
    UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.3, alpha: 1.0) : .colorFromRGB(0xCCCCCC) }
  }

  private static var titleColor: UIColor {
    UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.95, alpha: 1.0) : .colorFromRGB(0x575757) }
  }

  private static var subTitleColor: UIColor {
    UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.75, alpha: 1.0) : .colorFromRGB(0x797979) }
  }

  private func setupContentView() {
    contentView.layer.cornerRadius = 5.0
    contentView.layer.masksToBounds = true
    contentView.layer.borderWidth = 0.5
    contentView.backgroundColor = Self.cardBackgroundColor
    contentView.layer.borderColor = Self.cardBorderColor.cgColor
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleTextView)
    view.addSubview(contentView)

    if cancellable {
      let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
      view.addGestureRecognizer(tap)
    }
  }

  @objc private func backgroundTapped(_ recognizer: UITapGestureRecognizer) {
    let location = recognizer.location(in: view)
    if !contentView.frame.contains(location) {
      closeAlert(-1)
    }
  }

  private func setupTitleLabel() {
    titleLabel.text = ""
    titleLabel.numberOfLines = 1
    titleLabel.textAlignment = .center
    titleLabel.font = UIFont(name: kFont, size: 25)
    titleLabel.textColor = Self.titleColor
  }

  private func setupSubtitleTextView() {
    subTitleTextView.text = ""
    subTitleTextView.textAlignment = .center
    subTitleTextView.font = UIFont(name: kFont, size: 16)
    subTitleTextView.textColor = Self.subTitleColor
    subTitleTextView.isEditable = false
  }

  private func resizeAndRelayout() {
    let mainScreenBounds = UIScreen.main.bounds
    view.frame.size = mainScreenBounds.size
    let x: CGFloat = kWidthMargin
    var y: CGFloat = kTopMargin
    let width: CGFloat = kContentWidth - (kWidthMargin * 2)

    if let animatedView {
      animatedView.frame = CGRect(
        x: (kContentWidth - kAnimatedViewHeight) / 2.0, y: y,
        width: kAnimatedViewHeight, height: kAnimatedViewHeight
      )
      contentView.addSubview(animatedView)
      y += kAnimatedViewHeight + kHeightMargin
    }

    if titleLabel.text?.isEmpty == false {
      titleLabel.frame = CGRect(x: x, y: y, width: width, height: kTitleHeight)
      contentView.addSubview(titleLabel)
      y += kTitleHeight + kHeightMargin
    }

    if subTitleTextView.text.isEmpty == false {
      let subtitleString = subTitleTextView.text as NSString
      let rect = subtitleString.boundingRect(
        with: CGSize(width: width, height: 0.0),
        options: .usesLineFragmentOrigin,
        attributes: [.font: subTitleTextView.font as Any],
        context: nil
      )
      textViewHeight = ceil(rect.size.height) + 10.0
      subTitleTextView.frame = CGRect(x: x, y: y, width: width, height: textViewHeight)
      contentView.addSubview(subTitleTextView)
      y += textViewHeight + kHeightMargin
    }

    guard !buttons.isEmpty else {
      y += kHeightMargin
      layoutContent(width: y, mainScreenBounds: mainScreenBounds)
      return
    }

    var buttonRect: [CGRect] = []
    for button in buttons {
      let string = (button.title(for: .normal) ?? "") as NSString
      buttonRect.append(
        string.boundingRect(
          with: CGSize(width: width, height: 0.0),
          options: .usesLineFragmentOrigin,
          attributes: [.font: button.titleLabel?.font as Any],
          context: nil
        )
      )
    }

    let totalWidth: CGFloat = buttons.count == 2
      ? buttonRect[0].size.width + buttonRect[1].size.width + kWidthMargin + 40.0
      : buttonRect[0].size.width + 20.0
    y += kHeightMargin
    var buttonX = (kContentWidth - totalWidth) / 2.0
    for i in 0..<buttons.count {
      buttons[i].frame = CGRect(
        x: buttonX, y: y,
        width: buttonRect[i].size.width + 20.0, height: buttonRect[i].size.height + 10.0
      )
      buttonX = buttons[i].frame.origin.x + kWidthMargin + buttonRect[i].size.width + 20.0
      buttons[i].layer.cornerRadius = 5.0
      contentView.addSubview(buttons[i])
      buttons[i].addTarget(self, action: #selector(pressed(_:)), for: .touchUpInside)
    }
    y += kHeightMargin + buttonRect[0].size.height + 10.0
    if y > kMaxHeight {
      let diff = y - kMaxHeight
      let sFrame = subTitleTextView.frame
      subTitleTextView.frame = CGRect(x: sFrame.origin.x, y: sFrame.origin.y, width: sFrame.width, height: sFrame.height - diff)
      for button in buttons {
        let bFrame = button.frame
        button.frame = CGRect(x: bFrame.origin.x, y: bFrame.origin.y - diff, width: bFrame.width, height: bFrame.height)
      }
      y = kMaxHeight
    }

    layoutContent(width: y, mainScreenBounds: mainScreenBounds)
  }

  private func layoutContent(width y: CGFloat, mainScreenBounds: CGRect) {
    contentView.frame = CGRect(
      x: (mainScreenBounds.size.width - kContentWidth) / 2.0,
      y: (mainScreenBounds.size.height - y) / 2.0,
      width: kContentWidth, height: y
    )
    contentView.clipsToBounds = true
  }

  @objc private func pressed(_ sender: UIButton!) {
    closeAlert(sender.tag)
  }

  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    resizeAndRelayout()
  }

  private func closeAlert(_ buttonIndex: Int) {
    if let userAction {
      let isOtherButton = buttonIndex == 0
      Self.shouldNotAnimate = true
      userAction(isOtherButton)
      Self.shouldNotAnimate = false
    }

    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut) {
      self.view.alpha = 0.0
    } completion: { _ in
      self.view.removeFromSuperview()
      self.cleanUpAlert()
      if Self.current === self {
        Self.current = nil
      }
      self.strongSelf = nil
    }
  }

  private func cleanUpAlert() {
    animatedView?.removeFromSuperview()
    animatedView = nil
    contentView.removeFromSuperview()
    contentView = UIView()
  }

  /// Sets the progress (0-100) of a currently shown `.progress` style alert. No-op otherwise.
  static func updateProgress(_ progress: Double) {
    (current?.animatedView as? ProgressAnimatedView)?.progress = progress
  }

  /// Dismisses the currently shown alert, if any, resolving with `confirmed: false`.
  static func dismissCurrent() {
    current?.closeAlert(-1)
  }

  // swiftlint:disable:next function_parameter_count
  static func present(
    title: String,
    subTitle: String?,
    style: AlertStyle,
    confirmButtonTitle: String?,
    confirmButtonColor: UIColor?,
    otherButtonTitle: String?,
    otherButtonColor: UIColor?,
    cancellable: Bool,
    progress: Double?,
    progressBarColor: UIColor?,
    progressBarWidth: Double?,
    action: @escaping (_ isOtherButton: Bool) -> Void
  ) {
    current?.closeAlert(-1)

    let alert = SweetAlertView()
    current = alert
    alert.cancellable = cancellable
    alert.userAction = action

    guard let window = UIApplication.shared.connectedScenes
      .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
      .first
    else {
      action(false)
      return
    }

    window.addSubview(alert.view)
    window.bringSubviewToFront(alert.view)
    alert.view.frame = window.bounds
    alert.setupContentView()
    alert.setupTitleLabel()
    alert.setupSubtitleTextView()

    switch style {
    case .success:
      alert.animatedView = SuccessAnimatedView()
    case .error:
      alert.animatedView = CancelAnimatedView()
    case .warning:
      alert.animatedView = InfoAnimatedView()
    case .progress:
      let progressView = ProgressAnimatedView()
      progressView.progress = progress
      if let progressBarColor {
        progressView.barColor = progressBarColor
      }
      if let progressBarWidth {
        progressView.barWidth = CGFloat(progressBarWidth)
      }
      alert.animatedView = progressView
    case .none:
      alert.animatedView = nil
    }

    alert.titleLabel.text = title
    if let subTitle {
      alert.subTitleTextView.text = subTitle
    }

    alert.buttons = []
    if let confirmButtonTitle, !confirmButtonTitle.isEmpty {
      let button = UIButton(type: .custom)
      button.setTitle(confirmButtonTitle, for: .normal)
      button.backgroundColor = confirmButtonColor ?? .colorFromRGB(0xAEDEF4)
      button.isUserInteractionEnabled = true
      button.tag = 0
      alert.buttons.append(button)
    }

    if let otherButtonTitle, !otherButtonTitle.isEmpty {
      let button = UIButton(type: .custom)
      button.setTitle(otherButtonTitle, for: .normal)
      button.backgroundColor = otherButtonColor ?? .colorFromRGB(0xF27474)
      button.tag = 1
      alert.buttons.append(button)
    }

    alert.resizeAndRelayout()
    if Self.shouldNotAnimate {
      alert.animatedView?.animate()
    } else {
      alert.animateAlert()
    }
  }

  private func animateAlert() {
    view.alpha = 0
    UIView.animate(withDuration: 0.1) { self.view.alpha = 1.0 }

    let previousTransform = contentView.transform
    contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
    UIView.animate(withDuration: 0.2) {
      self.contentView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 0.0)
    } completion: { _ in
      UIView.animate(withDuration: 0.1) {
        self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
      } completion: { _ in
        UIView.animate(withDuration: 0.1) {
          self.contentView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 0.0)
          self.animatedView?.animate()
        } completion: { _ in
          self.contentView.transform = previousTransform
        }
      }
    }
  }

  private static var shouldNotAnimate = false
}

// MARK: - Animatable Views

class AnimatableView: UIView {
  func animate() {
    // Overridden by subclasses.
  }
}

class CancelAnimatedView: AnimatableView {
  private var circleLayer = CAShapeLayer()
  private var crossPathLayer = CAShapeLayer()

  override required init(frame: CGRect) {
    super.init(frame: frame)
    setupLayers()
    var t = CATransform3DIdentity
    t.m34 = 1.0 / -500.0
    t = CATransform3DRotate(t, .pi / 2, 1, 0, 0)
    circleLayer.transform = t
    crossPathLayer.opacity = 0.0
  }

  override func layoutSubviews() {
    setupLayers()
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var outlineCircle: CGPath {
    let path = UIBezierPath()
    path.addArc(
      withCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.width / 2.0),
      radius: frame.size.width / 2.0, startAngle: 0, endAngle: .pi * 2, clockwise: false
    )
    return path.cgPath
  }

  private var crossPath: CGPath {
    let path = UIBezierPath()
    let factor: CGFloat = frame.size.width / 5.0
    path.move(to: CGPoint(x: frame.size.height / 2.0 - factor, y: frame.size.height / 2.0 - factor))
    path.addLine(to: CGPoint(x: frame.size.height / 2.0 + factor, y: frame.size.height / 2.0 + factor))
    path.move(to: CGPoint(x: frame.size.height / 2.0 + factor, y: frame.size.height / 2.0 - factor))
    path.addLine(to: CGPoint(x: frame.size.height / 2.0 - factor, y: frame.size.height / 2.0 + factor))
    return path.cgPath
  }

  private func setupLayers() {
    circleLayer.path = outlineCircle
    circleLayer.fillColor = UIColor.clear.cgColor
    circleLayer.strokeColor = UIColor.colorFromRGB(0xF27474).cgColor
    circleLayer.lineCap = .round
    circleLayer.lineWidth = 4
    circleLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    circleLayer.position = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
    layer.addSublayer(circleLayer)

    crossPathLayer.path = crossPath
    crossPathLayer.fillColor = UIColor.clear.cgColor
    crossPathLayer.strokeColor = UIColor.colorFromRGB(0xF27474).cgColor
    crossPathLayer.lineCap = .round
    crossPathLayer.lineWidth = 4
    crossPathLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    crossPathLayer.position = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
    layer.addSublayer(crossPathLayer)
  }

  override func animate() {
    var t = CATransform3DIdentity
    t.m34 = 1.0 / -500.0
    t = CATransform3DRotate(t, .pi / 2, 1, 0, 0)

    var t2 = CATransform3DIdentity
    t2.m34 = 1.0 / -500.0
    t2 = CATransform3DRotate(t2, -.pi, 1, 0, 0)

    let time = 0.3
    let animation = CABasicAnimation(keyPath: "transform")
    animation.duration = time
    animation.fromValue = NSValue(caTransform3D: t)
    animation.toValue = NSValue(caTransform3D: t2)
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    circleLayer.add(animation, forKey: "transform")

    var scale = CATransform3DIdentity
    scale = CATransform3DScale(scale, 0.3, 0.3, 0)

    let crossAnimation = CABasicAnimation(keyPath: "transform")
    crossAnimation.duration = 0.3
    crossAnimation.beginTime = CACurrentMediaTime() + time
    crossAnimation.fromValue = NSValue(caTransform3D: scale)
    crossAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.8, 0.7, 2.0)
    crossAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
    crossPathLayer.add(crossAnimation, forKey: "scale")

    let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
    fadeInAnimation.duration = 0.3
    fadeInAnimation.beginTime = CACurrentMediaTime() + time
    fadeInAnimation.fromValue = 0.3
    fadeInAnimation.toValue = 1.0
    fadeInAnimation.isRemovedOnCompletion = false
    fadeInAnimation.fillMode = .forwards
    crossPathLayer.add(fadeInAnimation, forKey: "opacity")
  }
}

class InfoAnimatedView: AnimatableView {
  private var circleLayer = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayers()
  }

  override func layoutSubviews() {
    setupLayers()
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var outlineCircle: CGPath {
    let path = UIBezierPath()
    path.addArc(
      withCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.width / 2.0),
      radius: frame.size.width / 2.0, startAngle: 0, endAngle: .pi * 2, clockwise: false
    )
    let factor: CGFloat = frame.size.width / 1.5
    path.move(to: CGPoint(x: frame.size.width / 2.0, y: 15.0))
    path.addLine(to: CGPoint(x: frame.size.width / 2.0, y: factor))
    path.move(to: CGPoint(x: frame.size.width / 2.0, y: factor + 10.0))
    path.addArc(
      withCenter: CGPoint(x: frame.size.width / 2.0, y: factor + 10.0),
      radius: 1.0, startAngle: 0, endAngle: .pi * 2, clockwise: true
    )
    return path.cgPath
  }

  private func setupLayers() {
    circleLayer.path = outlineCircle
    circleLayer.fillColor = UIColor.clear.cgColor
    circleLayer.strokeColor = UIColor.colorFromRGB(0xF8D486).cgColor
    circleLayer.lineCap = .round
    circleLayer.lineWidth = 4
    circleLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    circleLayer.position = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
    layer.addSublayer(circleLayer)
  }

  override func animate() {
    let colorAnimation = CABasicAnimation(keyPath: "strokeColor")
    colorAnimation.duration = 1.0
    colorAnimation.repeatCount = .greatestFiniteMagnitude
    colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    colorAnimation.autoreverses = true
    colorAnimation.fromValue = UIColor.colorFromRGB(0xF7D58B).cgColor
    colorAnimation.toValue = UIColor.colorFromRGB(0xF2A665).cgColor
    circleLayer.add(colorAnimation, forKey: "strokeColor")
  }
}

class SuccessAnimatedView: AnimatableView {
  private var circleLayer = CAShapeLayer()
  private var outlineLayer = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayers()
    circleLayer.strokeStart = 0.0
    circleLayer.strokeEnd = 0.0
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    setupLayers()
  }

  private var outlineCircle: CGPath {
    let path = UIBezierPath()
    path.addArc(
      withCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0),
      radius: frame.size.width / 2.0, startAngle: 0, endAngle: .pi * 2, clockwise: false
    )
    return path.cgPath
  }

  private var path: CGPath {
    let path = UIBezierPath()
    let startAngle: CGFloat = (60 / 180.0) * .pi
    let endAngle: CGFloat = (200 / 180.0) * .pi
    path.addArc(
      withCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0),
      radius: frame.size.width / 2.0, startAngle: startAngle, endAngle: endAngle, clockwise: false
    )
    path.addLine(to: CGPoint(x: 36.0 - 10.0, y: 60.0 - 10.0))
    path.addLine(to: CGPoint(x: 85.0 - 20.0, y: 30.0 - 20.0))
    return path.cgPath
  }

  private func setupLayers() {
    outlineLayer.position = .zero
    outlineLayer.path = outlineCircle
    outlineLayer.fillColor = UIColor.clear.cgColor
    outlineLayer.strokeColor = UIColor(red: 150.0 / 255.0, green: 216.0 / 255.0, blue: 115.0 / 255.0, alpha: 1.0).cgColor
    outlineLayer.lineCap = .round
    outlineLayer.lineWidth = 4
    outlineLayer.opacity = 0.1
    layer.addSublayer(outlineLayer)

    circleLayer.position = .zero
    circleLayer.path = path
    circleLayer.fillColor = UIColor.clear.cgColor
    circleLayer.strokeColor = UIColor(red: 150.0 / 255.0, green: 216.0 / 255.0, blue: 115.0 / 255.0, alpha: 1.0).cgColor
    circleLayer.lineCap = .round
    circleLayer.lineWidth = 4
    circleLayer.actions = ["strokeStart": NSNull(), "strokeEnd": NSNull(), "transform": NSNull()]
    layer.addSublayer(circleLayer)
  }

  override func animate() {
    let strokeStart = CABasicAnimation(keyPath: "strokeStart")
    let strokeEnd = CABasicAnimation(keyPath: "strokeEnd")
    let factor = 0.045
    strokeEnd.fromValue = 0.00
    strokeEnd.toValue = 0.93
    strokeEnd.duration = 10.0 * factor
    let timing = CAMediaTimingFunction(controlPoints: 0.3, 0.6, 0.8, 1.2)
    strokeEnd.timingFunction = timing

    strokeStart.fromValue = 0.0
    strokeStart.toValue = 0.68
    strokeStart.duration = 7.0 * factor
    strokeStart.beginTime = CACurrentMediaTime() + 3.0 * factor
    strokeStart.fillMode = .backwards
    strokeStart.timingFunction = timing
    circleLayer.strokeStart = 0.68
    circleLayer.strokeEnd = 0.93
    circleLayer.add(strokeEnd, forKey: "strokeEnd")
    circleLayer.add(strokeStart, forKey: "strokeStart")
  }
}

/// Renders a determinate arc (0-100) when `progress` is set, or an indeterminate
/// spinning arc otherwise. The old iOS implementation had no `progress` style at all.
class ProgressAnimatedView: AnimatableView {
  private let arcLayer = CAShapeLayer()
  var barColor: UIColor = .colorFromRGB(0x8CC152) {
    didSet { arcLayer.strokeColor = barColor.cgColor }
  }
  var barWidth: CGFloat = 4 {
    didSet { arcLayer.lineWidth = barWidth }
  }
  var progress: Double? {
    didSet { updateArc() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayers()
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    setupLayers()
    updateArc()
  }

  private func setupLayers() {
    let path = UIBezierPath(
      arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0),
      radius: frame.size.width / 2.0, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true
    )
    arcLayer.path = path.cgPath
    arcLayer.fillColor = UIColor.clear.cgColor
    arcLayer.strokeColor = barColor.cgColor
    arcLayer.lineCap = .round
    arcLayer.lineWidth = barWidth
    arcLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    arcLayer.position = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
    layer.addSublayer(arcLayer)
  }

  private func updateArc() {
    guard let progress else { return }
    arcLayer.removeAnimation(forKey: "spin")
    arcLayer.strokeEnd = CGFloat(min(max(progress, 0), 100) / 100.0)
  }

  override func animate() {
    guard progress == nil else { return }
    arcLayer.strokeEnd = 0.25
    let spin = CABasicAnimation(keyPath: "transform.rotation")
    spin.fromValue = 0
    spin.toValue = Double.pi * 2
    spin.duration = 1.0
    spin.repeatCount = .infinity
    arcLayer.add(spin, forKey: "spin")
  }
}

extension UIColor {
  static func colorFromRGB(_ rgbValue: UInt) -> UIColor {
    UIColor(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: 1.0
    )
  }

  convenience init?(hexString: String) {
    var cString = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if cString.hasPrefix("#") { cString.removeFirst() }
    guard cString.count == 6, let rgbValue = UInt32(cString, radix: 16) else { return nil }
    self.init(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: 1.0
    )
  }
}

/// Objective-C-compatible entry point for `SweetAlertView`. ObjC++ TurboModule
/// glue can't call `SweetAlertView.present` directly: it takes a Swift-only
/// `AlertStyle` enum and `Double?` params, neither of which bridge to
/// Objective-C. This wrapper flattens those to `String`/`NSNumber?`.
@objc(SweetAlertBridge)
public final class SweetAlertBridge: NSObject {
  @objc public static func present(
    title: String,
    subTitle: String?,
    style: String,
    confirmButtonTitle: String?,
    confirmButtonColor: String?,
    otherButtonTitle: String?,
    otherButtonColor: String?,
    cancellable: Bool,
    progress: NSNumber?,
    progressBarColor: String?,
    progressBarWidth: NSNumber?,
    completion: @escaping (Bool) -> Void
  ) {
    let convertedStyle: AlertStyle
    switch style {
    case "success": convertedStyle = .success
    case "error": convertedStyle = .error
    case "warning": convertedStyle = .warning
    case "progress": convertedStyle = .progress
    default: convertedStyle = .none
    }

    SweetAlertView.present(
      title: title,
      subTitle: subTitle,
      style: convertedStyle,
      confirmButtonTitle: confirmButtonTitle,
      confirmButtonColor: confirmButtonColor.flatMap { UIColor(hexString: $0) },
      otherButtonTitle: otherButtonTitle,
      otherButtonColor: otherButtonColor.flatMap { UIColor(hexString: $0) },
      cancellable: cancellable,
      progress: progress?.doubleValue,
      progressBarColor: progressBarColor.flatMap { UIColor(hexString: $0) },
      progressBarWidth: progressBarWidth?.doubleValue,
      action: completion
    )
  }

  @objc public static func dismiss() {
    SweetAlertView.dismissCurrent()
  }

  @objc public static func setProgress(_ progress: Double) {
    SweetAlertView.updateProgress(progress)
  }
}
