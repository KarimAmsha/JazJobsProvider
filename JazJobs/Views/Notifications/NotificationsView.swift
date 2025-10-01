//
//  NotificationsView.swift
//  Jaz Client
//
//  Created by Karim Amsha on 4.12.2023.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var settings: UserSettings
    @StateObject private var viewModel = NotificationsViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .top) {
            // خلفية تملىء الشاشة دائمًا
            Color.background()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                headerCard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.notificationsItems.isEmpty {
                            DefaultEmptyView(
                                title: LocalizedStringKey.noDataFound,
                                message: "لا توجد إشعارات لعرضها الآن.",
                                systemImage: "bell.badge"
                            )
                            .padding(.top, 24)
                            .frame(maxWidth: .infinity) // يضمن التوسّع عرضيًا
                        } else {
                            // نحتاج للفهرس لتمييز أول عنصر بخلفية
                            ForEach(Array(viewModel.notificationsItems.enumerated()), id: \.element) { index, item in
                                NotificationRowView(notification: item)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(index == 0 ? Color.blue.opacity(0.08) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        if item.notificationType == .orders {
                                            appRouter.navigate(to: .orderDetails(item.bodyParams ?? ""))
                                        }
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            deleteNotification(item)
                                        }) {
                                            Text(LocalizedStringKey.delete)
                                                .font(.system(size: 14, weight: .regular))
                                            Image(systemName: "trash")
                                        }
                                    }

                                // فاصل بين العناصر
                                if index != viewModel.notificationsItems.count - 1 {
                                    Divider()
                                        .padding(.leading, 12)
                                }
                            }

                            if viewModel.shouldLoadMoreData {
                                Color.clear.onAppear {
                                    loadMore()
                                }
                            }

                            if viewModel.isFetchingMoreData {
                                LoadingView()
                                    .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // يضمن ملء الشاشة
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image("ic_back")
                    }

                    Text(LocalizedStringKey.notifications)
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .onAppear {
            loadData()
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AppRouter())
        .environmentObject(UserSettings())
        .environmentObject(AppState())
}

extension NotificationsView {
    // هيدر بسيط: عنوان + وصف فقط، بدون أسهم وبدون شارات
    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey.notifications)
                    .customFont(weight: .bold, size: 18)
                    .foregroundColor(.black1F1F1F())

                Text("تصفح قائمة الإشعارات المستلمة")
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.gray8F8F8F())
            }
            .padding(16)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }

    func loadData() {
        viewModel.notificationsItems.removeAll()
        viewModel.fetchNotificationsItems(page: 0, limit: 10)
    }

    func loadMore() {
        viewModel.loadMoreNotifications(limit: 10)
    }

    func deleteNotification(_ notification: NotificationItem) {
        let alertModel = AlertModel(
            icon: "",
            title: LocalizedStringKey.delete,
            message: LocalizedStringKey.deleteMessage,
            hasItem: false,
            item: "",
            okTitle: LocalizedStringKey.ok,
            cancelTitle: "",
            hidesIcon: true,
            hidesCancel: true,
            onOKAction: {
                appRouter.togglePopup(nil)
                viewModel.deleteNotifications(id: notification.id ?? "") { _ in
                    loadData()
                }
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
