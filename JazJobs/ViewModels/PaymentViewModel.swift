//
//  PaymentViewModel.swift
//  Wishy
//
//  Created by Karim Amsha on 15.06.2024.
//

import SwiftUI
//import goSellSDK
import PassKit

enum PaymentStatus: Equatable {
    case success
    case failed(String)
    case cancelled
}

class PaymentViewModel: NSObject, ObservableObject {
    @Published var myAmount: Decimal = 100.0
//    @Published var transactionMode: TransactionMode = .purchase
    let settings = UserSettings.shared
//    @Published var paymentSuccess: Bool = false
    @Published var errorMessage: String?
    var applePay = false
    var applePayUI = false
    @Published var paymentStatus: PaymentStatus?
    var paymentIcon: UIImage {
        UIImage(systemName: "creditcard") ?? UIImage()
    }

    var applePayMerchantID: String
    {
        return "merchant.wishy.live.sa.com"
    }
    
    var merchantID: String?
    {
        return "35263831"
    }
    
//    func startPayment() {
//        let session = Session()
//        session.dataSource = self
//        session.delegate = self
////        applePay = true
////        applePayUI = false
//        do {
////            try session.startApplePay()
//            try session.start()
//        } catch {
//            // Handle the error appropriately
//            print("Error starting payment session: \(error)")
//        }
//    }
    
//    func startPayment() {
//        let session = Session()
//        session.dataSource = self
//        session.delegate = self
//        session.start()  // لا تحتاج try
//    }
    
//    func startPayment() {
//        let session = Session()
//        session.dataSource = self
//        session.delegate = self
//
//        do {
//            if applePay {
//                try session.startApplePay()
//            } else {
//                session.start() // لا تحتاج try
//            }
//        } catch {
//            print("Error starting Apple Pay session: \(error)")
//        }
//    }

    // Function to update the amount based on user input
    func updateAmount(_ newAmount: String) {
        if let decimalAmount = Decimal(string: newAmount) {
            myAmount = decimalAmount
        } else {
            print("Invalid amount format")
        }
    }
}

//extension PaymentViewModel: SessionDataSource {
//    var amount: Decimal {
//        return self.myAmount
//    }
//
//    var currency: goSellSDK.Currency? {
//        do {
//            return try goSellSDK.Currency(isoCode: "SAR")
//        } catch {
//            // Handle the error appropriately
//            print("Error creating currency object: \(error)")
//            return nil
//        }
//    }
//
//    var customer: goSellSDK.Customer? {
//        // Replace with actual customer details
////        let customerIdentifier = settings.id ?? ""
//        do {
//            let phone = settings.user?.phone_number ?? "555555555"
//            let email = settings.user?.email ?? "dummy@wishy.sa"
//
//            let emailAddressCopy = try EmailAddress(emailAddressString: email)
//            let phoneNumberCopy = try PhoneNumber(isdNumber: "+966", phoneNumber: phone)
//
//            return try goSellSDK.Customer(
//                emailAddress: emailAddressCopy,
//                phoneNumber: phoneNumberCopy,
//                firstName: settings.user?.full_name ?? "Wishy",
//                middleName: "",
//                lastName: ""
//            )
//        } catch {
//            // Handle the error appropriately
//            print("Error creating customer object: \(error)")
//            return nil
//        }
//    }
//
//    var mode: TransactionMode {
//        return self.transactionMode
//    }
//}
//
//extension PaymentViewModel: SessionDelegate {
//    func paymentSucceed(_ charge: goSellSDK.Charge, on session: SessionProtocol) {
//        // Handle successful payment
//        paymentStatus = .success
////        handlePaymentSuccess()
//    }
//
//    func paymentFailed(with charge: goSellSDK.Charge?, error: TapSDKError?, on session: SessionProtocol) {
//        // Handle payment failure
//        let message = error?.localizedDescription ?? "حدث خطأ في الدفع"
//        print("Payment Failed: \(message)")
//        paymentStatus = .failed(message)
//    }
//
//    func sessionCancelled(_ session: SessionProtocol) {
//        // Handle payment cancellation
//        print("Payment Cancelled")
//        paymentStatus = .cancelled
//    }
//    
//    func checkApplePaySupport() {
//        let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .mada] // أو حسب البوابة
//
//        let canMakePayment = PKPaymentAuthorizationController.canMakePayments()
//        let canMakePaymentWithNetworks = PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
//
//        print("🟢 Apple Pay متاح على الجهاز؟", canMakePayment)
//        print("🟢 مع الشبكات؟", canMakePaymentWithNetworks)
//
//        if !canMakePayment || !canMakePaymentWithNetworks {
//            print("❌ الجهاز لا يدعم Apple Pay أو الشبكات غير مدعومة")
//        } else {
//            print("✅ Apple Pay متاحة وجاهزة")
//        }
//    }
//}
