//
//  GeneralErrorToastView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI

struct GeneralErrorToastView: View {
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.red)
                .cornerRadius(24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .customFont(weight: .bold, size: 16)
                Text(message)
                    .customFont(weight: .bold, size: 16)
                    .opacity(0.8)
            }
            
            Spacer()
        }
        .foregroundColor(.black)
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 42, trailing: 16))
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 40, x: 0, y: -4)
    }
}

enum ToastType {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}

struct GeneralToastView: View {
    let type: ToastType
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: type.icon)
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(type.color)
                .cornerRadius(24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .customFont(weight: .bold, size: 16)
                Text(message)
                    .customFont(weight: .bold, size: 16)
                    .opacity(0.8)
            }
            
            Spacer()
        }
        .foregroundColor(.black)
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 42, trailing: 16))
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 40, x: 0, y: -4)
    }
}

enum AlertType {
    case success, error, info
}

struct GeneralAlertToastView: View {
    let title: String
    let message: String
    var type: AlertType

    var iconName: String {
        switch type {
        case .success: return "info.circle"//"checkmark.circle.fill"
        case .error: return "info.circle"//"xmark.circle.fill"
        case .info: return "info.circle"//"info.circle.fill"
        }
    }

    var iconColor: Color {
        switch type {
        case .success: return .primary()//.green
        case .error: return .primary()//.red
        case .info: return .primary()//.blue
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(iconColor)
                .cornerRadius(24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .customFont(weight: .bold, size: 16)
                Text(message)
                    .customFont(weight: .regular, size: 14)
                    .opacity(0.8)
            }

            Spacer()
        }
        .foregroundColor(.black)
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 42, trailing: 16))
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 40, x: 0, y: -4)
    }
}
