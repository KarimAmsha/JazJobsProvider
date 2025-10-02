//
//  CategoriesView.swift
//  Wishy
//
//  Created by Karim Amsha on 30.04.2024.
//

import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var appRouter: AppRouter
    @State private var searchText: String = ""
    let items = Array(1...10)

    private let sampleImageURL = URL(string: "https://media.zid.store/cdn-cgi/image/f=auto/https://media.zid.store/ca6f01a7-f802-4c28-b793-b6c642a7f178/42610e71-37fa-471e-aa72-b5e11fb658a7.jpg")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey.publicCategories)
                .customFont(weight: .bold, size: 16)
                .foregroundColor(.primaryBlack())

            horizontalCategories()

            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey.specialCategories)
                    .customFont(weight: .bold, size: 16)
                    .foregroundColor(.primaryBlack())

                gridCategories()
            }
        }
        .padding(16)
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(LocalizedStringKey.publicCategories)
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
    }

    // MARK: - Subviews

    @ViewBuilder
    private func horizontalCategories() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<10, id: \.self) { index in
                    categoryBubble(index: index)
                }
            }
        }
    }

    @ViewBuilder
    private func categoryBubble(index: Int) -> some View {
        VStack(spacing: 8) {
            AsyncImageView(
                width: 20,
                height: 20,
                cornerRadius: 0,
                imageURL: sampleImageURL,
                placeholder: Image(systemName: "photo"),
                contentMode: .fill
            )
            .padding(25)
            .roundedBackground(cornerRadius: 35, strokeColor: .grayEBF0FF(), lineWidth: 1)
            .padding(.bottom, 4)

            Text("Item \(index + 1)")
                .customFont(weight: .light, size: 10)
                .foregroundColor(.gray9098B1())
        }
    }

    @ViewBuilder
    private func gridCategories() -> some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(items, id: \.self) { index in
                    gridItem(index: index)
                }
            }
        }
    }

    @ViewBuilder
    private func gridItem(index: Int) -> some View {
        VStack(spacing: 8) {
            AsyncImageView(
                width: 150,
                height: 150,
                cornerRadius: 10,
                imageURL: sampleImageURL,
                placeholder: Image(systemName: "photo"),
                contentMode: .fill
            )
            .cornerRadius(4)
            .padding(6)

            Text("Item \(index)")
                .customFont(weight: .bold, size: 14)
                .foregroundColor(.primaryBlack())
                .padding(.bottom, 4)
        }
        .roundedBackground(cornerRadius: 4, strokeColor: .grayEBF0FF(), lineWidth: 1)
        .onTapGesture {
            appRouter.navigate(to: .productsListView(nil))
        }
    }
}

#Preview {
    CategoriesView()
}
