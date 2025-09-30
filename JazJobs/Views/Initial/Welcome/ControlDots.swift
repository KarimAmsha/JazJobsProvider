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

    var body: some View {
        HStack {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Image(page == currentPage ? "ic_current_page_dot" : "ic_page_dot")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
    }
}
