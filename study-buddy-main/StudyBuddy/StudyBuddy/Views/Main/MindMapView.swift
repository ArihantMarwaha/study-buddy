import SwiftUI
import AppKit

// MARK: - Mind Map Note Model (copied from NotesApp, renamed to avoid conflicts)
struct MindMapNote: Identifiable {
    let id = UUID()
    var position: CGPoint
    var content: NSAttributedString
    var fontSize: CGFloat
    var textColor: Color
    var backgroundColor: Color
    var borderColor: Color
    var isBold: Bool
    var isItalic: Bool
    var isUnderlined: Bool
    var isStrikethrough: Bool
    var size: CGSize
    var cornerRadius: CGFloat
    var borderWidth: CGFloat
    var opacity: Double
    var fontFamily: String
    
    init(position: CGPoint, textColor: Color = .white) {
        self.position = position
        let color = NSColor(textColor)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        self.content = NSAttributedString(string: "New node...", attributes: attributes)
        self.fontSize = 12
        self.textColor = textColor
        self.backgroundColor = Color.blue.opacity(0.8)
        self.borderColor = Color.blue
        self.isBold = false
        self.isItalic = false
        self.isUnderlined = false
        self.isStrikethrough = false
        self.size = CGSize(width: 200, height: 150)
        self.cornerRadius = 8
        self.borderWidth = 2
        self.opacity = 1.0
        self.fontFamily = "System"
    }
}

// MARK: - MindMapView
struct MindMapView: View {
    @State private var notes: [MindMapNote] = []
    @State private var selectedNoteId: UUID?
    @State private var canvasOffset: CGPoint = .zero
    @State private var isDraggingCanvas = false
    @State private var lastDragPosition: CGPoint = .zero
    @State private var currentFontSize: CGFloat = 12
    @State private var currentTextColor: Color = .white
    @State private var currentBackgroundColor: Color = Color.yellow.opacity(0.8)
    @State private var currentBorderColor: Color = Color.yellow
    @State private var currentCornerRadius: CGFloat = 8
    @State private var currentBorderWidth: CGFloat = 2
    @State private var currentOpacity: Double = 1.0
    @State private var currentFontFamily = "System"
    @State private var showCustomizationPanel = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var showGrid: Bool = true
    @State private var noteColorIndex: Int = 0
    private let noteColors: [(background: Color, border: Color)] = [
        (Color.blue.opacity(0.8), Color.blue),
        (Color.green.opacity(0.8), Color.green),
        (Color.pink.opacity(0.8), Color.pink),
        (Color.orange.opacity(0.8), Color.orange),
        (Color.purple.opacity(0.8), Color.purple),
        (Color.gray.opacity(0.8), Color.gray)
    ]
    @State private var noteSelectedRanges: [UUID: NSRange] = [:]
    
    // Computed properties for formatting states
    var isBoldActive: Bool {
#if os(macOS)
        guard let selectedId = selectedNoteId,
              let note = notes.first(where: { $0.id == selectedId }) else { return false }
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: note.content.length)
        return note.content.isBold(in: range)
#else
        return false
#endif
    }
    var isItalicActive: Bool {
#if os(macOS)
        guard let selectedId = selectedNoteId,
              let note = notes.first(where: { $0.id == selectedId }) else { return false }
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: note.content.length)
        return note.content.isItalic(in: range)
#else
        return false
#endif
    }
    var isUnderlinedActive: Bool {
#if os(macOS)
        guard let selectedId = selectedNoteId,
              let note = notes.first(where: { $0.id == selectedId }) else { return false }
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: note.content.length)
        return note.content.isUnderlined(in: range)
#else
        return false
#endif
    }
    var isStrikethroughActive: Bool {
#if os(macOS)
        guard let selectedId = selectedNoteId,
              let note = notes.first(where: { $0.id == selectedId }) else { return false }
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: note.content.length)
        return note.content.isStrikethrough(in: range)
#else
        return false
#endif
    }
    
    var selectedTextFontSize: Int {
#if os(macOS)
        guard let selectedId = selectedNoteId,
              let note = notes.first(where: { $0.id == selectedId }) else { return 12 }
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: note.content.length)
        var size: Int = 12
        note.content.enumerateAttribute(.font, in: range, options: []) { value, _, stop in
            if let font = value as? NSFont {
                size = Int(font.pointSize)
                stop.pointee = true
            }
        }
        return size
