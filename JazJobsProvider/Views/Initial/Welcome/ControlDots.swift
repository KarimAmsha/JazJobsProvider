//
//  ControlDots.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI

struct ControlDots: View {
    let numberOfPages: Int
    @Binding var currentPage: Int

    private let itemWidth: CGFloat = 100
    private let itemHeight: CGFloat = 4
    private let spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Capsule()
                    .fill(page == currentPage ? Color.green0CB057() : Color.blueLight())
                    .frame(width: itemWidth, height: itemHeight)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
    }
}
