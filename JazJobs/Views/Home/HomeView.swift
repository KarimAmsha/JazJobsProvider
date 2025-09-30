//
//  HomeView.swift
//  Wishy
//
//  Created by Karim Amsha on 28.04.2024.
//

import SwiftUI
import SkeletonUI
import RefreshableScrollView
import FirebaseMessaging

struct HomeView: View {
    @StateObject var viewModel = InitialViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appRouter: AppRouter
    @State private var searchText: String = ""
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @StateObject private var userViewModel = UserViewModel(errorHandling: ErrorHandling())

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    SearchBar2(text: $searchText) {
                        appRouter.navigate(to: .productsSearchView)
                    }

                    Button {
                        appRouter.navigate(to: .notifications)
                    } label: {
                        Image("ic_bell")
                    }
                }
                                
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            if let items = viewModel.homeItems, let sliders = items.slider {
                                VStack {
                                    TabView(selection: $currentIndex) {
                                        ForEach(sliders.indices, id: \.self) { index in
                                            if let imageUrl = sliders[index].image?.toURL() {
                                                AsyncImageView(
                                                    width: geometry.size.width - 32,
                                                    height: 150,
                                                    cornerRadius: 10,
                                                    imageURL: imageUrl,
                                                    placeholder: Image(systemName: "photo"),
                                                    contentMode: .fill
                                                )
                                                .tag(index)
                                            }
                                        }
                                    }
                                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                                    .frame(height: 150)
                                    .onReceive(timer) { _ in
                                        withAnimation {
                                            currentIndex = (currentIndex + 1) % sliders.count
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            if let categories = viewModel.homeItems?.category, categories.isEmpty {
                                DefaultEmptyView(title: LocalizedStringKey.noDataFound)
                            } else if let categories = viewModel.homeItems?.category {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(categories, id: \.self) { item in
                                        CategoryItemView(item: item, onSelect: {
                                            if item.categoryType == .wishes {
                                                appRouter.navigate(to: .wishesView)
                                            } else if item.categoryType == .events {
                                                appRouter.navigate(to: .upcomingReminders)
                                            } else if item.categoryType == .userProducts {
                                                appRouter.navigate(to: .userProducts(item.id ?? ""))
                                            } else if item.categoryType == .eventPreparation || item.categoryType == .giftVIP {
                                                appRouter.navigate(to: .VIPGiftView(item.categoryType))
                                            } else {
                                                appRouter.navigate(to: .productsListView(item))
                                            }
                                        })
                                    }
                                }
                            }
                            
                            let image = viewModel.homeItems?.whatsApp?.image ?? ""
                            CustomAsyncImage(imageURL: image.toURL(), cornerRadius: 10)
                                .padding(.top, 30)
                                .onTapGesture(perform: {
                                    openWhatsApp()
                                })
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: geometry.size.height)
        }
        .onAppear {
            getHome()
            viewModel.fetchContactItems()
            refreshFcmToken()
            print("token \(UserSettings.shared.token)")

        }
    }
    
    func openWhatsApp() {
        let phoneNumber = viewModel.whatsAppContactItem?.Data ?? ""
        
        if let url = URL(string: "https://wa.me/\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    HomeView()
}

extension HomeView {
    func getHome() {
        viewModel.fetchHomeItems()
    }
}

extension HomeView {
    func refreshFcmToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
            } else if let token = token {
                let params: [String: Any] = [
                    "id": UserSettings.shared.id ?? "",
                    "fcmToken": token
                ]
                userViewModel.refreshFcmToken(params: params, onsuccess: {
                    
                })
            }
        }
    }
}
