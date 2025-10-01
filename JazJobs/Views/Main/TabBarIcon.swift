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
    
    // دعم أيقونات النظام (SF Symbols)
    let systemIconName: String?
    let selectedSystemIconName: String?

    private var isSelected: Bool {
        appState.currentPage == assignedPage
    }
    
    // مُهيّئ مخصص لدعم systemIconName و selectedSystemIconName
    init(
        appState: AppState,
        assignedPage: Page,
        width: CGFloat,
        height: CGFloat,
        iconName: String,
        tabName: String,
        isAddButton: Bool,
        isCart: Bool? = nil,
        systemIconName: String? = nil,
        selectedSystemIconName: String? = nil
    ) {
        _appState = StateObject(wrappedValue: appState)
        self.assignedPage = assignedPage
        self.width = width
        self.height = height
        self.iconName = iconName
        self.tabName = tabName
        self.isAddButton = isAddButton
        self.isCart = isCart
        self.systemIconName = systemIconName
        self.selectedSystemIconName = selectedSystemIconName
    }

    var body: some View {
        VStack(spacing: 0) {
            if isAddButton {
                HStack {
                    Spacer()
                    
                    ZStack {
                        Text("+")
                            .customFont(weight: .bold, size: 13)
                            .foregroundColor(isSelected ? Color.primary() : Color.gray595959())
                    }
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.primary() : Color.gray595959(), lineWidth: 2)
                    )
                    .padding(10)

                    Spacer()
                }
            } else {
                VStack(spacing: 6) {
                    // مؤشر التحديد العلوي
                    Capsule()
                        .fill(isSelected ? Color.primary() : Color.clear)
                        .frame(width: 24, height: 4)
                        .opacity(isSelected ? 1 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isSelected)

                    ZStack(alignment: .topTrailing) {
                        // خلفية كبسولة خفيفة عند التحديد
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary().opacity(0.12))
                                    .frame(width: max(width + 16, 44), height: max(height + 16, 36))
                                    .transition(.opacity.combined(with: .scale))
                            }

                            // صورة الأيقونة (نظام أو أصول)
                            iconView
                                .frame(width: width, height: height)
                                .foregroundColor(isSelected ? .primary() : .grayA4ACAD())
                                .padding(isSelected ? 6 : 0)
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isSelected)

                        // شارة العربة (تظل فعالة فقط إن كانت التبويب هو السلة)
                        if (isCart ?? false), cartViewModel.cartCount > 0 {
                            Text("\(min(cartViewModel.cartCount, 99))") 
                                .customFont(weight: .bold, size: 10)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(radius: 1)
                                .offset(x: 8, y: -6)
                                .allowsHitTesting(false)
                                .transition(.scale)
                        }
                    }

                    Text(tabName)
                        .customFont(weight: isSelected ? .bold : .regular, size: 11)
                        .foregroundColor(isSelected ? .primary() : .grayA4ACAD())
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
                .padding(.top, 6)
                .padding(.bottom, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                appState.currentPage = assignedPage
            }
        }
        // الاستماع لأي إشعارات تعديل على السلة من باقي الواجهات
        .onReceive(NotificationCenter.default.publisher(for: .cartUpdated)) { _ in
            cartViewModel.fetchCartCount()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(tabName))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    // يختار بين SF Symbol أو صورة من الأصول
    @ViewBuilder
    private var iconView: some View {
        if let systemIconName {
            let selectedName = selectedSystemIconName ?? systemIconName
            Image(systemName: isSelected ? selectedName : systemIconName)
                .resizable()
                .scaledToFit()
        } else {
            Image(isSelected ? "\(iconName)_s" : iconName)
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview {
    TabBarIcon(
        appState: AppState(),
        assignedPage: .home,
        width: 22,
        height: 22,
        iconName: "ic_home",
        tabName: LocalizedStringKey.home,
        isAddButton: false,
        isCart: false
    )
    .environmentObject(CartViewModel(errorHandling: ErrorHandling()))
}