#else
        return 12
#endif
    }
    
    var body: some View {
        ZStack {
            // Canvas Background
            MindMapCanvasView(
                canvasOffset: $canvasOffset,
                isDraggingCanvas: $isDraggingCanvas,
                lastDragPosition: $lastDragPosition,
                onDoubleClick: addNote,
                zoomScale: zoomScale,
                showGrid: showGrid
            )
            // Notes
            ForEach(notes) { note in
                MindMapNoteView(
                    note: binding(for: note),
                    canvasOffset: canvasOffset,
                    isSelected: selectedNoteId == note.id,
                    onSelect: { selectNote(note.id) },
                    onDelete: { deleteNote(note.id) },
                    zoomScale: zoomScale,
                    selectedRange: Binding(
                        get: { noteSelectedRanges[note.id] ?? NSRange(location: 0, length: 0) },
                        set: { noteSelectedRanges[note.id] = $0 }
                    )
                )
            }
            // Toolbar
            VStack {
                MindMapFormattingToolbar(
                    fontSize: $currentFontSize,
                    textColor: $currentTextColor,
                    backgroundColor: $currentBackgroundColor,
                    borderColor: $currentBorderColor,
                    cornerRadius: $currentCornerRadius,
                    borderWidth: $currentBorderWidth,
                    opacity: $currentOpacity,
                    fontFamily: $currentFontFamily,
                    showCustomizationPanel: $showCustomizationPanel,
                    onFormattingChange: applyFormatting,
                    zoomScale: $zoomScale,
                    showGrid: $showGrid,
                    onBoldButton: { boldSelectedText() },
                    onItalicButton: { italicSelectedText() },
                    onUnderlineButton: { underlineSelectedText() },
                    onStrikethroughButton: { strikethroughSelectedText() },
                    isBoldActive: isBoldActive,
                    isItalicActive: isItalicActive,
                    isUnderlinedActive: isUnderlinedActive,
                    isStrikethroughActive: isStrikethroughActive,
                    onIncreaseFontSize: { increaseFontSizeSelectedText() },
                    onDecreaseFontSize: { decreaseFontSizeSelectedText() },
                    fontSizeDisplay: selectedTextFontSize
                )
                Spacer()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .clipped()
    }
    
    private func binding(for note: MindMapNote) -> Binding<MindMapNote> {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            fatalError("Note not found")
        }
        return $notes[index]
    }
    
    private func addNote(at position: CGPoint) {
        let adjustedPosition = CGPoint(
            x: position.x - canvasOffset.x,
            y: position.y - canvasOffset.y
        )
        let colorPair = noteColors[noteColorIndex % noteColors.count]
        noteColorIndex += 1
        var newNote = MindMapNote(position: adjustedPosition, textColor: currentTextColor)
        newNote.backgroundColor = colorPair.background
        newNote.borderColor = colorPair.border
        newNote.fontSize = currentFontSize
        newNote.textColor = currentTextColor
        newNote.cornerRadius = currentCornerRadius
        newNote.borderWidth = currentBorderWidth
        newNote.opacity = currentOpacity
        newNote.fontFamily = currentFontFamily
        notes.append(newNote)
        selectedNoteId = newNote.id
    }
    
    private func selectNote(_ id: UUID) {
        selectedNoteId = id
        if let note = notes.first(where: { $0.id == id }) {
            currentFontSize = note.fontSize
            currentTextColor = note.textColor
            currentBackgroundColor = note.backgroundColor
            currentBorderColor = note.borderColor
            currentCornerRadius = note.cornerRadius
            currentBorderWidth = note.borderWidth
            currentOpacity = note.opacity
            currentFontFamily = note.fontFamily
        }
    }
    
    private func deleteNote(_ id: UUID) {
        notes.removeAll { $0.id == id }
        if selectedNoteId == id {
            selectedNoteId = nil
        }
    }
    
    private func applyFormatting() {
        guard let selectedId = selectedNoteId,
              let index = notes.firstIndex(where: { $0.id == selectedId }) else {
            return
        }
        notes[index].fontSize = currentFontSize
        notes[index].textColor = currentTextColor
        notes[index].backgroundColor = currentBackgroundColor
        notes[index].borderColor = currentBorderColor
        notes[index].cornerRadius = currentCornerRadius
        notes[index].borderWidth = currentBorderWidth
        notes[index].opacity = currentOpacity
        notes[index].fontFamily = currentFontFamily
    }
    
    // MARK: - Text Formatting Functions
#if os(macOS)
    func boldSelectedText() {
        guard let selectedId = selectedNoteId,
              let index = notes.firstIndex(where: { $0.id == selectedId }) else { return }
        let mutable = NSMutableAttributedString(attributedString: notes[index].content)
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: mutable.length)
        let isCurrentlyBold = notes[index].content.isBold(in: range)
        mutable.setBold(!isCurrentlyBold, in: range)
        notes[index].content = mutable
    }
    func italicSelectedText() {
        guard let selectedId = selectedNoteId,
              let index = notes.firstIndex(where: { $0.id == selectedId }) else { return }
        let mutable = NSMutableAttributedString(attributedString: notes[index].content)
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: mutable.length)
        let isCurrentlyItalic = notes[index].content.isItalic(in: range)
        mutable.setItalic(!isCurrentlyItalic, in: range)
        notes[index].content = mutable
    }
    func underlineSelectedText() {
        guard let selectedId = selectedNoteId,
              let index = notes.firstIndex(where: { $0.id == selectedId }) else { return }
        let mutable = NSMutableAttributedString(attributedString: notes[index].content)
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: mutable.length)
        let isCurrentlyUnderlined = notes[index].content.isUnderlined(in: range)
        mutable.setUnderlined(!isCurrentlyUnderlined, in: range)
        notes[index].content = mutable
    }
    func strikethroughSelectedText() {
        guard let selectedId = selectedNoteId,
              let index = notes.firstIndex(where: { $0.id == selectedId }) else { return }
        let mutable = NSMutableAttributedString(attributedString: notes[index].content)
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: mutable.length)
        let isCurrentlyStrikethrough = notes[index].content.isStrikethrough(in: range)
        mutable.setStrikethrough(!isCurrentlyStrikethrough, in: range)
        notes[index].content = mutable
    }
    func increaseFontSizeSelectedText() {
        guard let selectedId = selectedNoteId,
              let index = notes.firstIndex(where: { $0.id == selectedId }) else { return }
        let mutable = NSMutableAttributedString(attributedString: notes[index].content)
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: mutable.length)
        var currentSize: CGFloat = 12
        mutable.enumerateAttribute(.font, in: range, options: []) { value, _, stop in
            if let font = value as? NSFont {
                currentSize = font.pointSize
                stop.pointee = true
            }
        }
        let newSize = min(32, currentSize + 2)
        mutable.setFontSize(newSize, in: range)
        notes[index].content = mutable
    }
    func decreaseFontSizeSelectedText() {
        guard let selectedId = selectedNoteId,
              let index = notes.firstIndex(where: { $0.id == selectedId }) else { return }
        let mutable = NSMutableAttributedString(attributedString: notes[index].content)
        let range = noteSelectedRanges[selectedId] ?? NSRange(location: 0, length: mutable.length)
        var currentSize: CGFloat = 12
        mutable.enumerateAttribute(.font, in: range, options: []) { value, _, stop in
            if let font = value as? NSFont {
                currentSize = font.pointSize
                stop.pointee = true
            }
        }
        let newSize = max(10, currentSize - 2)
        mutable.setFontSize(newSize, in: range)
        notes[index].content = mutable
    }
