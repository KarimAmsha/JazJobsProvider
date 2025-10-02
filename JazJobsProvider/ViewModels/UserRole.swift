//
//  UserRole.swift
//  Wishy
//
//  Created by Your Name on 2025-10-02.
//

import Foundation

enum UserRole: String, Codable, CaseIterable, Sendable {
    case client = "client"
    case provider = "provider"
    case admin = "admin"
    case guest = "guest"
    case unknown = "unknown"

    // ترميز غير حساس لحالة الأحرف مع دعم قيم غير معروفة
    init(rawValueInsensitive value: String?) {
        let normalized = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self = UserRole(rawValue: normalized) ?? .unknown
    }
}

// دعم فك الترميز case-insensitive من JSON دون إعادة التصريح بـ Decodable
extension UserRole {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try? container.decode(String.self)
        self = UserRole(rawValueInsensitive: raw)
    }
}

// أسماء عرض عربية اختيارية
extension UserRole {
    var displayName: String {
        switch self {
        case .client:   return "عميل"
        case .provider: return "مقدم خدمة"
        case .admin:    return "مشرف"
        case .guest:    return "زائر"
        case .unknown:  return "غير معروف"
        }
    }
}
