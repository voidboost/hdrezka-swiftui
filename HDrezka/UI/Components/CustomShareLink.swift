import SwiftUI

struct CustomSharingsPicker: NSViewRepresentable {
    @Binding private var isPresented: Bool
    private let sharingItems: [Any]

    init(isPresented: Binding<Bool>, sharingItems: [Any]) {
        self._isPresented = isPresented
        self.sharingItems = sharingItems
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            let picker = NSSharingServicePicker(items: sharingItems)
            picker.delegate = context.coordinator

            DispatchQueue.main.async {
                picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        let owner: CustomSharingsPicker

        init(owner: CustomSharingsPicker) {
            self.owner = owner
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
            let urls = items.compactMap { $0 as? URL }

            guard !urls.isEmpty else { return proposedServices }

            guard let image = NSImage(systemSymbolName: "link", accessibilityDescription: nil) else {
                return proposedServices
            }

            var share = proposedServices

            for url in urls {
                if url.scheme == "hdrezka" {
                    let customService = NSSharingService(title: String(localized: "key.copy.link.internal"), image: image, alternateImage: image, handler: {
                        let p = NSPasteboard.general
                        p.clearContents()
                        p.setString(url.absoluteString, forType: .string)
                    })

                    if share.isEmpty {
                        share.insert(customService, at: 0)
                    } else {
                        share.insert(customService, at: 1)
                    }
                } else {
                    let customService = NSSharingService(title: String(localized: "key.copy.link"), image: image, alternateImage: image, handler: {
                        let p = NSPasteboard.general
                        p.clearContents()
                        p.setString(url.absoluteString, forType: .string)
                    })

                    share.insert(customService, at: 0)
                }
            }

            return share
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            sharingServicePicker.delegate = nil
            owner.isPresented = false
        }
    }
}

struct CustomShareLink<Label>: View where Label: View {
    private let items: [URL]
    private let label: () -> Label

    init(items: [URL], label: @escaping () -> Label) {
        self.items = items
        self.label = label
    }

    @State private var showPicker = false

    var body: some View {
        Button {
            self.showPicker = true
        } label: {
            label()
        }
        .background(CustomSharingsPicker(isPresented: $showPicker, sharingItems: items))
    }
}
