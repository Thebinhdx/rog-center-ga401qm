//
//  FanControlModels.swift
//  
//
//  Created by thebinhdx on 24/10/26.
//

import SwiftUI

// MARK: - Performance Modes (GA401QM)

public enum ROGPerformanceMode: String, CaseIterable, Identifiable, Codable {
    case silent = "Silent"
    case balanced = "Balanced"
    case turbo = "Turbo"
    case manual = "Manual"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .silent: return "leaf.fill"
        case .balanced: return "scalemass.fill"
        case .turbo: return "flame.fill"
        case .manual: return "slider.horizontal.3"
        }
    }

    public var subtitle: String {
        switch self {
        case .silent: return "Energy efficient and quiet fan."
        case .balanced: return "Balancing everyday performance."
        case .turbo: return "Turn on maximum CPU/GPU power."
        case .manual: return "Customize the fan chart manually."
        }
    }

    public var accentColor: Color {
        switch self {
        case .silent: return ROGColor.good
        case .balanced: return ROGColor.info
        case .turbo: return ROGColor.accent
        case .manual: return Color.purple
        }
    }
}

// MARK: - Custom Fan Curve Data Node

public struct FanCurvePoint: Identifiable, Equatable, Codable {
    public let id: UUID
    public var tempCelsius: Int     // 30°C - 100°C
    public var fanSpeedPercent: Int  // 0% - 100%

    public init(id: UUID = UUID(), tempCelsius: Int, fanSpeedPercent: Int) {
        self.id = id
        self.tempCelsius = max(30, min(100, tempCelsius))
        self.fanSpeedPercent = max(0, min(100, fanSpeedPercent))
    }
}