#endif
}

// MARK: - MindMapNoteView (copy NoteView, adapt for MindMapNote)
struct MindMapNoteView: View {
    @Binding var note: MindMapNote
    let canvasOffset: CGPoint
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let zoomScale: CGFloat
    @Binding var selectedRange: NSRange
    @State private var isDragging = false
    @State private var isEditing = false
    @State private var dragOffset: CGSize = .zero
    @State private var isResizing = false
    @State private var resizeOffset: CGSize = .zero
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "move.3d")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                Text("Node")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(note.backgroundColor.opacity(0.5))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onSelect()
                        }
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        note.position = CGPoint(
                            x: note.position.x + dragOffset.width / zoomScale,
                            y: note.position.y + dragOffset.height / zoomScale
                        )
                        dragOffset = .zero
                        isDragging = false
                    }
            )
            Group {
                if isEditing {
#if os(macOS)
                    AttributedTextEditor(attributedText: $note.content, selectedRange: $selectedRange, onEditingChanged: { newText, newRange in
                        note.content = newText
                        selectedRange = newRange
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
                    TextEditor(text: .constant(note.content.string))
                        .disabled(true)
#endif
                } else {
#if os(macOS)
                    Text(note.content.string)
                        .font(fontFromFamily(note.fontFamily, size: note.fontSize * zoomScale, weight: note.isBold ? .bold : .regular))
                        .foregroundColor(note.textColor)
                        .italic(note.isItalic)
                        .underline(note.isUnderlined)
                        .strikethrough(note.isStrikethrough)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isEditing = true
                            onSelect()
                        }
#else
                    Text(note.content.string)
                        .font(fontFromFamily(note.fontFamily, size: note.fontSize * zoomScale, weight: note.isBold ? .bold : .regular))
                        .foregroundColor(note.textColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isEditing = true
                            onSelect()
                        }
#endif
                }
            }
        }
        .frame(
            width: (note.size.width + resizeOffset.width) * zoomScale,
            height: (note.size.height + resizeOffset.height) * zoomScale
        )
        .background(note.backgroundColor)
        .cornerRadius(note.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: note.cornerRadius)
                .stroke(isSelected ? Color.blue : note.borderColor, lineWidth: note.borderWidth)
        )
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                        .padding(4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isResizing {
                                        isResizing = true
                                        onSelect()
                                    }
                                    resizeOffset = value.translation
                                }
                                .onEnded { _ in
                                    note.size = CGSize(
                                        width: max(100, note.size.width + resizeOffset.width),
                                        height: max(80, note.size.height + resizeOffset.height)
                                    )
                                    resizeOffset = .zero
                                    isResizing = false
                                }
                        )
                        .opacity(isSelected ? 1 : 0.3)
                }
                .padding(4)
            }
        )
        .shadow(radius: 3)
        .opacity(note.opacity)
        .position(
            x: (note.position.x + canvasOffset.x + dragOffset.width / zoomScale + (note.size.width + resizeOffset.width) / 2) * zoomScale,
            y: (note.position.y + canvasOffset.y + dragOffset.height / zoomScale + (note.size.height + resizeOffset.height) / 2) * zoomScale
        )
        .onTapGesture {
            onSelect()
        }
    }
    private func fontFromFamily(_ family: String, size: CGFloat, weight: Font.Weight) -> Font {
        switch family {
        case "Helvetica":
            return .custom("Helvetica", size: size)
        case "Times":
            return .custom("Times New Roman", size: size)
        case "Courier":
            return .custom("Courier New", size: size)
        case "Georgia":
            return .custom("Georgia", size: size)
        case "Verdana":
            return .custom("Verdana", size: size)
        default:
            return .system(size: size, weight: weight)
        }
    }
}

