import PassKit
import SwiftUI
import OPPWAMobile

struct ApplePayControllerView: UIViewControllerRepresentable {
    let checkoutId: String
    let amount: Double
    let onResult: (Result<String, Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIViewController {
        return ApplePayContainerViewController { vc in
            context.coordinator.startApplePay(in: vc)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
        let parent: ApplePayControllerView
        private var didFinishWithResult = false

        init(parent: ApplePayControllerView) { self.parent = parent }

        func startApplePay(in viewController: UIViewController) {
            guard PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .mada]) else {
                parent.onResult(.failure(NSError(domain: "ApplePay",
                                                 code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey: "جهازك لا يدعم Apple Pay أو لا توجد بطاقة صالحة"])))
                return
            }

            let req = PKPaymentRequest()
            req.merchantIdentifier = "merchant.wishy.newlive.sa.com" // ← بدّلها لِـ Merchant ID الحقيقي
            req.supportedNetworks = [.visa, .masterCard, .mada]
            req.merchantCapabilities = .capability3DS
            req.countryCode = "SA"
            req.currencyCode = "SAR"
            req.requiredBillingContactFields = [.name, .postalAddress, .emailAddress, .phoneNumber]
            req.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "Wishy", amount: NSDecimalNumber(value: parent.amount))
            ]

            guard let controller = PKPaymentAuthorizationViewController(paymentRequest: req) else {
                parent.onResult(.failure(NSError(domain: "ApplePay",
                                                 code: 0,
                                                 userInfo: [NSLocalizedDescriptionKey: "تعذّر إنشاء Apple Pay Sheet"])))
                return
            }
            controller.delegate = self
            viewController.present(controller, animated: true)
        }

        func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                                didAuthorizePayment payment: PKPayment,
                                                handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            // في الإنتاج استخدم .live
            let provider = OPPPaymentProvider(mode: .live)

            do {
                let params = try OPPApplePayPaymentParams(checkoutID: parent.checkoutId,
                                                          tokenData: payment.token.paymentData)
                params.shopperResultURL = "sa.com.Fazaa.Wishy.payments://payment"

                let transaction = OPPTransaction(paymentParams: params)
                provider.submitTransaction(transaction) { [weak self] (t, error) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        if let error = error {
                            self.didFinishWithResult = true
                            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                            self.parent.onResult(.failure(error))
                        } else {
                            // نجاح التفويض: نعيد checkoutId بدل resourcePath حسب طلبك
                            self.didFinishWithResult = true
                            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                            self.parent.onResult(.success(self.parent.checkoutId))
                        }
                    }
                }
            } catch {
                self.didFinishWithResult = true
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                parent.onResult(.failure(error))
            }
        }

        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
            controller.dismiss(animated: true) {
                // إذا ما وصّلنا نتيجة قبل (مثلاً المستخدم أغلق الشيت قبل التفويض)
                if !self.didFinishWithResult {
                    self.parent.onResult(.failure(NSError(domain: "ApplePay",
                                                          code: 1,
                                                          userInfo: [NSLocalizedDescriptionKey: "تم الإغلاق قبل إتمام العملية"])))
                }
            }
        }
    }
}

final class ApplePayContainerViewController: UIViewController {
    let onAppear: (UIViewController) -> Void
    private var hasPresented = false

    init(onAppear: @escaping (UIViewController) -> Void) {
        self.onAppear = onAppear
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasPresented {
            hasPresented = true
            onAppear(self)
        }
    }
}
