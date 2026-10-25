//
//  AuraStudioView.swift
//
//
//  Created by thebinhdx on 24/10/26.
//

import SwiftUI
import Cocoa

// MARK: - Effect Mode Types (GA401QM Simplified)
public enum AuraEffectCategory: String, CaseIterable, Identifiable {
    case staticMode = "Static"
    case breathing = "Breathing"
    case strobing = "Strobing"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .staticMode: return "lightbulb.fill"
        case .breathing: return "water.waves"
        case .strobing: return "bolt.fill"
        }
    }

    public var subtitle: String {
        switch self {
        case .staticMode: return "Steady illumination"
        case .breathing: return "Rhythmic fading pulse"
        case .strobing: return "High-energy pulse"
        }
    }
}

// MARK: - Main Aura Studio View for GA401QM

public struct AuraStudioView: View {
    @ObservedObject var service = AuraService.shared

    @State private var selectedEffect: AuraEffectCategory = .staticMode
    @State private var brightnessLevel: Int = 3 // 0: Off, 1: 33%, 2: 66%, 3: 100%

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                // 1. Model Header Info
                HStack {
                    Text("GA401QM Hardware Backlight Studio")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("GA401QM")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ROGColor.accent.opacity(0.2))
                        .foregroundColor(ROGColor.accent)
                        .clipShape(Capsule())
                }

                // 2. Seamless Keyboard Deck Preview
                AuraGA401KeyboardDeck(selectedEffect: selectedEffect, brightnessLevel: brightnessLevel)

                // 3. Lighting Effect Cards Gallery (Static, Breathing, Strobing)
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Lighting Effects", systemImage: "sparkles")

                    HStack(spacing: 10) {
                        ForEach(AuraEffectCategory.allCases) { effect in
                            EffectVisualCard(
                                effect: effect,
                                isSelected: selectedEffect == effect
                            ) {
                                selectedEffect = effect
                                applyEffect(effect)
                            }
                        }
                    }
                }

                // 4. Brightness & Hardware Control Deck
                VStack(alignment: .leading, spacing: 14) {
                    Text("Backlight Brightness")
                        .font(ROGType.bodyEmphasized())
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        ForEach([(0, "Off"), (1, "33%"), (2, "66%"), (3, "100%")], id: \.0) { level, title in
                            Button(action: {
                                brightnessLevel = level
                                service.setBrightness(level)
                            }) {
                                Text(title)
                                    .font(.system(size: 12, weight: brightnessLevel == level ? .bold : .regular))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(brightnessLevel == level ? ROGColor.accent.opacity(0.2) : Color(NSColor.controlBackgroundColor).opacity(0.4))
                                    .foregroundColor(brightnessLevel == level ? ROGColor.accent : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: ROGRadius.control, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ROGRadius.control, style: .continuous)
                                            .stroke(brightnessLevel == level ? ROGColor.accent : ROGColor.hairline, lineWidth: brightnessLevel == level ? 1.2 : 0.6)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .glassCard(radius: ROGRadius.card, padding: 16)
            }
            .padding(18)
        }
    }

    private func applyEffect(_ effect: AuraEffectCategory) {
        switch effect {
        case .staticMode:
            service.applySingleColor(.white)
        case .breathing:
            service.applyBreathing(c1: .white, c2: nil, speed: service.currentSpeed)
        case .strobing:
            service.applyStrobing(color: .white, speed: service.currentSpeed)
        }
    }
}

// MARK: - Keyboard Deck Preview for GA401QM

struct AuraGA401KeyboardDeck: View {
    let selectedEffect: AuraEffectCategory
    let brightnessLevel: Int

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // Dedicated Top Hotkeys Row
            HStack(spacing: 8) {
                KeyboardHotkeyPill(title: "VOL -", icon: "speaker.minus")
                KeyboardHotkeyPill(title: "VOL +", icon: "speaker.plus")
                KeyboardHotkeyPill(title: "MIC MUTE", icon: "mic.slash")
                KeyboardHotkeyPill(title: "ROG", icon: "flame.fill", isAccent: true)
                Spacer()
            }
            .frame(width: 630)

