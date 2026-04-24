//  PresenceApp
//  GlassTextField.swift
//  Created: 2026-04-24
//  Purpose: Glass-styled input field used throughout onboarding. Wraps
//           SwiftUI TextField with a glass capsule, leading prefix
//           (optional), and focus ring.

import SwiftUI

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var prefix: String?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never
    var isSecure: Bool = false
    var maxLength: Int?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            }
            if let prefix {
                Text(prefix)
                    .font(Typography.headline)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
            }
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(Typography.body)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .focused($isFocused)
            .foregroundStyle(PresenceColors.presenceWhite)
            .onChange(of: text) { _, newValue in
                if let maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassField(isFocused: isFocused)
    }
}

private extension View {
    @ViewBuilder
    func glassField(isFocused: Bool) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            isFocused
                                ? PresenceColors.auroraBlue.opacity(0.8)
                                : PresenceColors.presenceWhite.opacity(0.12),
                            lineWidth: 1
                        )
                )
        } else {
            self
                .background(.regularMaterial, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            isFocused
                                ? PresenceColors.auroraBlue.opacity(0.8)
                                : PresenceColors.presenceWhite.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
    }
}

#Preview {
    @Previewable @State var phone = ""
    @Previewable @State var username = ""
    return ZStack {
        PresenceBackground()
        VStack(spacing: 20) {
            GlassTextField(
                placeholder: "(415) 555-0199",
                text: $phone,
                systemImage: "phone.fill",
                prefix: "+1",
                keyboardType: .phonePad,
                textContentType: .telephoneNumber
            )
            GlassTextField(
                placeholder: "morningfern",
                text: $username,
                prefix: "@",
                maxLength: 24
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
