//
//  MainView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI
import PopupView

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: UserSettings
    @State var showAddOrder = false
    @State private var path = NavigationPath()
    @EnvironmentObject var appRouter: AppRouter
    @StateObject var viewModel = InitialViewModel(errorHandling: ErrorHandling())

    var body: some View {
        NavigationStack(path: $appRouter.navPath) {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // محتوى الصفحة حسب التبويب الحالي
                    pageContent()
                        .background(Color.background())

                    // شريط التبويب
                    tabBar()
                        .background(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: -1)
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(Color.background(), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRouter.Destination.self) { destination in
                switch destination {
                case .profile:
                    ProfileView()
                case .editProfile:
                    EditProfileView()
                case .changePassword:
                    EmptyView()
                case .changePhoneNumber:
                    EmptyView()
                case .contactUs:
                    ContactUsView()
                case .rewards:
                    EmptyView()
                case .paymentSuccess:
                    SuccessView()
                case .constant(let item):
                    ConstantView(item: .constant(item))
                case .myOrders:
                    MyOrdersView()
                case .orderDetails(let orderID):
                    OrderDetailsView(orderID: orderID)
                case .upcomingReminders:
                    UpcomingRemindersView()
                case .productsListView(let specialCategory):
                    ProductsListView(viewModel: viewModel, specialCategory: specialCategory)
                case .productDetails(let id):
                    ProductDetailsView(viewModel: viewModel, productId: id)
                case .selectedGiftView:
                    SelectedGiftView()
                case .friendWishes(let user):
                    FriendWishesView(user: user)
                case .friendWishesListView:
                    FriendWishesListView()
                case .friendWishesDetailsView(let id):
                    FriendWishesDetailsView(wishId: id, viewModel: viewModel)
                case .retailFriendWishesView:
                    RetailFriendWishesView()
                case .retailPaymentView(let id):
                    RetailPaymentView(wishId: id)
                case .addressBook:
                    AddressBookView()
                case .addAddressBook:
                    AddAddressView()
                case .editAddressBook(let item):
                    EditAddressView(addressItem: item)
                case .addressBookDetails(let item):
                    AddressDetailsView(addressItem: item)
                case .notifications:
                    NotificationsView()
                case .checkoutView(let cartItems):
                    CheckoutView(cartItems: cartItems)
                case .productsSearchView:
                    ProductsSearchView(viewModel: viewModel)
                case .wishesView:
                    WishesView()
                case .userProducts(let id):
                    UserProductsView(viewModel: viewModel, id: id)
                case .addUserProduct:
                    AddUserProductView(viewModel: viewModel)
                case .VIPGiftView(let type):
                    VIPGiftView(viewModel: viewModel, categoryType: type)
                case .userWishes(let userId, let groupId):
                    UserWishesView(userId: userId, group_id: groupId)
                case .wishCheckOut(let id):
                    WishCheckOutView(wishId: id)
                case .walletView:
                    WalletView()
                case .explorWishView(let id):
                    ExplorWishView(wishId: id, viewModel: viewModel)
                case .myWishView(let id):
                    MyWishView(wishId: id, viewModel: viewModel)
                case .addReview(let id):
                    AddReviewView(orderId: id)
                case let .chat(chatId, currentUserId, receiverId):
                    ChatDetailView(chatId: chatId, currentUserId: currentUserId, receiverId: receiverId)
                }
            }
            .popup(isPresented: Binding<Bool>(
                get: { appRouter.activePopup != nil },
                set: { _ in appRouter.togglePopup(nil) })
            ) {
               if let popup = appRouter.activePopup {
                   switch popup {
                   case .cancelOrder(let alertModel):
                       AlertView(alertModel: alertModel)
                   case .alert(let alertModel):
                       AlertView(alertModel: alertModel)
                   case .inputAlert(let alertModelWithInput):
                       InputAlertView(alertModel: alertModelWithInput)
                   }
               }
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
            .popup(isPresented: Binding<Bool>(
                get: { appRouter.appPopup != nil },
                set: { _ in appRouter.toggleAppPopup(nil) })
            ) {
                if let popup = appRouter.appPopup {
                    switch popup {
                    case .alertError(let title, let message):
                        GeneralAlertToastView(title: title, message: message, type: .error)
                    case .alertSuccess(let title, let message):
                        GeneralAlertToastView(title: title, message: message, type: .success)
                    case .alertInfo(let title, let message):
                        GeneralAlertToastView(title: title, message: message, type: .info)
                    }
                }
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
        }
        .accentColor(.black)
        .environmentObject(appRouter)
    }
}

// MARK: - Subviews
extension MainView {
    @ViewBuilder
    private func pageContent() -> some View {
        switch appState.currentPage {
        case .home:
            HomeView() // الطلبات
        case .messages:
            // الرسائل: قائمة الدردشة إن كان المستخدم مسجلاً الدخول
            if settings.id == nil {
                CustomeEmptyView()
            } else {
                ChatListView(userId: settings.id ?? "")
            }
        case .notifications:
            // الإشعارات
            if settings.id == nil {
                CustomeEmptyView()
            } else {
                NotificationsView()
            }
        case .discover:
            // الاستكشاف
            ExplorView()
        case .more:
            if settings.id == nil {
                CustomeEmptyView()
            } else {
                ProfileView() // الإعدادات
            }
        }
    }

    @ViewBuilder
    private func tabBar() -> some View {
        VStack(spacing: 0) {
            CustomDivider()
            HStack {
                TabBarIcon(
                    appState: appState,
                    assignedPage: .home,
                    width: 22, height: 22,
                    iconName: "",
                    tabName: LocalizedStringKey.orders,
                    isAddButton: false,
                    isCart: false,
                    systemIconName: "house",
                    selectedSystemIconName: "house.fill"
                )

                Spacer()

                TabBarIcon(
                    appState: appState,
                    assignedPage: .messages,
                    width: 22, height: 22,
                    iconName: "",
                    tabName: LocalizedStringKey.messages, // الرسائل
                    isAddButton: false,
                    isCart: false,
                    systemIconName: "bubble.left.and.bubble.right",
                    selectedSystemIconName: "bubble.left.and.bubble.right.fill"
                )

                Spacer()

                TabBarIcon(
                    appState: appState,
                    assignedPage: .discover,
                    width: 22, height: 22,
                    iconName: "",
                    tabName: LocalizedStringKey.discover, // الاستكشاف
                    isAddButton: false,
                    isCart: false,
                    systemIconName: "safari",
                    selectedSystemIconName: "safari.fill"
                )

                Spacer()

                TabBarIcon(
                    appState: appState,
                    assignedPage: .notifications,
                    width: 22, height: 22,
                    iconName: "",
                    tabName: LocalizedStringKey.notifications, // الإشعارات
                    isAddButton: false,
                    isCart: false,
                    systemIconName: "bell",
                    selectedSystemIconName: "bell.fill"
                )

                Spacer()

                TabBarIcon(
                    appState: appState,
                    assignedPage: .more,
                    width: 22, height: 22,
                    iconName: "",
                    tabName: LocalizedStringKey.settings,
                    isAddButton: false,
                    isCart: false,
                    systemIconName: "gearshape",
                    selectedSystemIconName: "gearshape.fill"
                )
            }
            .padding(.horizontal)
            .frame(height: 64)
        }
    }
}

#Preview {
    MainView()
        .environmentObject(UserSettings())
        .environmentObject(AppState())
        .environmentObject(AppRouter())
}
