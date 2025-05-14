import AppKit
import Combine
import SwiftUI

struct CursorPositionTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    let prompt: String

    @State private var isFirstResponder: Bool = true
    @State private var subscriptions: Set<AnyCancellable> = []

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextViewWrapper {
        let textView = NSTextViewWrapper()
        textView.delegate = context.coordinator
        textView.placeholderString = prompt
        textView.isEditable = true
        textView.font = .systemFont(ofSize: 13)
        textView.backgroundColor = NSColor.clear
        textView.textContainerInset = CGSize(width: 0, height: 0)
        textView.allowsUndo = true

        DispatchQueue.main.async {
            NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification, object: textView)
                .receive(on: DispatchQueue.main)
                .sink { notification in
                    context.coordinator.textViewDidChangeSelection(notification)
                }
                .store(in: &subscriptions)
        }

        return textView
    }

    func updateNSView(_ nsView: NSTextViewWrapper, context: Context) {
        DispatchQueue.main.async {
            if nsView.string != text {
                nsView.string = text
            }

            if nsView.selectedRange() != selection {
                nsView.setSelectedRange(selection)
            }

            if isFirstResponder {
                nsView.window?.makeFirstResponder(nsView)
                isFirstResponder = false
            }

            nsView.invalidateIntrinsicContentSize()
            nsView.sizeToFit()
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CursorPositionTextView

        init(_ parent: CursorPositionTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                DispatchQueue.main.async {
                    if textView.string != self.parent.text {
                        self.parent.text = textView.string
                    }
                }

                updateCursorPosition(in: textView)
                textView.invalidateIntrinsicContentSize()
                textView.sizeToFit()
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                updateCursorPosition(in: textView)
            }
        }

        private func updateCursorPosition(in textView: NSTextView) {
            if let selectedRange = textView.selectedRanges.first?.rangeValue {
                DispatchQueue.main.async {
                    if selectedRange != self.parent.selection {
                        self.parent.selection = selectedRange
                    }
                }
            }
        }
    }
}

class NSTextViewWrapper: NSTextView {
    var placeholderString: String = "" {
        didSet {
            needsDisplay = true
        }
    }

    override var intrinsicContentSize: CGSize {
        let width = frame.width

        let height: CGFloat = if let layoutManager, let textContainer {
            layoutManager.usedRect(for: textContainer).size.height
        } else {
            0
        }

        return CGSize(width: width, height: height)
    }

    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)

        if string.isEmpty {
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.placeholderTextColor,
                .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
            let placeholderRect = CGRect(x: 5, y: 0, width: dirtyRect.width - 10, height: dirtyRect.height)
            (placeholderString as NSString).draw(in: placeholderRect, withAttributes: placeholderAttributes)
        }
    }
}
