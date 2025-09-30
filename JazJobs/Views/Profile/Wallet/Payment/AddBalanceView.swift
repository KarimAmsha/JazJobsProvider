//
//  AddBalanceView.swift
//  Wishy
//
//  Created by Karim Amsha on 15.06.2024.
//

import SwiftUI
import PassKit

struct AddBalanceView: View {
    @State private var coupon = ""
    @State private var amount = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var showAddBalanceView: Bool
    var onsuccess: () -> Void

    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var orderViewModel = OrderViewModel(errorHandling: ErrorHandling())
    @StateObject private var hyperPaymentViewModel = HyperPaymentViewModel()

    @State private var selectedBrand: HyperpayBrand = .mada
    @State private var currentHyperpayId: String?
    @State private var showBrandSheet = false
    @State private var showApplePaySheet = false
    @State private var applePayCheckoutId: String?
    @State private var applePayAmount: Double = 0.0
    let canShowApplePay: Bool = PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .mada])

    init(showAddBalanceView: Binding<Bool>, onsuccess: @escaping () -> Void) {
        _showAddBalanceView = showAddBalanceView
        self.onsuccess = onsuccess
    }

    var body: some View {
        VStack(spacing: 20) {
            CustomTextFieldWithTitle(text: $amount, placeholder: LocalizedStringKey.amount, textColor: .black4E5556(), placeholderColor: .grayA4ACAD())
                .keyboardType(.numberPad)
                .disabled(orderViewModel.isLoading)

            if let errorMessage = orderViewModel.errorMessage {
                Text(errorMessage)
                    .customFont(weight: .regular, size: 14)
                    .foregroundColor(.redFF3F3F())
            }

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
            .disabled(orderViewModel.isLoading)

            if orderViewModel.isLoading {
                LoadingView()
            }
            
            if selectedBrand == .apple, canShowApplePay
            {
                ApplePaySection {
                    if let amountValue = amount.toDouble(), amountValue > 0 {
                        startHyperpayPayment(amount: amountValue)
                    } else {
                        orderViewModel.errorMessage = "يرجى إدخال المبلغ بشكل صحيح"
                    }
                }
                .frame(height: 48)
                .padding(.horizontal)
                .padding(.vertical, 8)
            } else {
                // زر دفع عادي
                Button {
                    checkCoupon()
                } label: {
                    Text(LocalizedStringKey.send)
                }
                .buttonStyle(PrimaryButton(fontSize: 18, fontWeight: .bold, background: .primary(), foreground: .white, height: 48, radius: 12))
                .disabled(orderViewModel.isLoading)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(LocalizedStringKey.addAccount)
        .alert(isPresented: $showAlert) {
            Alert(title: Text(LocalizedStringKey.error), message: Text(alertMessage), dismissButton: .default(Text(LocalizedStringKey.ok)))
        }
        .sheet(isPresented: $showBrandSheet) {
            BrandSheet(selectedBrand: $selectedBrand, showBrandSheet: $showBrandSheet, canShowApplePay: canShowApplePay)
        }
        .overlay(
            MessageAlertObserverView(
                message: $hyperPaymentViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
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
        // ⬅️ Overlay إضافي للودينج الخاص بـ HyperPaymentViewModel (مع الحفاظ على القديم)
        .overlay {
            if hyperPaymentViewModel.isLoading {
                LoadingView()
            }
        }
    }

    private func checkCoupon() {
        orderViewModel.errorMessage = nil

        guard !amount.isEmpty, let amountValue = amount.toDouble(), amountValue > 0 else {
            orderViewModel.errorMessage = LocalizedStringKey.addAccount
            return
        }

        if coupon.isEmpty {
            startHyperpayPayment(amount: amountValue)
        } else {
            orderViewModel.checkWalletCoupon(params: [:]) {
                if let finalTotal = orderViewModel.coupon?.final_total {
                    startHyperpayPayment(amount: finalTotal)
                }
            }
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
                        orderViewModel.isLoading = false
                        return
                    }
                    showApplePaySheet(checkoutId: id, amount: amount)
                } else {
                    hyperPaymentViewModel.isShowingCheckout = true
                }
            } else {
                orderViewModel.errorMessage = "تعذر بدء عملية الدفع"
                orderViewModel.isLoading = false
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
                addBalance()
            } else {
                orderViewModel.errorMessage = "فشلت عملية الدفع"
            }
        }
    }

    func addBalance() {
        let params: [String: Any] = [
            "amount": coupon.isEmpty ? amount.toDouble() ?? 0.0 : orderViewModel.coupon?.final_total ?? 0.0,
            "coupon": coupon,
        ]

        orderViewModel.addBalanceToWallet(params: params) { message in
            showAddBalanceView = false
            self.onsuccess()
        }
    }
}

