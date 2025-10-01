//
//  DefaultEmptyView.swift
//  Wishy
//
//  Created by Karim Amsha on 13.02.2024.
//

import SwiftUI

struct DefaultEmptyView: View {
    // Mandatory
    let title: String
    
    // Optional customizations
    var message: String? = nil
    var systemImage: String? = "tray"
    var imageName: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            
            ZStack {
                Circle()
                    .fill(Color.primary().opacity(0.10))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1 : 0.85)
                
                Circle()
                    .stroke(Color.primary().opacity(0.15), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .opacity(animate ? 1 : 0.2)
                
                // أيقونة ديناميكية (صورة من الأصول أو SF Symbol)
                iconView
                    .scaleEffect(animate ? 1 : 0.9)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animate)
            
            Text(title)
                .multilineTextAlignment(.center)
                .customFont(weight: .bold, size: 16)
                .foregroundColor(.black1F1F1F())
                .padding(.horizontal)
            
            if let message = message, !message.isEmpty {
                Text(message)
                    .multilineTextAlignment(.center)
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.grayA4ACAD())
                    .padding(.horizontal, 24)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(
                    PrimaryButton(
                        fontSize: 14,
                        fontWeight: .bold,
                        background: .primary(),
                        foreground: .white,
                        height: 44,
                        radius: 12
                    )
                )
                .padding(.top, 8)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 24)
        .onAppear {
            animate = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}

extension DefaultEmptyView {
    @ViewBuilder
    private var iconView: some View {
        if let img = imageName {
            Image(img)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
        } else if let sys = systemImage {
            Image(systemName: sys)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.primary())
                .symbolRenderingMode(.hierarchical)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        DefaultEmptyView(
            title: LocalizedStringKey.noOrdersFound,
            message: "لا توجد عناصر لعرضها الآن. حاول تحديث الصفحة لاحقًا.",
            systemImage: "doc.text.magnifyingglass",
            actionTitle: "تحديث",
            action: {}
        )
        
        DefaultEmptyView(
            title: "لا توجد نتائج",
            message: "جرّب تعديل معايير البحث.",
            imageName: "ic_logo"
        )
    }
    .padding()
}
