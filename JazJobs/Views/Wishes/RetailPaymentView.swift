// RetailPaymentView.swift

import SwiftUI
//import goSellSDK
import TamaraSDK
import PassKit

struct RetailPaymentView: View {
    @EnvironmentObject var appRouter: AppRouter
    @State var total = ""
    @ObservedObject var wishesViewModel = WishesViewModel(errorHandling: ErrorHandling())
    let wishId: String?
    @StateObject private var hyperPaymentViewModel = HyperPaymentViewModel()
    @State private var selectedBrand: HyperpayBrand = .mada
    @State private var showBrandSheet = false
    @State private var currentHyperpayId: String?

    @State private var payHyper: Bool = true
    @State private var payTamara: Bool = false
    @StateObject var orderViewModel = OrderViewModel(errorHandling: ErrorHandling())
    @State private var showTamaraPayment = false
    @State private var checkoutUrl = ""
    @State var tamaraViewModel: TamaraWebViewModel? = nil
    let canShowApplePay: Bool = PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .mada])
    @State private var showApplePaySheet = false
    @State private var applePayCheckoutId: String?
    @State private var applePayAmount: Double = 0.0

    var body: some View {
        VStack {
            Image("ic_money")
                .padding(.top, 80)

            PaymentOptionsSection(payHyper: $payHyper, payTamara: $payTamara)
                .padding(.bottom, 16)

            if payHyper {
                VStack(alignment: .leading, spacing: 8) {
                    Text("نوع البطاقة")
                        .font(.subheadline)
                    Button {
                        showBrandSheet = true
                    } label: {
                        HStack {
                            Text(selectedBrand.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.bottom, 10)
            }

            Text("اكتب القيمة بالريال السعودي")
                .customFont(weight: .bold, size: 16)
                .foregroundColor(.primaryBlack())

            VStack(alignment: .leading) {
                TextField(LocalizedStringKey.sar, text: $total)
                    .placeholder(when: total.isEmpty) {
                        Text(LocalizedStringKey.sar)
                            .foregroundColor(.gray999999())
                    }
                    .customFont(weight: .regular, size: 14)
                    .keyboardType(.numberPad)
                    .accentColor(.primary())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .underline()
                    .roundedBackground(cornerRadius: 12, strokeColor: .gray898989(), lineWidth: 1)
            }
            .foregroundColor(.black222020())

            Spacer()

            if orderViewModel.isLoading {
                LoadingView()
            }

            // زر Apple Pay الرسمي إذا تم اختياره وكان الجهاز يدعم
            if payHyper,
               selectedBrand == .apple,
               canShowApplePay
            {
                ApplePaySection {
                    if total.isEmpty {
                        wishesViewModel.errorMessage = "ادخل قيمة للاستمرار بالدفع!"
                        return
                    }
                    let amount = total.toDouble() ?? 0.0
                    startHyperpayPayment(amount: amount)
                }
                .frame(height: 48)
                .padding(.horizontal)
            } else {
                Button {
                    if total.isEmpty {
                        wishesViewModel.errorMessage = "ادخل قيمة للاستمرار بالدفع!"
                        return
                    }
                    let amount = total.toDouble() ?? 0.0
                    if payHyper {
                        startHyperpayPayment(amount: amount)
                    } else if payTamara {
                        startTamaraCheckout(amount: amount)
                    }
                } label: {
                    Text("الاستمرار للدفع")
                }
                .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                .padding(.horizontal, 16)
                .disabled(orderViewModel.isLoading)
            }
        }
        .padding(16)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image("ic_back")
                    }

                    Text("ساهم الان بـ قَطّة!")
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .overlay(MessageAlertObserverView(message: $orderViewModel.errorMessage, alertType: .constant(.error)))
        .overlay(MessageAlertObserverView(message: $wishesViewModel.errorMessage, alertType: .constant(.error)))
        .sheet(isPresented: $showBrandSheet) {
            BrandSheet(selectedBrand: $selectedBrand, showBrandSheet: $showBrandSheet, canShowApplePay: canShowApplePay)
        }
        .fullScreenCover(isPresented: $hyperPaymentViewModel.isShowingCheckout) {
            if let checkoutId = hyperPaymentViewModel.checkoutId {
                HyperpayCheckoutView(
                    checkoutId: checkoutId,
                    paymentBrands: [selectedBrand.displayName],
                    onResult: { result in
                        switch result {
                        case .success(let resourcePath):
                            checkHyperpayStatus(resourcePath: checkoutId)
                        case .failure(let error):
                            orderViewModel.errorMessage = error.localizedDescription
                            orderViewModel.isLoading = false
                        }
                    },
                    onDismiss: {
                        // أغلق الشاشة فقط هنا!
                        hyperPaymentViewModel.isShowingCheckout = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showApplePaySheet) {
            if let checkoutId = applePayCheckoutId {
                ApplePayControllerView(
                    checkoutId: checkoutId,
                    amount: applePayAmount,
                    onResult: { result in
                        showApplePaySheet = false
                        switch result {
                        case .success(let hyperpayId):
                            checkHyperpayStatus(resourcePath: hyperpayId)
                        case .failure(let error):
                            orderViewModel.errorMessage = error.localizedDescription
                            orderViewModel.isLoading = false
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showTamaraPayment) {
            if let url = URL(string: checkoutUrl) {
                SafariView(url: url) { redirectedURL in
                    handleTamaraRedirect(url: redirectedURL)
                }
            }
        }
        // ⬅️ Overlay إضافي للودينج الخاص بـ HyperPaymentViewModel (مع الحفاظ على القديم)
        .overlay {
            if hyperPaymentViewModel.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            laodWishData()
        }
    }

    private func handleTamaraRedirect(url: URL) {
        let urlStr = url.absoluteString
        showTamaraPayment = false

        if urlStr.contains("wishy.sa/tamara/success") {
            payWish()
        } else if urlStr.contains("wishy.sa/tamara/failure") {
            orderViewModel.errorMessage = "فشلت عملية الدفع"
        } else if urlStr.contains("wishy.sa/tamara/cancel") {
            orderViewModel.errorMessage = "تم إلغاء عملية الدفع"
        }
    }

    func payWish() {
        let params: [String: Any] = ["total": total]
        wishesViewModel.payWish(id: wishId ?? "", params: params) {
            appRouter.navigate(to: .paymentSuccess)
        }
    }

    func startHyperpayPayment(amount: Double) {
        orderViewModel.isLoading = true
        hyperPaymentViewModel.requestCheckoutId(
            amount: amount,
            brandType: selectedBrand.dbValue
        ) { checkoutId in
            if let id = checkoutId {
                currentHyperpayId = id
                if selectedBrand == .apple {
                    if !canShowApplePay {
                        orderViewModel.errorMessage = "جهازك لا يدعم Apple Pay أو لم يتم إضافة بطاقة"
                        return
                    }
                    showApplePaySheet(checkoutId: id, amount: amount)
                } else {
                    hyperPaymentViewModel.isShowingCheckout = true
                }
            } else {
                orderViewModel.errorMessage = "تعذر بدء عملية الدفع"
            }
        }
    }
    
    // وظيفة عرض Apple Pay Sheet (ضعها في extension)
    func showApplePaySheet(checkoutId: String, amount: Double) {
        applePayCheckoutId = checkoutId
        applePayAmount = amount
        showApplePaySheet = true
    }

    func checkHyperpayStatus(resourcePath: String) {
        hyperPaymentViewModel.checkPaymentStatus(
            hyperpayId: resourcePath,
            brandType: selectedBrand.dbValue
        ) { status, response in
            orderViewModel.isLoading = false
            if status {
                payWish()
            } else {
                orderViewModel.errorMessage = "فشلت عملية الدفع"
            }
        }
    }

    func startTamaraCheckout(amount: Double) {
        orderViewModel.isLoading = true
        let productId = wishesViewModel.wish?.product_id?.id ?? ""

        let tamaraBody = TamaraBody(
            amount: amount,
            products: [
                TamaraProduct(
                    product_id: productId,
                    variation_name: wishesViewModel.wish?.product_id?.variation_name ?? "",
                    variation_sku: wishesViewModel.wish?.product_id?.variation_sku ?? "",
                    qty: 1
                )
            ]
        )

        orderViewModel.tamaraCheckout(params: tamaraBody) {
            let url = orderViewModel.tamaraCheckout?.checkout_url ?? ""
            self.checkoutUrl = url
            self.tamaraViewModel = TamaraWebViewModel(
                url: self.checkoutUrl,
                merchantURL: TamaraMerchantURL(
                    success: "https://wishy.sa/tamara/success",
                    failure: "https://wishy.sa/tamara/failure",
                    cancel: "https://wishy.sa/tamara/cancel",
                    notification: "https://wishy.sa/tamara/cancel"
                )
            )
            showTamaraPayment.toggle()
        }
    }    
}

extension RetailPaymentView {
    func laodWishData() {
        wishesViewModel.getWish(id: wishId ?? "")
    }
}

struct PaymentOptionsSection: View {
    @Binding var payHyper: Bool
    @Binding var payTamara: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("اختر طريقة الدفع")
                .customFont(weight: .bold, size: 15)
                .foregroundColor(.black121212())

            HStack(spacing: 20) {
                RetailCheckboxButton(title: "هايبر بي", isChecked: $payHyper, other: $payTamara)
                RetailCheckboxButton(title: "تمارا", isChecked: $payTamara, other: $payHyper)
            }
        }
    }
}

struct RetailCheckboxButton: View {
    let title: String
    @Binding var isChecked: Bool
    @Binding var other: Bool

    var body: some View {
        Button {
            if !isChecked {
                isChecked = true
                other = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(isChecked ? .primary() : .gray595959())
                Text(title)
                    .foregroundColor(.black121212())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

