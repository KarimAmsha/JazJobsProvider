//
//  HomeView.swift
//  Wishy
//
//  Created by Karim Amsha on 28.04.2024.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var ordersVM = OrderViewModel(errorHandling: ErrorHandling())
    @State private var selectedTab: OrdersTab = .current
    
    // حالات التبويب
    private let currentStatuses: [OrderStatus] = [.new, .accepted, .started, .way, .progress, .updated, .prefinished]
    private let previousStatuses: [OrderStatus] = [.finished, .canceled]
    
    // تقسيم الطلبات حسب التبويب
    private var filteredOrders: [OrderModel] {
        let source = ordersVM.orders
        switch selectedTab {
        case .current:
            return source.filter { model in
                guard let st = model.orderStatus else { return false }
                return currentStatuses.contains(st)
            }
        case .previous:
            return source.filter { model in
                guard let st = model.orderStatus else { return false }
                return previousStatuses.contains(st)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                headerView
                
                tabsView
                    .padding(.horizontal, 16)
                
                if ordersVM.isLoading && ordersVM.orders.isEmpty {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            if filteredOrders.isEmpty {
                                DefaultEmptyView(title: LocalizedStringKey.noOrdersFound)
                                    .padding(.top, 24)
                            } else {
                                ForEach(filteredOrders, id: \.id) { item in
                                    HomeOrderCardView(order: item) {
                                        appRouter.navigate(to: .orderDetails(item.id ?? ""))
                                    }
                                }
                            }
                            
                            if ordersVM.shouldLoadMoreData {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        // نجلب المزيد بدون فلتر حالة (ثم نفلتر محليًا)
                                        ordersVM.loadMoreOrders(status: nil, limit: 10)
                                    }
                            }
                            
                            if ordersVM.isFetchingMoreData {
                                LoadingView()
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
        }
        .padding(.top, 8)
        .background(Color.background())
        .onAppear {
            // نجلب كل الطلبات مرة واحدة (ثم نفلتر محليًا)
            if ordersVM.orders.isEmpty {
                ordersVM.getOrders(status: nil, page: 0, limit: 10)
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $ordersVM.errorMessage,
                alertType: .constant(.error)
            )
        )
    }
}

// MARK: - Subviews
extension HomeView {
    // هيدر ترحيبي (RTL): الصورة أولًا ثم البيانات، والجرس يسار
    private var headerView: some View {
        HStack(spacing: 12) {
            
            // يمين: الصورة أولًا ثم بيانات المستخدم (محاذاة leading)
            HStack(spacing: 10) {
                // الصورة في أقصى اليمين
                AsyncImageView(
                    width: 40,
                    height: 40,
                    cornerRadius: 20,
                    imageURL: UserSettings.shared.user?.image?.toURL(),
                    placeholder: Image(systemName: "person.crop.circle"),
                    contentMode: .fill
                )
                
                // النصوص بمحاذاة leading
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("مرحبًا")
                            .customFont(weight: .bold, size: 16)
                            .foregroundColor(.black1F1F1F())
                        Text("👋")
                    }
                    
                    Text(UserSettings.shared.user?.full_name ?? "")
                        .customFont(weight: .regular, size: 12)
                        .foregroundColor(.gray8F8F8F())
                }
            }
            
            Spacer()

            // يسار: زر الجرس
            Button {
                appRouter.navigate(to: .notifications)
            } label: {
                Image("ic_bell")
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // تبويب “الطلبات الحالية / الطلبات السابقة” مع خط سفلي متحرك
    private var tabsView: some View {
        VStack(spacing: 8) {
            HStack {
                tabButton(title: LocalizedStringKey.currentOrders, tab: .current)
                Spacer()
                tabButton(title: LocalizedStringKey.previousOrders, tab: .previous)
            }
            
            ZStack(alignment: selectedTab == .current ? .leading : .trailing) {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: 1)
                
                Rectangle()
                    .fill(Color.primary())
                    .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: selectedTab)
            }
        }
    }
    
    private func tabButton(title: String, tab: OrdersTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                selectedTab = tab
            }
        } label: {
            Text(title)
                .customFont(weight: selectedTab == tab ? .bold : .regular, size: 14)
                .foregroundColor(selectedTab == tab ? .primary() : .black1F1F1F())
        }
    }
}

// MARK: - Card View (مطابقة للصور قدر الإمكان بالبيانات المتاحة)
private struct HomeOrderCardView: View {
    let order: OrderModel
    let onTap: () -> Void
    
    private var companyName: String {
        order.supplierId?.name ?? "Company"
    }
    
    private var dateText: String {
        order.formattedCreateDate ?? ""
    }
    
    private var descriptionText: String {
        order.items?.first?.localizedDescription ?? ""
    }
    
    private var status: OrderStatus? {
        order.orderStatus
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // رأس البطاقة: التاريخ + اسم الشركة + شعار
            HStack(alignment: .top) {
                Text(dateText)
                    .customFont(weight: .regular, size: 12)
                    .foregroundColor(.black1F1F1F())
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(companyName)
                        .customFont(weight: .bold, size: 14)
                        .foregroundColor(.black1F1F1F())
                    
                    if let logo = order.supplierId?.image?.toURL() {
                        AsyncImageView(
                            width: 28,
                            height: 28,
                            cornerRadius: 6,
                            imageURL: logo,
                            placeholder: Image(systemName: "photo"),
                            contentMode: .fill
                        )
                    }
                }
            }
            
            // وصف مختصر (أخذناه من أول منتج في الطلب)
            if !descriptionText.isEmpty {
                Text(descriptionText)
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.black222020())
                    .lineLimit(3)
            }
            
            // شارة الحالة
            if let st = status {
                let colors = st.colors
                Text(st.value)
                    .customFont(weight: .regular, size: 12)
                    .foregroundColor(colors.foreground)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(colors.background)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .onTapGesture { onTap() }
    }
}

// MARK: - تبويب الطلبات
private enum OrdersTab {
    case current
    case previous
}

#Preview {
    HomeView()
        .environmentObject(AppRouter())
}
