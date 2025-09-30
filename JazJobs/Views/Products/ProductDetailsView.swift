//
//  ProductDetailsView.swift
//  Wishy
//
//  Created by Karim Amsha on 1.05.2024.
//

import SwiftUI
import PopupView
//import goSellSDK
import PassKit

struct ProductDetailsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter
    @ObservedObject var viewModel: InitialViewModel
    @ObservedObject var cartViewModel = CartViewModel(errorHandling: ErrorHandling())
    let productId: String?
    @State var showAddToMyWishes = false
    @State var showRetailAlertView = false
    @State var selectedGroup: Group?
    @State var type: String?
    @StateObject var wishesViewModel = WishesViewModel(errorHandling: ErrorHandling())
    @State private var selectedOption: String?
    @State private var selectedName: String = ""
    @State private var selectedSku: String = ""
    @State private var showAddToCartPopup = false
    @State private var selectedGroupId: String = ""
    @State private var selectedIsShare: Bool = false
    @State private var showPaymentOptions = false
    @State private var exploreCost: Double = 0.0
    @StateObject var orderViewModel = OrderViewModel(errorHandling: ErrorHandling())
    @State private var showTamaraPayment = false
    @State private var checkoutUrl = ""
    @State var tamaraViewModel: TamaraWebViewModel? = nil
    @StateObject private var paymentViewModel = PaymentViewModel()
    // Hyperpay
    @StateObject private var hyperPaymentViewModel = HyperPaymentViewModel()
    @State private var selectedBrand: HyperpayBrand = .mada
    @State private var showBrandSheet = false
    @State private var currentHyperpayId: String?

    // اختيار وسيلة الدفع
    @State private var payHyper: Bool = true
    @State private var payTamara: Bool = false
    @State private var showApplePaySheet = false
    @State private var applePayCheckoutId: String?
    @State private var applePayAmount: Double = 0.0
    let canShowApplePay: Bool = PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .mada])

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isLoading || viewModel.product == nil {
                        LoadingView()
                    }

                    productImageView
                    productDetailsView
                }
            }

            Spacer()

            if cartViewModel.isLoading {
                LoadingView()
            }

            if orderViewModel.isLoading {
                LoadingView()
            }

            CustomDivider()
            actionButtons
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image("ic_back")
                    }

                    Text(viewModel.product?.name ?? "")
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .popup(isPresented: $showAddToMyWishes) {
            GroupListView(onSelect: { group, type, cost in
                showAddToMyWishes.toggle()
                self.selectedGroup = group
                self.type = type ? "public" : "private"
                self.exploreCost = cost
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {
                    showRetailAlertView.toggle()
                })
            }, onCancel: {
                showAddToMyWishes.toggle()
            })
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .closeOnTap(false)
                .backgroundColor(Color.black.opacity(0.80))
                .isOpaque(true)
                .useKeyboardSafeArea(true)
        }
        .popup(isPresented: $showRetailAlertView) {
            RetailAlertView(onSelect: { isShared in
                if let group = selectedGroup, let id = group.id, let type = type {
                    addToMyWish(group_id: id, type: type, isShare: isShared)
                }
            }, onCancel: {
                showRetailAlertView.toggle()
            })
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .closeOnTap(false)
                .backgroundColor(Color.black.opacity(0.80))
                .isOpaque(true)
                .useKeyboardSafeArea(true)
        }
        .popup(isPresented: $showAddToCartPopup) {
            AddToCartPopup(isPresented: $showAddToCartPopup) {
                NotificationCenter.default.post(name: .cartUpdated, object: nil)
                appState.currentPage = .cart
            }
        } customize: {
            $0.type(.floater()).position(.bottom).animation(.spring()).closeOnTapOutside(true).backgroundColor(Color.black.opacity(0.4))
        }
        .popup(isPresented: $showPaymentOptions) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 28) {
                    // زر إغلاق دائري أعلى اليمين
                    HStack {
                        Spacer()
                        Button(action: { showPaymentOptions = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.gray.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    
                    // عنوان رئيسي
                    Text("اختر وسيلة الدفع")
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(.primaryBlack())
                        .padding(.bottom, -8)
                    
                    // خيارات الدفع
                    HStack(spacing: 20) {
                        paymentChoiceButton(icon: "creditcard", title: "هايبر باي", isActive: payHyper) {
                            payHyper = true
                            payTamara = false
                        }
                        paymentChoiceButton(icon: "cart", title: "تمارا", isActive: payTamara) {
                            payHyper = false
                            payTamara = true
                        }
                    }
                    .padding(.vertical, 6)
                    
                    // اختيار نوع البطاقة
                    if payHyper {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("نوع البطاقة")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primaryBlack())
                            
                            Button {
                                showBrandSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: selectedBrand.iconName) // استخدم iconName حسب براندك
                                        .frame(width: 24, height: 24)
                                    Text(selectedBrand.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("يمكنك اختيار مدى، فيزا، ماستر، أو أبل باي")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // زر الدفع
                    if payHyper,
                       selectedBrand == .apple,
                       canShowApplePay
                    {
                        ApplePaySection {
                            startHyperpayPayment(for: selectedGroupId, isShare: selectedIsShare)
                            showPaymentOptions = false
                        }
                        .frame(height: 50)
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                    } else {
                        Button {
                            if payHyper {
                                startHyperpayPayment(for: selectedGroupId, isShare: selectedIsShare)
                            } else if payTamara {
                                startTamaraCheckout(for: selectedGroupId, isShare: selectedIsShare)
                            }
                            showPaymentOptions = false
                        } label: {
                            Text("الاستمرار للدفع")
                                .font(.system(size: 17, weight: .bold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GradientPrimaryButton(fontSize: 17, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 50, radius: 14))
                        .padding(.vertical, 10)
                    }
                }
                .padding(.top, 6)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.13), radius: 14, x: 0, y: 7)
                )
            }
        } customize: {
            $0.type(.toast)
              .position(.bottom)
              .animation(.spring())
              .closeOnTapOutside(true)
              .backgroundColor(Color.black.opacity(0.27))
              .useKeyboardSafeArea(true)
        }
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
        .overlay(alertObservers)
        // ⬅️ Overlay إضافي للودينج الخاص بـ HyperPaymentViewModel (مع الحفاظ على القديم)
        .overlay {
            if hyperPaymentViewModel.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            getDetails()
        }
    }
    
    @ViewBuilder
    func paymentChoiceButton(icon: String, title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(isActive ? .white : .gray)
                    .frame(width: 22, height: 22)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isActive ? .white : .black)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isActive ? Color.primary : Color.gray.opacity(0.09))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.primary : Color.gray.opacity(0.3), lineWidth: isActive ? 0 : 1)
            )
            .shadow(color: isActive ? Color.primary.opacity(0.10) : Color.clear, radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    var productImageView: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImageView(
                width: UIScreen.main.bounds.width,
                height: 320,
                cornerRadius: 10,
                imageURL: viewModel.product?.image?.toURL(),
                placeholder: Image(systemName: "photo"),
                contentMode: .fill
            )
            .frame(maxWidth: .infinity)

            Button(action: {
                withAnimation { addToFavorite() }
            }) {
                Image(systemName: viewModel.product?.isFavorite ?? false ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.product?.isFavorite ?? false ? .red : .gray)
                    .font(.title2)
                    .padding(10)
            }
            .background(Color.white.opacity(0.8).cornerRadius(8))
            .padding()
        }
    }
    
    var productDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.product?.name ?? "")
                .customFont(weight: .bold, size: 16)
                .foregroundColor(.primaryBlack())

            HStack {
                HStack {
                    Text(String(format: "%.2f", viewModel.product?.sale_price ?? 0))
                    Text(LocalizedStringKey.sar)
                }
                .customFont(weight: .semiBold, size: 14)
                .foregroundColor(.primary())

                Spacer()

                RatingView(rating: .constant(viewModel.product?.rate?.toInt() ?? 0))
            }

            if let attributes = viewModel.product?.attributes, !attributes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("الأنواع")
                        .customFont(weight: .bold, size: 14)
                        .foregroundColor(.primary())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(attributes.flatMap { $0.options ?? [] }, id: \ .sku) { option in
                                Text(option.name ?? "")
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(selectedName == option.name ? Color.primary() : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedName == option.name ? .white : .black)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.primary().opacity(selectedName == option.name ? 0 : 0.4), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        selectedName = option.name ?? ""
                                        selectedSku = option.sku ?? ""
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }

            Text(viewModel.product?.description ?? "")
                .customFont(weight: .regular, size: 14)
                .foregroundColor(.primaryBlack())
        }
        .padding(.horizontal, 16)
    }
    
    var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                addToCart()
            } label: {
                HStack(spacing: 4) {
                    Image("ic_w_cart")
                    Text(LocalizedStringKey.addToCart)
                }
            }
            .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
            .padding(.horizontal, 16)

            Button {
                if let attributes = viewModel.product?.attributes, !attributes.isEmpty, selectedSku.isEmpty {
                    appRouter.toggleAppPopup(.alertError("", "يرجى اختيار نوع المنتج قبل إضافته إلى امنياتك."))
                    return
                }
                showAddToMyWishes.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image("ic_wish")
                    Text(LocalizedStringKey.addToMyWishes)
                }
            }
            .buttonStyle(PrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryLight(), foreground: .primary(), height: 48, radius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    func paymentButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label)
                    .customFont(weight: .bold, size: 16)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primary())
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private func handleTamaraRedirect(url: URL) {
        let urlStr = url.absoluteString
        showTamaraPayment = false

        if urlStr.contains("wishy.sa/tamara/success") {
            submitWish(group_id: selectedGroupId, type: "public", isShare: selectedIsShare)
        } else if urlStr.contains("wishy.sa/tamara/failure") {
            orderViewModel.errorMessage = "فشلت عملية الدفع"
        } else if urlStr.contains("wishy.sa/tamara/cancel") {
            orderViewModel.errorMessage = "تم إلغاء عملية الدفع"
        }

        // بغض النظر عن الحالة، أغلق الفيو
        showTamaraPayment = false
        orderViewModel.isLoading = false
    }

    func getDetails() {
        viewModel.getProductDetails(id: productId ?? "") 
    }

    func addToCart() {
        if let attributes = viewModel.product?.attributes, !attributes.isEmpty, selectedSku.isEmpty {
            appRouter.toggleAppPopup(.alertError("", "يرجى اختيار نوع المنتج قبل إضافته إلى السلة."))
            return
        }

        let params: [String: Any] = [
            "product_id": productId ?? "",
            "qty": 1,
            "variation_name": selectedName,
            "variation_sku": selectedSku
        ]
        
        print("ssss \(params)")

        cartViewModel.addToCart(params: params, onsuccess: {
            // handle success
            print("222")
            DispatchQueue.main.async {
                self.showAddToCartPopup = true
            }
        })
    }

    func addToFavorite() {
        let params: [String: Any] = [
            "product_id": productId ?? ""
        ]
        viewModel.addToFavorite(params: params) {
            getDetails()
        }
    }

    func addToMyWish(group_id: String, type: String, isShare: Bool) {
        if type == "public" {
            // خزّن القيم لنعيد استخدامها بعد الدفع
            selectedGroupId = group_id
            selectedIsShare = isShare
            showPaymentOptions = true // إظهار بوابات الدفع
            showRetailAlertView = false
            return
        }

        // إذا كانت خاصة يتم الإضافة مباشرة
        submitWish(group_id: group_id, type: type, isShare: isShare)
    }

    func submitWish(group_id: String, type: String, isShare: Bool) {
        let body: [String: Any] = [
            "product_id": productId ?? "",
            "group_id": group_id,
            "type": type, // "public" أو "private"
            "isShare": String(isShare),
            "total": viewModel.product?.sale_price ?? 0,
            "pays": "",
            "variation_name": selectedName,
            "variation_sku": selectedSku
        ]

        wishesViewModel.addWish(params: body) { _, _ in
            appRouter.navigateBack()
        }
    }
    
    func startHyperpayPayment(for groupId: String, isShare: Bool) {
        let amount = exploreCost
        orderViewModel.isLoading = true
        selectedGroupId = groupId
        selectedIsShare = isShare
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
                submitWish(group_id: selectedGroupId, type: "public", isShare: selectedIsShare)
            } else {
                orderViewModel.errorMessage = "فشلت عملية الدفع"
            }
        }
    }

    func startTamaraCheckout(for groupId: String, isShare: Bool) {
        let amount = exploreCost
        let productId = viewModel.product?.id ?? ""

        let tamaraBody = TamaraBody(
            amount: amount,
            products: [
                TamaraProduct(
                    product_id: productId,
                    variation_name: selectedName,
                    variation_sku: selectedSku,
                    qty: 1
                )
            ]
        )

        orderViewModel.isLoading = true
        selectedGroupId = groupId
        selectedIsShare = isShare

        orderViewModel.tamaraCheckout(params: tamaraBody) {
            self.checkoutUrl = orderViewModel.tamaraCheckout?.checkout_url ?? ""
            //            self.checkoutUrl = "https://raw.githack.com/KarimAmsha/my-project/main/index.html"
            
            // Initialize the Tamara view model with the new URL and merchantURL
            self.tamaraViewModel = TamaraWebViewModel(
                url: self.checkoutUrl,
                merchantURL: TamaraMerchantURL(
                    success: "https://wishy.sa/tamara/success",
                    failure: "https://wishy.sa/tamara/failure",
                    cancel: "https://wishy.sa/tamara/cancel",
                    notification: "https://wishy.sa/tamara/cancel"
                )
            )

            showTamaraPayment = true
        }
    }
    
    var alertObservers: some View {
        VStack {
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )

            MessageAlertObserverView(
                message: $cartViewModel.errorMessage,
                alertType: .constant(.error)
            )

            MessageAlertObserverView(
                message: $wishesViewModel.errorMessage,
                alertType: $wishesViewModel.alertType.orDefault(.error)
            )
            
            MessageAlertObserverView(
                message: $orderViewModel.errorMessage,
                alertType: $wishesViewModel.alertType.orDefault(.error)
            )
        }
        .opacity(0)
    }
}

struct AddToCartPopup: View {
    @Binding var isPresented: Bool
    var onGoToCart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 تمت إضافة المنتج إلى السلة")
                .customFont(weight: .bold, size: 16)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(action: {
                    isPresented = false
                }) {
                    Text("استمرار بالتسوق")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primaryLight())
                        .foregroundColor(.primary())
                        .cornerRadius(10)
                }

                Button(action: {
                    isPresented = false
                    onGoToCart()
                }) {
                    Text("الذهاب إلى السلة")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.primary())
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding()
    }
}

