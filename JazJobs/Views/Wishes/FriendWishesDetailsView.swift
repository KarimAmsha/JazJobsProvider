//
//  FriendWishesDetailsView.swift
//  Wishy
//
//  Created by Karim Amsha on 1.05.2024.
//

import SwiftUI
import PopupView

struct FriendWishesDetailsView: View {
    @EnvironmentObject var appRouter: AppRouter
    let wishId: String?
    @ObservedObject var viewModel: InitialViewModel
    @ObservedObject var cartViewModel = CartViewModel(errorHandling: ErrorHandling())
    @ObservedObject var wishesViewModel = WishesViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appState: AppState
    @State private var showAddToCartPopup = false

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isLoading || wishesViewModel.isLoading {
                        LoadingView()
                    }

                    // ZStack to overlay favorite button on top of the image
                    ZStack(alignment: .topTrailing) {
                        AsyncImageView(
                            width: UIScreen.main.bounds.width,
                            height: 320,
                            cornerRadius: 10,
                            imageURL: wishesViewModel.wish?.product_id?.image?.toURL(),
                            placeholder: Image(systemName: "photo"),
                            contentMode: .fill
                        )
                        .frame(maxWidth: .infinity)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(wishesViewModel.wish?.product_id?.name ?? "")
                            .customFont(weight: .bold, size: 16)
                            .foregroundColor(.primaryBlack())

                        HStack {
                            HStack {
                                Text(String(format: "%.2f", wishesViewModel.wish?.product_id?.sale_price ?? 0))
                                Text(LocalizedStringKey.sar)
                            }
                            .customFont(weight: .semiBold, size: 14)
                            .foregroundColor(.primary())
                            
                            Spacer()
                            
                            RatingView(rating: .constant(wishesViewModel.wish?.product_id?.rate?.toInt() ?? 0))
                        }
                        
                        HStack {
                            HStack {
                                Text(wishesViewModel.wish?.all_pays?.toString() ?? "")
                                Text(LocalizedStringKey.sar)
                            }
                            Spacer()
                            HStack {
                                Text(wishesViewModel.wish?.pays?.count.toString())
                                Text("مساهم")
                            }
                        }
                        .customFont(weight: .semiBold, size: 12)
                        .foregroundColor(.primary())
                        
                        var percentage: Double {
                            wishesViewModel.wish?.all_pays?.percentage(of: wishesViewModel.wish?.total ?? 0.0) ?? 0.0
                        }

                        ProgressLineView(percentage: percentage)
                            .frame(height: 10)
                        
                        if let variationName = wishesViewModel.wish?.product_id?.variation_name, !variationName.isEmpty {
                            Text("النوع: \(variationName)")
                                .customFont(weight: .regular, size: 12)
                                .foregroundColor(.primary())
                        }

                        Text(wishesViewModel.wish?.product_id?.description ?? "")
                            .customFont(weight: .regular, size: 14)
                            .foregroundColor(.primaryBlack())
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Spacer()

            VStack {
                CustomDivider()
                
                let isShared = wishesViewModel.wish?.isShare ?? false
                let isComplete = wishesViewModel.wish?.isComplete ?? false
                
                Button {
                    if isShared && !isComplete {
                        appRouter.navigate(to: .retailPaymentView(wishId ?? ""))
                    } else {
                        addToCart()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image("ic_w_gift")
                        Text(isShared && !isComplete
                             ? "ساهم بقطّة منك لتحقيق أمنية!"
                             : LocalizedStringKey.addToCart)
                    }
                }
                .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                .padding(.horizontal, 16)
            }
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

                    Text(wishesViewModel.wish?.product_id?.name ?? "")
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $wishesViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .overlay(
            MessageAlertObserverView(
                message: $cartViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .popup(isPresented: $showAddToCartPopup) {
            AddToCartPopup(isPresented: $showAddToCartPopup) {
                // ما يحدث عند "الذهاب إلى السلة"
                appState.currentPage = .home
                appRouter.navigateBack()
            }
        } customize: {
            $0.type(.toast)
              .position(.bottom)
              .animation(.spring())
              .closeOnTapOutside(true)
              .backgroundColor(Color.black.opacity(0.27))
              .useKeyboardSafeArea(true)
        }
        .onAppear {
            laodWishData()
        }
    }
}

#Preview {
    FriendWishesDetailsView(wishId: "", viewModel: InitialViewModel(errorHandling: ErrorHandling()))
        .environmentObject(AppState())
}

extension FriendWishesDetailsView { 
    func laodWishData() {
        wishesViewModel.getWish(id: wishId ?? "")
    }
    
    func addToCart() {
        let params: [String: Any] = [
            "product_id": wishesViewModel.wish?.product_id?.id ?? "",
            "qty": 1,
            "variation_name": wishesViewModel.wish?.product_id?.variation_name ?? "",
            "variation_sku": wishesViewModel.wish?.product_id?.variation_sku ?? ""
        ]
        print("kkkk \(params)")

        cartViewModel.addToCart(params: params, onsuccess: {
            // handle success
            DispatchQueue.main.async {
                print("mmm")
                showAddToCartPopup = true
            }
            NotificationCenter.default.post(name: .cartUpdated, object: nil)
        })
    }
    
    private func showMessage() {
        let alertModel = AlertModel(
            icon: "",
            title: "",
            message: LocalizedStringKey.cartMessage,
            hasItem: false,
            item: "",
            okTitle: LocalizedStringKey.ok,
            cancelTitle: LocalizedStringKey.back,
            hidesIcon: true,
            hidesCancel: false,
            onOKAction: {
                appRouter.togglePopup(nil)
                appRouter.navigateBack()
                appState.currentPage = .home
            },
            onCancelAction: {
                withAnimation {
                    appRouter.togglePopup(nil)
                }
            }
        )

        appRouter.togglePopup(.alert(alertModel))
    }
}