// MARK: - AttributedTextEditor (macOS only, reused)
#if os(macOS)
import AppKit
struct AttributedTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    var onEditingChanged: ((NSAttributedString, NSRange) -> Void)?
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isRichText = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.heightTracksTextView = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.alignment = .left
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.layoutManager?.usesFontLeading = false
        return textView
    }
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.attributedString() != attributedText {
            nsView.textStorage?.setAttributedString(attributedText)
        }
        nsView.selectedRange = selectedRange
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AttributedTextEditor
        init(_ parent: AttributedTextEditor) {
            self.parent = parent
        }
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
            parent.selectedRange = textView.selectedRange
            parent.onEditingChanged?(textView.attributedString(), textView.selectedRange)
        }
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.selectedRange = textView.selectedRange
        }
    }
}
#endif 

#if os(macOS)
extension NSAttributedString {
    func isBold(in range: NSRange) -> Bool {
        var isBold = false
        self.enumerateAttribute(.font, in: range, options: []) { value, _, stop in
            if let font = value as? NSFont {
                if font.fontDescriptor.symbolicTraits.contains(.bold) {
                    isBold = true
                    stop.pointee = true
                }
            }
        }
        return isBold
    }
    func isItalic(in range: NSRange) -> Bool {
        var isItalic = false
        self.enumerateAttribute(.font, in: range, options: []) { value, _, stop in
            if let font = value as? NSFont {
                if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    isItalic = true
                    stop.pointee = true
                }
            }
        }
        return isItalic
    }
    func isUnderlined(in range: NSRange) -> Bool {
        var isUnderlined = false
        self.enumerateAttribute(.underlineStyle, in: range, options: []) { value, _, stop in
            if let style = value as? NSNumber, style.intValue != 0 {
                isUnderlined = true
                stop.pointee = true
            }
        }
        return isUnderlined
    }
    func isStrikethrough(in range: NSRange) -> Bool {
        var isStrikethrough = false
        self.enumerateAttribute(.strikethroughStyle, in: range, options: []) { value, _, stop in
            if let style = value as? NSNumber, style.intValue != 0 {
                isStrikethrough = true
                stop.pointee = true
            }
        }
        return isStrikethrough
    }
}
#endif 

