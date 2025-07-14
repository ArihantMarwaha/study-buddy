import SwiftUI

// MARK: - Formatting Toolbar
struct FormattingToolbar: View {
    @Binding var fontSize: CGFloat
    @Binding var textColor: Color
    @Binding var backgroundColor: Color
    @Binding var borderColor: Color
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var isUnderlined: Bool
    @Binding var isStrikethrough: Bool
    @Binding var cornerRadius: CGFloat
    @Binding var borderWidth: CGFloat
    @Binding var opacity: Double
    @Binding var fontFamily: String
    @Binding var showCustomizationPanel: Bool
    let onFormattingChange: () -> Void
    // Remove zoomScale and showGrid for StudyBuddy integration
    let fontFamilies = ["System", "Helvetica", "Times", "Courier", "Georgia", "Verdana"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Main toolbar
            HStack(spacing: 16) {
                // Text formatting buttons
                HStack(spacing: 8) {
                    FormatButton(
                        icon: "bold",
                        isActive: isBold,
                        action: {
                            isBold.toggle()
                            onFormattingChange()
                        }
                    )
                    
                    FormatButton(
                        icon: "italic",
                        isActive: isItalic,
                        action: {
                            isItalic.toggle()
                            onFormattingChange()
                        }
                    )
                    
                    FormatButton(
                        icon: "underline",
                        isActive: isUnderlined,
                        action: {
                            isUnderlined.toggle()
                            onFormattingChange()
                        }
                    )
                    
                    FormatButton(
                        icon: "strikethrough",
                        isActive: isStrikethrough,
                        action: {
                            isStrikethrough.toggle()
                            onFormattingChange()
                        }
                    )
                }
                
                Divider()
                    .frame(height: 20)
                
                // Font size controls
                HStack(spacing: 8) {
                    Button(action: {
                        fontSize = max(10, fontSize - 2)
                        onFormattingChange()
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    
                    Text("\(Int(fontSize))")
                        .font(.system(size: 12, weight: .medium))
                        .frame(minWidth: 20)
                    
                    Button(action: {
                        fontSize = min(32, fontSize + 2)
                        onFormattingChange()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Text color picker
                HStack(spacing: 8) {
                    Image(systemName: "textformat")
                        .font(.system(size: 14))
                    
                    ColorPicker("", selection: $textColor)
                        .frame(width: 30, height: 30)
                        .onChange(of: textColor) { _ in
                            onFormattingChange()
                        }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Customization toggle
                Button(action: {
                    showCustomizationPanel.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14))
                        Text("Customize")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(showCustomizationPanel ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(showCustomizationPanel ? .white : .primary)
                .cornerRadius(6)
            }
            
            // Customization panel
            if showCustomizationPanel {
                CustomizationPanel(
                    backgroundColor: $backgroundColor,
                    borderColor: $borderColor,
                    cornerRadius: $cornerRadius,
                    borderWidth: $borderWidth,
                    opacity: $opacity,
                    fontFamily: $fontFamily,
                    fontFamilies: fontFamilies,
                    onFormattingChange: onFormattingChange
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.top, 20)
    }
}

// MARK: - Customization Panel
struct CustomizationPanel: View {
    @Binding var backgroundColor: Color
    @Binding var borderColor: Color
    @Binding var cornerRadius: CGFloat
    @Binding var borderWidth: CGFloat
    @Binding var opacity: Double
    @Binding var fontFamily: String
    let fontFamilies: [String]
    let onFormattingChange: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Colors row
            HStack(spacing: 20) {
                // Background color
                VStack(spacing: 4) {
                    Text("Background")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    ColorPicker("", selection: $backgroundColor)
                        .frame(width: 40, height: 30)
                        .onChange(of: backgroundColor) { _ in
                            onFormattingChange()
                        }
                }
                
                // Border color
                VStack(spacing: 4) {
                    Text("Border")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    ColorPicker("", selection: $borderColor)
                        .frame(width: 40, height: 30)
                        .onChange(of: borderColor) { _ in
                            onFormattingChange()
                        }
                }
                
                Divider()
                    .frame(height: 30)
                
                // Font family
                VStack(spacing: 4) {
                    Text("Font")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Picker("Font", selection: $fontFamily) {
                        ForEach(fontFamilies, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                    .onChange(of: fontFamily) { _ in
                        onFormattingChange()
                    }
                }
            }
            
            // Sliders row
            HStack(spacing: 20) {
                // Corner radius
                VStack(spacing: 4) {
                    Text("Roundness: \(Int(cornerRadius))")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Slider(value: $cornerRadius, in: 0...20, step: 1)
                        .frame(width: 80)
                        .onChange(of: cornerRadius) { _ in
                            onFormattingChange()
                        }
                }
                
                // Border width
                VStack(spacing: 4) {
                    Text("Border: \(Int(borderWidth))")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Slider(value: $borderWidth, in: 0...5, step: 1)
                        .frame(width: 80)
                        .onChange(of: borderWidth) { _ in
                            onFormattingChange()
                        }
                }
                
                // Opacity
                VStack(spacing: 4) {
                    Text("Opacity: \(Int(opacity * 100))%")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.1)
                        .frame(width: 80)
                        .onChange(of: opacity) { _ in
                            onFormattingChange()
                        }
                }
            }
            
            // Preset colors row
            HStack(spacing: 8) {
                Text("Presets:")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                
                ForEach(presetColors, id: \.name) { preset in
                    Button(action: {
                        backgroundColor = preset.background
                        borderColor = preset.border
                        onFormattingChange()
                    }) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(preset.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(preset.border, lineWidth: 2)
                            )
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var presetColors: [(name: String, background: Color, border: Color)] {
        [
            ("Yellow", Color.yellow.opacity(0.8), Color.yellow),
            ("Blue", Color.blue.opacity(0.3), Color.blue),
            ("Green", Color.green.opacity(0.3), Color.green),
            ("Pink", Color.pink.opacity(0.3), Color.pink),
            ("Orange", Color.orange.opacity(0.3), Color.orange),
            ("Purple", Color.purple.opacity(0.3), Color.purple),
            ("Gray", Color.gray.opacity(0.3), Color.gray)
        ]
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isActive ? .white : .primary)
        }
        .buttonStyle(.plain)
        .padding(8)
        .background(isActive ? Color.blue : Color.gray.opacity(0.2))
        .cornerRadius(6)
    }
}

// MARK: - Text Extension for Italic, Underline, and Strikethrough
extension Text {
    func italic(_ isItalic: Bool) -> Text {
        if isItalic {
            return self.italic()
        }
        return self
    }
    
    func underline(_ isUnderlined: Bool) -> Text {
        if isUnderlined {
            return self.underline()
        }
        return self
    }
    
    func strikethrough(_ isStrikethrough: Bool) -> Text {
        if isStrikethrough {
            return self.strikethrough()
        }
        return self
    }
} 