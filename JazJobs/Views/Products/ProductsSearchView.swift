//
//  ProductsSearchView.swift
//  Wishy
//
//  Created by Karim Amsha on 29.05.2024.
//

import SwiftUI

struct ProductsSearchView: View {
    @ObservedObject var viewModel: InitialViewModel
    @EnvironmentObject var appRouter: AppRouter
    @State var searchText = ""
    @State var params: [String: Any] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SearchBar(text: $searchText)
                
                Button {
                    appRouter.navigate(to: .notifications)
                } label: {
                    Image("ic_bell")
                }
            }
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            ScrollView(showsIndicators: false) {
                if viewModel.isFetchingInitialProducts {
                    LoadingView().padding(.top, 40)
                } else if viewModel.products.isEmpty {
                    DefaultEmptyView(title: LocalizedStringKey.noDataFound)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.products, id: \.id) { item in
                            ProductItemView(item: item, onSelect: {
                                appRouter.navigate(to: .productDetails(item.id ?? ""))
                            })
                        }

                        if viewModel.shouldLoadMoreData {
                            Color.clear.onAppear {
                                loadMore()
                            }
                        }

                        if viewModel.isFetchingMoreData {
                            LoadingView()
                        }
                    }
                    .transition(.opacity) // optional for nice fade-in
                    .animation(.easeInOut(duration: 0.3), value: viewModel.products)
                }
            }

            Spacer()
        }
        .padding(16)
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

                    Text(LocalizedStringKey.searchForProduct)
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .onChange(of: searchText) { searchText in
            loadData()
        }
        .onAppear {
            if viewModel.products.isEmpty {
                loadData()
            }
        }
    }
}

#Preview {
    ProductsListView(viewModel: InitialViewModel(errorHandling: ErrorHandling()), specialCategory: nil)
}

extension ProductsSearchView {
    func loadData() {
        viewModel.products.removeAll()
        params = [
            "isOffer": false,
            "category_id": "",
            "special_id": "",
            "q": searchText,
        ]
        viewModel.getProducts(page: 0, limit: 10, params: params)
    }
    
    func loadMore() {
        viewModel.loadMoreProducts(limit: 10, params: params)
    }
}


