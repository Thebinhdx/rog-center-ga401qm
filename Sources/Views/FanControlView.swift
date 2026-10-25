//
//  FanControlView.swift
//  
//
//  Created by thebinhdx on 24/10/26.
//

import SwiftUI
import AppKit

public struct FanControlView: View {
    @ObservedObject var telemetry = TelemetryService.shared
    @ObservedObject var service = AuraService.shared

    private var selectedMode: ROGPerformanceMode {
            service.activePerformanceMode
        }
    @State private var targetFanTab: Int = 0 // 0 = CPU Fan, 1 = GPU Fan

    // Default Fan Curve Nodes (8 Points)
    @State private var cpuFanCurve: [FanCurvePoint] = [
        FanCurvePoint(tempCelsius: 30, fanSpeedPercent: 0),
        FanCurvePoint(tempCelsius: 45, fanSpeedPercent: 20),
        FanCurvePoint(tempCelsius: 55, fanSpeedPercent: 35),
        FanCurvePoint(tempCelsius: 65, fanSpeedPercent: 50),
        FanCurvePoint(tempCelsius: 75, fanSpeedPercent: 70),
        FanCurvePoint(tempCelsius: 85, fanSpeedPercent: 85),
        FanCurvePoint(tempCelsius: 90, fanSpeedPercent: 100),
        FanCurvePoint(tempCelsius: 100, fanSpeedPercent: 100)
    ]

    @State private var gpuFanCurve: [FanCurvePoint] = [
        FanCurvePoint(tempCelsius: 30, fanSpeedPercent: 0),
        FanCurvePoint(tempCelsius: 45, fanSpeedPercent: 0),
        FanCurvePoint(tempCelsius: 55, fanSpeedPercent: 30),
        FanCurvePoint(tempCelsius: 65, fanSpeedPercent: 45),
        FanCurvePoint(tempCelsius: 75, fanSpeedPercent: 65),
        FanCurvePoint(tempCelsius: 85, fanSpeedPercent: 80),
        FanCurvePoint(tempCelsius: 90, fanSpeedPercent: 95),
        FanCurvePoint(tempCelsius: 100, fanSpeedPercent: 100)
    ]

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                // 1. Performance Mode Selection Bento Cards
                PerformanceModeSelectorGrid()

                // 2. Dual Fan Telemetry & Live RPM Controls
                HStack(spacing: 14) {
                    FanStatusBentoCard(
                        title: "CPU Fan (Ryzen 9)",
                        icon: "cpu",
                        currentRPM: telemetry.fan.cpuFanRPM,
                        maxRPM: telemetry.fan.maxFanRPM,
                        tempCelsius: telemetry.fan.cpuTempCelsius,
                        accentColor: .cyan,
                        isSelected: targetFanTab == 0
                    ) {
                        targetFanTab = 0
                    }

                    FanStatusBentoCard(
                        title: "GPU Fan (RTX 3060)",
                        icon: "play.square.stack.fill",
                        currentRPM: telemetry.fan.gpuFanRPM,
                        maxRPM: telemetry.fan.maxFanRPM,
                        tempCelsius: telemetry.fan.gpuTempCelsius,
                        accentColor: .purple,
                        isSelected: targetFanTab == 1
                    ) {
                        targetFanTab = 1
                    }
                }

                // 3. Interactive Fan Curve Graph & Node Editor
                InteractiveFanCurveBentoCard(
                    title: targetFanTab == 0 ? "CPU Custom Fan Curve" : "GPU Custom Fan Curve",
                    accentColor: targetFanTab == 0 ? .cyan : .purple,
                    nodes: targetFanTab == 0 ? $cpuFanCurve : $gpuFanCurve,
                    isManualMode: selectedMode == .manual
                )
            }
            .padding(18)
        }
    }
}

// MARK: - 1. Performance Mode Selector Grid

struct PerformanceModeSelectorGrid: View {
    @ObservedObject var service = AuraService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Performance Profile (Power & Thermals)", systemImage: "gauge.with.needle.fill")

            HStack(spacing: 10) {
                ForEach(ROGPerformanceMode.allCases) { mode in
                    let isSelected = (service.activePerformanceMode == mode)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            service.setPerformanceMode(mode)
                        }
                    }) {
                        PerformanceCardContent(mode: mode, isSelected: isSelected)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: ROGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ROGRadius.card, style: .continuous)
                .stroke(ROGColor.hairline, lineWidth: 0.6)
        )
    }
}

// Subview phụ trợ để giảm tải cho bộ biên dịch Swift (tránh lỗi type-check timeout)
struct PerformanceCardContent: View {
    let mode: ROGPerformanceMode
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? mode.accentColor : .secondary)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(mode.accentColor)
                        .frame(width: 6, height: 6)
                }
            }

            Text(mode.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .primary : .secondary)

            Text(mode.subtitle)
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ROGRadius.tile, style: .continuous)
                .fill(isSelected ? mode.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor).opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ROGRadius.tile, style: .continuous)
                .stroke(isSelected ? mode.accentColor : ROGColor.hairline, lineWidth: isSelected ? 1.5 : 0.6)
        )
    }
}

// MARK: - 2. Fan Status Bento Card

struct FanStatusBentoCard: View {
    let title: String
    let icon: String
    let currentRPM: Int
    let maxRPM: Int
    let tempCelsius: Int
    let accentColor: Color
    let isSelected: Bool
    let onSelect: () -> Void