#if os(macOS)
extension NSMutableAttributedString {
    func setFontSize(_ size: CGFloat, in range: NSRange? = nil) {
        let fullRange = range ?? NSRange(location: 0, length: self.length)
        self.enumerateAttribute(.font, in: fullRange, options: []) { value, subrange, _ in
            let oldFont = value as? NSFont ?? NSFont.systemFont(ofSize: size)
            let newFont = NSFont(descriptor: oldFont.fontDescriptor, size: size) ?? NSFont.systemFont(ofSize: size)
            self.addAttribute(.font, value: newFont, range: subrange)
        }
    }
    func setBold(_ isBold: Bool, in range: NSRange? = nil) {
        let fullRange = range ?? NSRange(location: 0, length: self.length)
        self.enumerateAttribute(.font, in: fullRange, options: []) { value, subrange, _ in
            let oldFont = value as? NSFont ?? NSFont.systemFont(ofSize: 12)
            let fontDescriptor = oldFont.fontDescriptor
            let traits = isBold ? (fontDescriptor.symbolicTraits.union(.bold)) : (fontDescriptor.symbolicTraits.subtracting(.bold))
            let newDescriptor = fontDescriptor.withSymbolicTraits(traits)
            let newFont = NSFont(descriptor: newDescriptor, size: oldFont.pointSize) ?? oldFont
            self.addAttribute(.font, value: newFont, range: subrange)
        }
    }
    func setItalic(_ isItalic: Bool, in range: NSRange? = nil) {
        let fullRange = range ?? NSRange(location: 0, length: self.length)
        self.enumerateAttribute(.font, in: fullRange, options: []) { value, subrange, _ in
            let oldFont = value as? NSFont ?? NSFont.systemFont(ofSize: 12)
            let fontDescriptor = oldFont.fontDescriptor
            let traits = isItalic ? (fontDescriptor.symbolicTraits.union(.italic)) : (fontDescriptor.symbolicTraits.subtracting(.italic))
            let newDescriptor = fontDescriptor.withSymbolicTraits(traits)
            let newFont = NSFont(descriptor: newDescriptor, size: oldFont.pointSize) ?? oldFont
            self.addAttribute(.font, value: newFont, range: subrange)
        }
    }
    func setUnderlined(_ isUnderlined: Bool, in range: NSRange? = nil) {
        let fullRange = range ?? NSRange(location: 0, length: self.length)
        let style = isUnderlined ? NSUnderlineStyle.single.rawValue : 0
        self.addAttribute(.underlineStyle, value: style, range: fullRange)
    }
    func setStrikethrough(_ isStrikethrough: Bool, in range: NSRange? = nil) {
        let fullRange = range ?? NSRange(location: 0, length: self.length)
        let style = isStrikethrough ? NSUnderlineStyle.single.rawValue : 0
        self.addAttribute(.strikethroughStyle, value: style, range: fullRange)
    }
}
#endif 
 