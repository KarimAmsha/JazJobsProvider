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
            
            // زر دفع عادي
            Button {
                checkCoupon()
            } label: {
                Text(LocalizedStringKey.send)
            }
            .buttonStyle(PrimaryButton(fontSize: 18, fontWeight: .bold, background: .primary(), foreground: .white, height: 48, radius: 12))
            .disabled(orderViewModel.isLoading)

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
    }

    private func checkCoupon() {
        orderViewModel.errorMessage = nil

        guard !amount.isEmpty, let amountValue = amount.toDouble(), amountValue > 0 else {
            orderViewModel.errorMessage = LocalizedStringKey.addAccount
            return
        }

        if coupon.isEmpty {
        } else {
            orderViewModel.checkWalletCoupon(params: [:]) {
                if let finalTotal = orderViewModel.coupon?.final_total {
                }
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

