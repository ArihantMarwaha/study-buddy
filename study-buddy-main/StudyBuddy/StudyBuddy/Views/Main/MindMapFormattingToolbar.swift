import SwiftUI

struct MindMapFormattingToolbar: View {
    @Binding var fontSize: CGFloat
    @Binding var textColor: Color
    @Binding var backgroundColor: Color
    @Binding var borderColor: Color
    @Binding var cornerRadius: CGFloat
    @Binding var borderWidth: CGFloat
    @Binding var opacity: Double
    @Binding var fontFamily: String
    @Binding var showCustomizationPanel: Bool
    let onFormattingChange: () -> Void
    @Binding var zoomScale: CGFloat
    @Binding var showGrid: Bool
    var onBoldButton: (() -> Void)? = nil
    var onItalicButton: (() -> Void)? = nil
    var onUnderlineButton: (() -> Void)? = nil
    var onStrikethroughButton: (() -> Void)? = nil
    var isBoldActive: Bool = false
    var isItalicActive: Bool = false
    var isUnderlinedActive: Bool = false
    var isStrikethroughActive: Bool = false
    var onIncreaseFontSize: (() -> Void)? = nil
    var onDecreaseFontSize: (() -> Void)? = nil
    var fontSizeDisplay: Int = 12
    let fontFamilies = ["System", "Helvetica", "Times", "Courier", "Georgia", "Verdana"]
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Bold button
                #if os(macOS)
                Button(action: { onBoldButton?() }) {
                    Image(systemName: "bold")
                        .font(.system(size: 14))
                        .foregroundColor(isBoldActive ? .white : .primary)
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(isBoldActive ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(6)
                // Italic button
                Button(action: { onItalicButton?() }) {
                    Image(systemName: "italic")
                        .font(.system(size: 14))
                        .foregroundColor(isItalicActive ? .white : .primary)
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(isItalicActive ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(6)
                // Underline button
                Button(action: { onUnderlineButton?() }) {
                    Image(systemName: "underline")
                        .font(.system(size: 14))
                        .foregroundColor(isUnderlinedActive ? .white : .primary)
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(isUnderlinedActive ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(6)
                // Strikethrough button
                Button(action: { onStrikethroughButton?() }) {
                    Image(systemName: "strikethrough")
                        .font(.system(size: 14))
                        .foregroundColor(isStrikethroughActive ? .white : .primary)
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(isStrikethroughActive ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(6)
                #endif
                Button(action: { onDecreaseFontSize?() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
                Text("\(fontSizeDisplay)")
                    .font(.system(size: 12, weight: .medium))
                    .frame(minWidth: 20)
                Button(action: { onIncreaseFontSize?() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
                HStack(spacing: 4) {
                    Button(action: { zoomScale = max(0.1, zoomScale - 0.1) }) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    Text("\(Int(zoomScale * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .frame(minWidth: 36)
                    Button(action: { zoomScale = min(2.0, zoomScale + 0.1) }) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                }
                Divider().frame(height: 20)
                Toggle(isOn: $showGrid) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 14))
                }
                .toggleStyle(.switch)
                .frame(width: 60)
                .padding(.leading, 8)
                HStack(spacing: 8) {
                    Image(systemName: "textformat")
                        .font(.system(size: 14))
                    ColorPicker("", selection: $textColor)
                        .frame(width: 30, height: 30)
                        .onChange(of: textColor) { _ in onFormattingChange() }
                }
                Divider().frame(height: 20)
                Button(action: { showCustomizationPanel.toggle() }) {
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
                Divider().frame(height: 20)
                HStack(spacing: 4) {
                    Image(systemName: "hand.point.up.left")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("Double-click to create node")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            if showCustomizationPanel {
                MindMapCustomizationPanel(
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

struct MindMapCustomizationPanel: View {
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
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Background")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    ColorPicker("", selection: $backgroundColor)
                        .frame(width: 40, height: 30)
                        .onChange(of: backgroundColor) { _ in onFormattingChange() }
                }
                VStack(spacing: 4) {
                    Text("Border")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    ColorPicker("", selection: $borderColor)
                        .frame(width: 40, height: 30)
                        .onChange(of: borderColor) { _ in onFormattingChange() }
                }
                Divider().frame(height: 30)
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
                    .onChange(of: fontFamily) { _ in onFormattingChange() }
                }
            }
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Roundness: \(Int(cornerRadius))")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Slider(value: $cornerRadius, in: 0...20, step: 1)
                        .frame(width: 80)
                        .onChange(of: cornerRadius) { _ in onFormattingChange() }
                }
                VStack(spacing: 4) {
                    Text("Border: \(Int(borderWidth))")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Slider(value: $borderWidth, in: 0...5, step: 1)
                        .frame(width: 80)
                        .onChange(of: borderWidth) { _ in onFormattingChange() }
                }
                VStack(spacing: 4) {
                    Text("Opacity: \(Int(opacity * 100))%")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.1)
                        .frame(width: 80)
                        .onChange(of: opacity) { _ in onFormattingChange() }
                }
            }
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