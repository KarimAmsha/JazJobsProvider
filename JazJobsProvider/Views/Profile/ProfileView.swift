//
//  ProfileView.swift
//  Wishy
//
//  Created by Karim Amsha on 30.04.2024.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var initialViewModel = InitialViewModel(errorHandling: ErrorHandling())
    @StateObject private var authViewModel = AuthViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appState: AppState

    // حالة سويتش الإشعارات (يمكن ربطها لاحقًا بإعدادات النظام/السيرفر)
    @State private var notificationsEnabled: Bool = true

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? "Version \(version)" : "Version \(version) (\(build))"
    }

    var body: some View {
        ZStack {
            Color.background().ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard

                    VStack(spacing: 0) {
                        // صف الإشعارات مع Toggle
                        SettingRow(
                            title: LocalizedStringKey.notifications,
                            subtitle: LocalizedStringKey.notificationHint,
                            icon: Image("ic_b_bell"),
                            tint: .blueEBF0FC(),
                            iconForeground: .blue3A70E2()
                        ) {
                            // لا يوجد onTap، لدينا Toggle في trailing
                        } trailing: {
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: .green0C9D61()))
                        }

                        Divider().padding(.leading, 60)

                        // من نحن؟
                        SettingRow(
                            title: LocalizedStringKey.aboutUs,
                            subtitle: LocalizedStringKey.aboutUsHint,
                            icon: Image("ic_support"),
                            tint: .blueEBF0FC(),
                            iconForeground: .blue3A70E2()
                        ) {
                            if let item = initialViewModel.constantsItems?.first(where: { $0.constantType == .about }) {
                                appRouter.navigate(to: .constant(item))
                            }
                        }

                        Divider().padding(.leading, 60)

                        // سياسة الاستخدام والخصوصية
                        SettingRow(
                            title: LocalizedStringKey.termsOfUseAndPrivacyPolicy,
                            subtitle: LocalizedStringKey.termsOfUseAndPrivacyPolicyHint,
                            icon: Image("ic_lock"),
                            tint: .blueEBF0FC(),
                            iconForeground: .blue3A70E2()
                        ) {
                            // افتح privacy إن توفر، وإلا using
                            if let item = initialViewModel.constantsItems?.first(where: { $0.constantType == .privacy }) {
                                appRouter.navigate(to: .constant(item))
                            } else if let item = initialViewModel.constantsItems?.first(where: { $0.constantType == .using }) {
                                appRouter.navigate(to: .constant(item))
                            }
                        }

                        Divider().padding(.leading, 60)

                        // حذف الحساب
                        SettingRow(
                            title: LocalizedStringKey.deleteAccount,
                            subtitle: LocalizedStringKey.deleteAccountHint,
                            icon: Image("ic_delete"),
                            tint: Color.orangeFCE5E5(),
                            iconForeground: .redE50000()
                        ) {
                            deleteAccount()
                        }

                        Divider().padding(.leading, 60)

                        // تسجيل الخروج
                        SettingRow(
                            title: LocalizedStringKey.logout,
                            subtitle: LocalizedStringKey.logoutHint,
                            icon: Image("ic_logout"),
                            tint: Color.orangeFCE5E5(),
                            iconForeground: .redE50000()
                        ) {
                            logout()
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    // فوتر الإصدار
                    Text(appVersionString)
                        .customFont(weight: .regular, size: 12)
                        .foregroundColor(.grayA4ACAD())
                        .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(LocalizedStringKey.applicationSettings)
                    .customFont(weight: .bold, size: 20)
                    .foregroundColor(Color.primaryBlack())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Image("ic_bell")
                    .onTapGesture {
                        appRouter.navigate(to: .notifications)
                    }
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $authViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .onAppear {
            getConstants()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
        .environmentObject(AppState())
}

// MARK: - Header
extension ProfileView {
    private var headerCard: some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncImageView(
                width: 44,
                height: 44,
                cornerRadius: 8,
                imageURL: UserSettings.shared.user?.image?.toURL(),
                placeholder: Image(systemName: "person.crop.square"),
                contentMode: .fill
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(LocalizedStringKey.applicationSettings)
                        .customFont(weight: .bold, size: 18)
                        .foregroundColor(.black1F1F1F())
                    Text("✨")
                }

                Text(LocalizedStringKey.settingsHint)
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.gray8F8F8F())
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            
            // زر الجرس يسار الهيدر (اختياري لأن لدينا نفس الزر في التولبار)
            Image("ic_bell")
                .padding(8)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                .onTapGesture {
                    appRouter.navigate(to: .notifications)
                }


        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Row View
private struct SettingRow<Trailing: View>: View {
    let title: String
    let subtitle: String
    let icon: Image
    var tint: Color = .blueEBF0FC()
    var iconForeground: Color = .blue3A70E2()
    var action: (() -> Void)? = nil
    @ViewBuilder var trailing: Trailing

    init(
        title: String,
        subtitle: String,
        icon: Image,
        tint: Color = .blueEBF0FC(),
        iconForeground: Color = .blue3A70E2(),
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.iconForeground = iconForeground
        self.action = action
        self.trailing = trailing()
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tint)
                        .frame(width: 44, height: 44)
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(iconForeground)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .customFont(weight: .bold, size: 14)
                        .foregroundColor(.black1F1F1F())

                    Text(subtitle)
                        .customFont(weight: .regular, size: 12)
                        .foregroundColor(.gray8F8F8F())
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                trailing
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Actions
extension ProfileView {
    private func getConstants() {
        initialViewModel.fetchConstantsItems()
    }

    private func logout() {
        let alertModel = AlertModel(
            icon: "",
            title: LocalizedStringKey.logout,
            message: LocalizedStringKey.logoutMessage,
            hasItem: false,
            item: nil,
            okTitle: LocalizedStringKey.logout,
            cancelTitle: LocalizedStringKey.back,
            hidesIcon: true,
            hidesCancel: true
        ) {
            authViewModel.logoutUser {
                appState.currentPage = .home
            }
            appRouter.dismissPopup()
        } onCancelAction: {
            appRouter.dismissPopup()
        }

        appRouter.togglePopup(.alert(alertModel))
    }

    private func deleteAccount() {
        let alertModel = AlertModel(
            icon: "",
            title: LocalizedStringKey.deleteAccount,
            message: LocalizedStringKey.deleteAccountMessage,
            hasItem: false,
            item: nil,
            okTitle: LocalizedStringKey.deleteAccount,
            cancelTitle: LocalizedStringKey.back,
            hidesIcon: true,
            hidesCancel: true
        ) {
            authViewModel.deleteAccount {
                appState.currentPage = .home
            }
            appRouter.dismissPopup()
        } onCancelAction: {
            appRouter.dismissPopup()
        }

        appRouter.togglePopup(.alert(alertModel))
    }
}
