//
//  TabBarIcon.swift
//  Wishy
//
//  Created by Karim Amsha on 28.04.2024.
//

import SwiftUI

struct TabBarIcon: View {
    
    @StateObject var appState: AppState
    let assignedPage: Page
    @ObservedObject private var settings = UserSettings()
    @EnvironmentObject var cartViewModel: CartViewModel

    let width, height: CGFloat
    let iconName, tabName: String
    let isAddButton: Bool
    let isCart: Bool?

    var body: some View {
        VStack(spacing: 0) {
            if isAddButton {
                HStack {
                    Spacer()
                    
                    ZStack {
                        Text("+")
                            .customFont(weight: .bold, size: 13)
                            .foregroundColor(appState.currentPage == assignedPage ? Color.primary() : Color.gray595959())
                    }
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(appState.currentPage == assignedPage ? Color.primary() : Color.gray595959(), lineWidth: 2)
                    )
                    .padding(10)

                    Spacer()
                }
            } else {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        Image(appState.currentPage == assignedPage ? "\(iconName)_s" : iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width, height: height)

                        Text(tabName)
                            .customFont(weight: appState.currentPage == assignedPage ? .bold : .regular, size: 12)
                            .foregroundColor(appState.currentPage == assignedPage ? .primary() : .primaryBlack())
                    }

                    if (isCart ?? false), cartViewModel.cartCount > 0 {
                        Text("\(min(cartViewModel.cartCount, 99))") 
                            .customFont(weight: .bold, size: 10)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 1)
                            .offset(x: 3, y: -2)
                            .allowsHitTesting(false)
                            .transition(.scale)
                    }
                }
            }
        }
        .onTapGesture {
            appState.currentPage = assignedPage
        }
        // الاستماع لأي إشعارات تعديل على السلة من باقي الواجهات
        .onReceive(NotificationCenter.default.publisher(for: .cartUpdated)) { _ in
            cartViewModel.fetchCartCount()
        }
    }
}

#Preview {
    TabBarIcon(appState: AppState(), assignedPage: .home, width: 38, height: 38, iconName: "ic_home", tabName: LocalizedStringKey.home, isAddButton: false, isCart: false)
        .environmentObject(CartViewModel(errorHandling: ErrorHandling()))
}

