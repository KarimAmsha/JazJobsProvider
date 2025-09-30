import SwiftUI
import PassKit

struct ApplePayButtonView: UIViewRepresentable {
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func didTapButton() {
            action()
        }
    }
}

struct ApplePaySection: View {
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ApplePayButtonView(action: action)
                .frame(height: 50)
            
            if !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .mada]) {
                Text("أضف بطاقة إلى Apple Wallet لتفعيل Apple Pay")
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
}
