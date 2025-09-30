//
//  WelcomeView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI
import PopupView

struct WelcomeView: View {
    @State private var currentPage = 0
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var settings: UserSettings
    @StateObject private var viewModel = InitialViewModel(errorHandling: ErrorHandling())
    @State var loginStatus: LoginStatus = .welcome
    @ObservedObject var appRouter = AppRouter()
    @StateObject private var authViewModel = AuthViewModel(errorHandling: ErrorHandling())

    var body: some View {
        GeometryReader { geometry in
            NavigationStack(path: $appRouter.navPath) {
                ZStack {
                    if loginStatus == .welcome {
                        VStack(spacing: 20) {
                            VStack(spacing: 0) {
                                if viewModel.isLoading {
                                    LoadingView()
                                } else if let items = viewModel.welcomeItems {
                                    TabView(selection: $currentPage) {
                                        ForEach(0..<3, id: \.self) { index in
                                            WelcomeSlideView(item: items[index])
                                                .tag(index)
                                        }
                                    }
                                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                }
                                
                                ControlDots(numberOfPages: 3, currentPage: $currentPage)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Button {
                                        withAnimation {
                                            if currentPage < 2 {
                                                currentPage += 1
                                            } else if currentPage == 2 {
                                                loginStatus = .register
                                            }
                                        }
                                    } label: {
                                        Text(currentPage < 2 ? LocalizedStringKey.next : LocalizedStringKey.registerNow)
                                    }
                                    .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                                    
                                    if currentPage == 2 {
                                        Button {
                                            withAnimation {
                                                loginStatus = .login
                                            }
                                        } label: {
                                            Text(LocalizedStringKey.login)
                                        }
                                        .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                                    }
                                }
                                                                
                                Button {
                                    authViewModel.guest {
                                        settings.loggedIn = true
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text(LocalizedStringKey.discoverApp)
                                        Spacer()
                                        
                                    }
                                    .padding(.horizontal)
                                }
                                .buttonStyle(PrimaryButton(fontSize: 14, fontWeight: .regular, background: .clear, foreground: .primaryNormal(), height: 48, radius: 12))
                            }
                        }
                        .padding()
                        .background(Color.background())
                        .onAppear {
                            viewModel.fetchWelcomeItems()
                        }
                    } else {
                        AuthenticationView(loginStatus: $loginStatus)
                    }
                }
                .popup(isPresented: Binding<Bool>(
                    get: { appRouter.appPopup != nil },
                    set: { _ in appRouter.toggleAppPopup(nil) })
                ) {
                   if let popup = appRouter.appPopup {
                       switch popup {
                       case .alertError(let title, let message):
                           GeneralToastView(type: .error, title: title, message: message)
                       case .alertSuccess(let title, let message):
                           GeneralToastView(type: .success, title: title, message: message)
                       case .alertInfo(let title, let message):
                           GeneralToastView(type: .info, title: title, message: message)
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
}

#Preview {
    WelcomeView()
        .environmentObject(LanguageManager())
}