            // Keyboard Matrix Preview
            VStack(spacing: 4.5) {
                // Function Row
                HStack(spacing: 3.5) {
                    Keycap(label: "ESC", width: 36, color: glowColor)
                    Spacer().frame(width: 10)
                    ForEach(1...12, id: \.self) { i in
                        Keycap(label: "F\(i)", width: 29, color: glowColor)
                    }
                    Spacer().frame(width: 14)
                    Keycap(label: "DEL", width: 32, color: glowColor)
                    Keycap(label: "PRT", width: 32, color: glowColor)
                    Keycap(label: "PAU", width: 32, color: glowColor)
                }
                .frame(width: 630, alignment: .leading)

                // Standard QWERTY Layout Preview Rows
                // (Hiển thị trực quan bàn phím gọn gàng)
                HStack(spacing: 3.5) {
                    Keycap(label: "TAB", width: 44, color: glowColor)
                    ForEach(["Q","W","E","R","T","Y","U","I","O","P"], id: \.self) { l in
                        Keycap(label: l, width: 30, color: glowColor, isWASD: l == "W")
                    }
                    Keycap(label: "[", width: 30, color: glowColor)
                    Keycap(label: "]", width: 30, color: glowColor)
                    Keycap(label: "\\", width: 40, color: glowColor)
                }
                .frame(width: 630, alignment: .leading)

                HStack(spacing: 3.5) {
                    Keycap(label: "CAPS", width: 52, color: glowColor)
                    ForEach(["A","S","D","F","G","H","J","K","L"], id: \.self) { l in
                        Keycap(label: l, width: 30, color: glowColor, isWASD: ["A","S","D"].contains(l))
                    }
                    Keycap(label: ";", width: 30, color: glowColor)
                    Keycap(label: "'", width: 30, color: glowColor)
                    Keycap(label: "ENTER", width: 65.5, color: glowColor)
                }
                .frame(width: 630, alignment: .leading)

                HStack(spacing: 3.5) {
                    Keycap(label: "SHIFT", width: 76, color: glowColor)
                    ForEach(["Z","X","C","V","B","N","M"], id: \.self) { l in
                        Keycap(label: l, width: 30, color: glowColor)
                    }
                    Keycap(label: ",", width: 30, color: glowColor)
                    Keycap(label: ".", width: 30, color: glowColor)
                    Keycap(label: "/", width: 30, color: glowColor)
                    Keycap(label: "SHIFT", width: 75, color: glowColor)
                }
                .frame(width: 630, alignment: .leading)

                HStack(spacing: 3.5) {
                    Keycap(label: "CTRL", width: 36, color: glowColor)
                    Keycap(label: "FN", width: 26, color: glowColor)
                    Keycap(label: "OPT", width: 26, color: glowColor)
                    Keycap(label: "CMD", width: 36, color: glowColor)
                    Keycap(label: "SPACEBAR", width: 201, color: glowColor)
                    Keycap(label: "CMD", width: 36, color: glowColor)
                    Keycap(label: "OPT", width: 26, color: glowColor)
                    Spacer().frame(width: 12)
                    Keycap(label: "◄", width: 24, height: 23, color: glowColor)
                    VStack(spacing: 2) {
                        Keycap(label: "▲", width: 24, height: 10.5, color: glowColor)
                        Keycap(label: "▼", width: 24, height: 10.5, color: glowColor)
                    }
                    Keycap(label: "►", width: 24, height: 23, color: glowColor)
                }
                .frame(width: 630, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ROGColor.hairline, lineWidth: 0.75)
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .glassCard(radius: ROGRadius.card, padding: 16)
    }

    private var glowColor: Color {
        guard brightnessLevel > 0 else { return Color.white.opacity(0.1) }
        let opacity = Double(brightnessLevel) / 3.0
        return Color.white.opacity(0.4 + 0.5 * opacity)
    }
}

// MARK: - Supporting Components

struct EffectVisualCard: View {
    let effect: AuraEffectCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? ROGColor.accent.opacity(0.2) : Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)

                        Image(systemName: effect.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSelected ? ROGColor.accent : .secondary)
                    }

                    Spacer()

                    if isSelected {
                        Circle()
                            .fill(ROGColor.accent)
                            .frame(width: 7, height: 7)
                    }
                }

                Text(effect.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Text(effect.subtitle)
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ROGRadius.tile, style: .continuous)
                    .fill(isSelected ? ROGColor.accentSoft : Color(NSColor.controlBackgroundColor).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ROGRadius.tile, style: .continuous)
                    .stroke(isSelected ? ROGColor.accent : ROGColor.hairline, lineWidth: isSelected ? 1.5 : 0.75)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct Keycap: View {
    let label: String
    let width: CGFloat
    var height: CGFloat = 23
    let color: Color
    var isWASD: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                .fill(
                    isWASD
                        ? LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.80)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.black.opacity(0.75), Color.black.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                )

            RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                .fill(color.opacity(isWASD ? 0.85 : 0.45))

            Text(label)
                .font(.system(size: label.count > 3 ? 8.5 : 10.0, weight: isWASD ? .heavy : .bold, design: .rounded))
                .foregroundColor(isWASD ? .black : .white.opacity(0.95))
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                .stroke(isWASD ? ROGColor.accent.opacity(0.85) : color.opacity(0.6), lineWidth: isWASD ? 1.2 : 0.5)
        )
    }
}

struct KeyboardHotkeyPill: View {
    let title: String
    let icon: String
    var isAccent: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8.5, weight: .bold))
            Text(title)
                .font(.system(size: 8.5, weight: .semibold))
        }
        .foregroundColor(isAccent ? ROGColor.accent : .secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(ROGRadius.control)
        .overlay(
            RoundedRectangle(cornerRadius: ROGRadius.control)
                .stroke(isAccent ? ROGColor.accent.opacity(0.5) : ROGColor.hairline, lineWidth: 0.5)
        )
    }
}
