import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()
    GeneratedPluginRegistrant.register(with: self)

    // Register HushSecureTextView platform view factory for local secret text protection
    if let registrar = self.registrar(forPlugin: "HushSecureTextViewPlugin") {
      let factory = HushSecureTextViewFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "hush_secure_text_view")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class HushSecureTextViewFactory: NSObject, FlutterPlatformViewFactory {
  private var messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return HushSecureTextView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      binaryMessenger: messenger
    )
  }

  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class HushSecureTextView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let textField: UITextField
  private let label: UILabel

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    textField = UITextField(frame: frame)
    textField.isSecureTextEntry = true
    textField.isUserInteractionEnabled = false
    textField.backgroundColor = .clear

    label = UILabel(frame: frame)
    label.numberOfLines = 0
    label.backgroundColor = .clear
    label.isUserInteractionEnabled = false

    if let params = args as? [String: Any] {
      if let text = params["text"] as? String {
        label.text = text
      }
      if let fontSize = params["fontSize"] as? CGFloat {
        label.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
      } else {
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
      }
      if let isRtl = params["isRtl"] as? Bool, isRtl {
        label.textAlignment = .right
      } else {
        label.textAlignment = .left
      }
      label.textColor = .white
    }

    super.init()

    containerView.addSubview(textField)
    textField.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      textField.topAnchor.constraint(equalTo: containerView.topAnchor),
      textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    let secureCanvas = textField.subviews.first ?? textField
    secureCanvas.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: secureCanvas.topAnchor),
      label.leadingAnchor.constraint(equalTo: secureCanvas.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: secureCanvas.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: secureCanvas.bottomAnchor),
    ])
  }

  func view() -> UIView {
    return containerView
  }
}
