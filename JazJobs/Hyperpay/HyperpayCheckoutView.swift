import SwiftUI
import OPPWAMobile

class Config: NSObject {
    static let urlScheme = "sa.com.Fazaa.Wishy.payments" // ضع نفس الـ URL Scheme في Info.plist
}

struct HyperpayCheckoutView: UIViewControllerRepresentable {
    let checkoutId: String
    let paymentBrands: [String]
    let onResult: (Result<String, Error>) -> Void
    var onDismiss: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult, onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let paymentProvider = OPPPaymentProvider(mode: .live)
        let checkoutSettings = OPPCheckoutSettings()
        checkoutSettings.paymentBrands = paymentBrands
        checkoutSettings.shopperResultURL = Config.urlScheme + "://payment"

        let checkoutProvider = OPPCheckoutProvider(
            paymentProvider: paymentProvider,
            checkoutID: checkoutId,
            settings: checkoutSettings
        )
        checkoutProvider?.delegate = context.coordinator
        context.coordinator.checkoutProvider = checkoutProvider

        DispatchQueue.main.async {
            checkoutProvider?.presentCheckout(
                forSubmittingTransactionCompletionHandler: { (transaction, error) in
                    context.coordinator.checkoutProvider(checkoutProvider!, didSubmitTransaction: transaction, error: error)
                },
                cancelHandler: {
                    context.coordinator.checkoutProviderDidCancel(checkoutProvider!)
                }
            )
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, OPPCheckoutProviderDelegate {
        let onResult: (Result<String, Error>) -> Void
        var onDismiss: (() -> Void)?
        weak var checkoutProvider: OPPCheckoutProvider?

        // نخزّن الـ resourcePath إذا كانت العملية async
        private var pendingResourcePath: String?

        init(onResult: @escaping (Result<String, Error>) -> Void,
             onDismiss: (() -> Void)?) {
            self.onResult = onResult
            self.onDismiss = onDismiss
        }

        func checkoutProvider(_ checkoutProvider: OPPCheckoutProvider,
                              didSubmitTransaction transaction: OPPTransaction?,
                              error: Error?) {
            if let error = error {
                onResult(.failure(error))
                dismiss(checkoutProvider)
                return
            }

            guard let transaction = transaction else {
                dismiss(checkoutProvider)
                return
            }

            if transaction.type == .asynchronous {
                // ✅ خزن الـ resourcePath وانتظر رجوع Safari
                pendingResourcePath = transaction.resourcePath
            } else {
                // ✅ synchronous — رجّع الـ resourcePath مباشرة
                onResult(.success(transaction.resourcePath ?? ""))
                dismiss(checkoutProvider)
            }
        }

        func checkoutProviderDidCancel(_ checkoutProvider: OPPCheckoutProvider) {
            let err = NSError(domain: "Hyperpay", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "تم الإلغاء من قبل المستخدم"])
            onResult(.failure(err))
            dismiss(checkoutProvider)
        }

        func checkoutProviderDidFinishSafariViewController(_ checkoutProvider: OPPCheckoutProvider) {
            // ✅ بعد الرجوع من Safari رجّع الـ resourcePath اللي خزّناه
            if let path = pendingResourcePath, !path.isEmpty {
                onResult(.success(path))
            } else {
                let err = NSError(domain: "Hyperpay", code: -2,
                                  userInfo: [NSLocalizedDescriptionKey: "تعذّر الحصول على معرف العملية"])
                onResult(.failure(err))
            }
            pendingResourcePath = nil
            dismiss(checkoutProvider)
        }

        private func dismiss(_ provider: OPPCheckoutProvider) {
            provider.dismissCheckout(animated: true) { [weak self] in
                self?.onDismiss?()
            }
        }
    }
}


//import SwiftUI
//import OPPWAMobile
//
//class Config: NSObject {
//    static let urlScheme = "sa.com.Fazaa.Wishy.payments"
//}
//
//struct HyperpayCheckoutView: UIViewControllerRepresentable {
//    let checkoutId: String
//    let paymentBrands: [String]
//    let onResult: (Result<String, Error>) -> Void
//    var onDismiss: (() -> Void)? = nil
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(onResult: onResult, onDismiss: onDismiss)
//    }
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        let viewController = UIViewController()
//        let paymentProvider = OPPPaymentProvider(mode: .live)
//        let checkoutSettings = OPPCheckoutSettings()
//        checkoutSettings.paymentBrands = paymentBrands
//        checkoutSettings.shopperResultURL = Config.urlScheme + "://payment"
//
//        let checkoutProvider = OPPCheckoutProvider(
//            paymentProvider: paymentProvider,
//            checkoutID: checkoutId,
//            settings: checkoutSettings
//        )
//        checkoutProvider?.delegate = context.coordinator
//        context.coordinator.checkoutProvider = checkoutProvider
//
//        DispatchQueue.main.async {
//            checkoutProvider?.presentCheckout(
//                forSubmittingTransactionCompletionHandler: { (transaction, error) in
//                    context.coordinator.checkoutProvider(checkoutProvider!, didSubmitTransaction: transaction, error: error)
//                },
//                cancelHandler: {
//                    context.coordinator.checkoutProviderDidCancel(checkoutProvider!)
//                }
//            )
//        }
//        return viewController
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
//
//    class Coordinator: NSObject, OPPCheckoutProviderDelegate {
//        let onResult: (Result<String, Error>) -> Void
//        var onDismiss: (() -> Void)?
//        weak var checkoutProvider: OPPCheckoutProvider?
//
//        init(onResult: @escaping (Result<String, Error>) -> Void, onDismiss: (() -> Void)?) {
//            self.onResult = onResult
//            self.onDismiss = onDismiss
//        }
//
//        func checkoutProvider(_ checkoutProvider: OPPCheckoutProvider, didSubmitTransaction transaction: OPPTransaction?, error: Error?) {
//            print("==== Hyperpay SDK Result Callback ====")
//            if let error = error {
//                print("Error: \(error.localizedDescription)")
//                onResult(.failure(error))
//                checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
//                    self?.onDismiss?()
//                })
//            } else if let transaction = transaction {
//                print("Transaction: \(transaction)")
//                print("Resource Path: \(transaction.resourcePath ?? "nil")")
//                print("Type: \(transaction.type.rawValue)")
//                onResult(.success(transaction.resourcePath ?? ""))
//
//                if transaction.type == .asynchronous {
//                    // انتظر سفاري، لا تغلق
//                } else {
//                    checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
//                        self?.onDismiss?()
//                    })
//                }
//            } else {
//                print("No error, no transaction -- unexpected result!")
//                checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
//                    self?.onDismiss?()
//                })
//            }
//        }
//
//        func checkoutProviderDidCancel(_ checkoutProvider: OPPCheckoutProvider) {
//            let error = NSError(
//                domain: "Hyperpay",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "تم الإلغاء من قبل المستخدم"]
//            )
//            onResult(.failure(error))
//            checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
//                self?.onDismiss?()
//            })
//        }
//
//        func checkoutProviderDidFinishSafariViewController(_ checkoutProvider: OPPCheckoutProvider) {
//            print("checkoutProviderDidFinishSafariViewController called")
//            checkoutProvider.dismissCheckout(animated: true, completion: { [weak self] in
//                self?.onDismiss?()
//            })
//        }
//    }
//}
