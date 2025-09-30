//
//  MyWishView.swift
//  Wishy
//
//  Created by Karim Amsha on 16.06.2024.
//

import SwiftUI

struct MyWishView: View {
    @EnvironmentObject var appRouter: AppRouter
    let wishId: String?
    @ObservedObject var viewModel: InitialViewModel
    @ObservedObject var cartViewModel = CartViewModel(errorHandling: ErrorHandling())
    @ObservedObject var wishesViewModel = WishesViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appState: AppState

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
                        
                        if let variationName = wishesViewModel.wish?.variation_name, !variationName.isEmpty {
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
                
                let isComplete = wishesViewModel.wish?.isComplete ?? false

                if isComplete {
                    Button {
                        appRouter.navigate(to: .wishCheckOut(wishId ?? ""))
                    } label: {
                        HStack(spacing: 4) {
                            Image("ic_w_gift")
                            Text("اتمام عملية الشراء")
                        }
                    }
                    .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                    .padding(.horizontal, 16)
                }
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
        .onAppear {
            laodWishData()
        }
    }
}

#Preview {
    MyWishView(wishId: "", viewModel: InitialViewModel(errorHandling: ErrorHandling()))
        .environmentObject(AppState())
}

extension MyWishView {
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
        cartViewModel.addToCart(params: params, onsuccess: {
            NotificationCenter.default.post(name: .cartUpdated, object: nil)
            showMessage()
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
                appState.currentPage = .cart
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