    private var rpmPercent: Double {
        Double(currentRPM) / Double(max(1, maxRPM))
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Activity Gauge Ring
                ZStack {
                    ActivityRing(
                        progress: rpmPercent,
                        ringWidth: 6,
                        gradientColors: [accentColor.opacity(0.6), accentColor]
                    )
                    .frame(width: 52, height: 52)

                    Image(systemName: "fanblades.fill")
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(title)
                            .font(ROGType.bodyEmphasized())
                            .foregroundColor(.primary)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(currentRPM) RPM")
                            .font(ROGType.heroNumber())
                            .font(.system(size: 22))
                            .foregroundColor(.primary)

                        Text("\(Int(rpmPercent * 100))%")
                            .font(ROGType.caption())
                            .foregroundColor(.secondary)
                    }

                    Text("Temp: \(tempCelsius)°C • Max: \(maxRPM) RPM")
                        .font(ROGType.footnote())
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: ROGRadius.card, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ROGRadius.card, style: .continuous)
                    .stroke(isSelected ? accentColor : ROGColor.hairline, lineWidth: isSelected ? 1.2 : 0.6)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 3. Interactive Fan Curve Canvas & Drag Editor

struct InteractiveFanCurveBentoCard: View {
    let title: String
    let accentColor: Color
    @Binding var nodes: [FanCurvePoint]
    let isManualMode: Bool

    @State private var draggedNodeIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionLabel(title, systemImage: "chart.line.uptrend.xyaxis")

                Spacer()

                if !isManualMode {
                    AccentBadge("Presets Active (Read Only)", color: .secondary)
                } else {
                    AccentBadge("Manual Tuning Active", color: ROGColor.good)
                }
            }

            // Curve Graph Canvas Area
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Grid Lines
                    Path { p in
                        for i in 1...4 {
                            let y = h * (CGFloat(i) / 5.0)
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)

                    // Gradient Fill Area under curve
                    Path { p in
                        guard nodes.count > 1 else { return }
                        p.move(to: CGPoint(x: 0, y: h))

                        for node in nodes {
                            let pt = pointToCanvas(node: node, size: geo.size)
                            p.addLine(to: pt)
                        }

                        p.addLine(to: CGPoint(x: w, y: h))
                        p.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Curve Line Stroke
                    Path { p in
                        guard nodes.count > 1 else { return }
                        for (idx, node) in nodes.enumerated() {
                            let pt = pointToCanvas(node: node, size: geo.size)
                            if idx == 0 {
                                p.move(to: pt)
                            } else {
                                p.addLine(to: pt)
                            }
                        }
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // Draggable Control Nodes
                    ForEach(0..<nodes.count, id: \.self) { idx in
                        let pt = pointToCanvas(node: nodes[idx], size: geo.size)

                        Circle()
                            .fill(draggedNodeIndex == idx ? Color.white : accentColor)
                            .frame(width: 12, height: 12)
                            .shadow(color: accentColor.opacity(0.6), radius: 4)
                            .position(pt)
                            .gesture(
                                DragGesture()
                                    .onChanged { val in
                                        guard isManualMode else { return }
                                        draggedNodeIndex = idx
                                        updateNode(index: idx, dragLocation: val.location, size: geo.size)
                                    }
                                    .onEnded { _ in
                                        draggedNodeIndex = nil
                                    }
                            )
                    }
                }
            }
            .frame(height: 200)
            .padding(10)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: ROGRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ROGRadius.tile, style: .continuous)
                    .stroke(ROGColor.hairline, lineWidth: 0.5)
            )

            // Horizontal Node Adjustment Table
            HStack(spacing: 8) {
                ForEach(0..<nodes.count, id: \.self) { idx in
                    VStack(spacing: 2) {
                        Text("\(nodes[idx].tempCelsius)°C")
                            .font(ROGType.footnote())
                            .foregroundColor(.secondary)

                        Text("\(nodes[idx].fanSpeedPercent)%")
                            .font(ROGType.inlineNumber())
                            .foregroundColor(accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: ROGRadius.control, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: ROGRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ROGRadius.card, style: .continuous)
                .stroke(ROGColor.hairline, lineWidth: 0.6)
        )
    }

    // Convert Temp/Fan % to Canvas Coordinates
    private func pointToCanvas(node: FanCurvePoint, size: CGSize) -> CGPoint {
        let xNorm = CGFloat(node.tempCelsius - 30) / 70.0 // 30°C to 100°C
        let yNorm = CGFloat(node.fanSpeedPercent) / 100.0   // 0% to 100%

        let x = xNorm * size.width
        let y = size.height - (yNorm * size.height)
        return CGPoint(x: x, y: y)
    }

    // Drag Math to update Temp & Speed
    private func updateNode(index: Int, dragLocation: CGPoint, size: CGSize) {
        let clampedX = max(0, min(size.width, dragLocation.x))
        let clampedY = max(0, min(size.height, dragLocation.y))

        let newTemp = 30 + Int((clampedX / size.width) * 70.0)
        let newSpeed = Int(((size.height - clampedY) / size.height) * 100.0)

        // Keep Nodes Sorted by Temperature
        let minTemp = index > 0 ? nodes[index - 1].tempCelsius + 1 : 30
        let maxTemp = index < nodes.count - 1 ? nodes[index + 1].tempCelsius - 1 : 100

        nodes[index].tempCelsius = max(minTemp, min(maxTemp, newTemp))
        nodes[index].fanSpeedPercent = max(0, min(100, newSpeed))
    }
}
