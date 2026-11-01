import SwiftUI
import iOS_SDK

/// Photo search, start to finish: take or choose a photo, tap one of the items Syte finds in it,
/// browse similar products. Started with an image URL, it searches that image right away, which
/// fits a "find similar" button on a product image.
///
/// Taking photos needs `NSCameraUsageDescription` in the app's Info.plist. Without a camera,
/// for example in the simulator, only choosing a photo is offered.
public struct SyteVisualSearchView<Card: View>: View {

    let startImage: URL?
    let startSku: String?
    let pageName: String
    let onSelect: (SyteUIProduct) -> Void
    let card: (SyteUIProduct) -> Card

    @Environment(\.syteService) private var service
    @Environment(\.syteTheme) private var theme
    @StateObject private var model = SyteVisualSearchModel()
    @State private var picker: SytePhotoSource?

    /// Starts by asking for a photo.
    public init(pageName: String = "mobile_sdk",
                onSelect: @escaping (SyteUIProduct) -> Void = { _ in },
                @ViewBuilder card: @escaping (SyteUIProduct) -> Card) {
        self.init(imageURL: nil, sku: nil, pageName: pageName, onSelect: onSelect, card: card)
    }

    /// Starts by searching the image at `imageURL`.
    /// - Parameter sku: The product the image belongs to, so Syte can tie clicks back to it.
    public init(imageURL: URL?,
                sku: String?,
                pageName: String = "mobile_sdk",
                onSelect: @escaping (SyteUIProduct) -> Void = { _ in },
                @ViewBuilder card: @escaping (SyteUIProduct) -> Card) {
        self.startImage = imageURL
        self.startSku = sku
        self.pageName = pageName
        self.onSelect = onSelect
        self.card = card
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing * 1.5) {
                if let source = model.source {
                    imageSection(source)
                    resultsSection
                } else {
                    prompt
                }
            }
            .padding(theme.edgeInset)
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(isPresented: isPicking(.library)) {
            SytePhotoPicker(source: .library, onPick: picked).ignoresSafeArea()
        }
        .fullScreenCover(isPresented: isPicking(.camera)) {
            SytePhotoPicker(source: .camera, onPick: picked).ignoresSafeArea()
        }
        .task {
            model.service = service
            model.pageName = pageName
            if let url = startImage, model.source == nil {
                await model.search(imageURL: url, sku: startSku)
            }
        }
    }

    // MARK: - Asking for a photo

    private var prompt: some View {
        VStack(spacing: theme.spacing) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(theme.accent)
                .padding(.bottom, 4)
                .accessibilityHidden(true)
            Text(theme.strings.visualSearchTitle)
                .font(theme.headerFont)
                .foregroundColor(theme.primaryText)
            Text(theme.strings.visualSearchHint)
                .font(theme.titleFont)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
            photoButtons
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .onAppear {
            service?.track(EventCameraButtonImpression(pageName: pageName))
        }
    }

    private var photoButtons: some View {
        HStack(spacing: theme.spacing) {
            if SytePhotoPicker.isCameraAvailable {
                photoButton(theme.strings.takePhoto, icon: "camera", source: .camera)
            }
            photoButton(theme.strings.choosePhoto, icon: "photo.on.rectangle", source: .library)
        }
    }

    private func photoButton(_ title: String, icon: String, source: SytePhotoSource) -> some View {
        Button {
            service?.track(EventCameraButtonClick(placement: Placement.default.rawValue, pageName: pageName))
            picker = source
        } label: {
            Label(title, systemImage: icon)
                .font(theme.titleFont.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(theme.accent.opacity(0.12)))
                .foregroundColor(theme.accent)
        }
        .buttonStyle(.plain)
    }

    private func isPicking(_ source: SytePhotoSource) -> Binding<Bool> {
        Binding(get: { picker == source }, set: { if !$0 { picker = nil } })
    }

    private func picked(_ photo: UIImage?) {
        picker = nil
        guard let photo = photo else { return }
        Task { await model.search(photo: photo) }
    }

    // MARK: - The image and its items

    private func imageSection(_ source: SyteVisualSearchModel.Source) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            SyteDetectionImage(source: source,
                               items: model.detection?.items ?? [],
                               selected: model.selected,
                               isDetecting: model.phase == .detecting) { item in
                Task { await model.select(item) }
            }
            if let items = model.detection?.items, items.count > 1 {
                itemChips(items)
            }
            HStack {
                status
                Spacer()
                Button {
                    model.reset()
                } label: {
                    Label(theme.strings.newPhoto, systemImage: "arrow.counterclockwise")
                        .font(theme.titleFont)
                        .foregroundColor(theme.accent)
                }
            }
        }
    }

    @ViewBuilder private var status: some View {
        switch model.phase {
        case .detecting:
            Text(theme.strings.findingItems)
                .font(theme.titleFont)
                .foregroundColor(theme.secondaryText)
        case .detected where model.detection?.items.isEmpty == true:
            Text(theme.strings.nothingFound)
                .font(theme.titleFont)
                .foregroundColor(theme.secondaryText)
        default:
            EmptyView()
        }
    }

    private func itemChips(_ items: [SyteDetectedItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    let isSelected = item.id == model.selected
                    Button {
                        Task { await model.select(item) }
                    } label: {
                        Text(SyteDetectionImage.displayName(item))
                            .font(theme.titleFont)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(isSelected ? theme.accent : theme.imageBackground))
                            .foregroundColor(isSelected ? .white : theme.primaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Results

    @ViewBuilder private var resultsSection: some View {
        if case .failed(let message) = model.phase {
            SyteErrorView(message: message) { Task { await model.retry() } }
        } else if let message = model.resultsError {
            SyteErrorView(message: message) { Task { await model.retry() } }
        } else if model.loadingResults {
            ProgressView().frame(maxWidth: .infinity).padding(32)
        } else {
            SyteProductGrid(products: model.results, onSelect: { index, product in
                model.resultTapped(product, at: index)
                onSelect(product)
            }, card: card)
        }
    }

}

extension SyteVisualSearchView where Card == SyteProductCard {

    public init(pageName: String = "mobile_sdk", onSelect: @escaping (SyteUIProduct) -> Void = { _ in }) {
        self.init(pageName: pageName, onSelect: onSelect) { SyteProductCard(product: $0) }
    }

    public init(imageURL: URL?, sku: String?, pageName: String = "mobile_sdk", onSelect: @escaping (SyteUIProduct) -> Void = { _ in }) {
        self.init(imageURL: imageURL, sku: sku, pageName: pageName, onSelect: onSelect) { SyteProductCard(product: $0) }
    }

}

/// The searched image with a tappable marker on each item found.
struct SyteDetectionImage: View {

    let source: SyteVisualSearchModel.Source
    let items: [SyteDetectedItem]
    let selected: Int?
    let isDetecting: Bool
    let onTap: (SyteDetectedItem) -> Void

    @Environment(\.syteTheme) private var theme

    var body: some View {
        Group {
            switch source {
            case .photo(let photo):
                marked(Image(uiImage: photo))
            case .url(let url):
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        marked(image)
                    } else {
                        theme.imageBackground
                            .aspectRatio(theme.imageAspectRatio, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 440)
    }

    private func marked(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(
                GeometryReader { geometry in
                    ForEach(items) { item in
                        Button {
                            onTap(item)
                        } label: {
                            SyteMarker(isSelected: item.id == selected)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("syte.marker")
                        .accessibilityLabel(Self.displayName(item))
                        .accessibilityAddTraits(item.id == selected ? .isSelected : [])
                        .position(x: item.center.x * geometry.size.width, y: item.center.y * geometry.size.height)
                    }
                }
            )
            .overlay(isDetecting ? Color.black.opacity(0.25).overlay(ProgressView().tint(.white)) : nil)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .animation(.easeOut(duration: 0.2), value: selected)
    }

    static func displayName(_ item: SyteDetectedItem) -> String {
        item.label.isEmpty ? "Item \(item.id + 1)" : item.label.prefix(1).uppercased() + item.label.dropFirst()
    }

}

struct SyteMarker: View {

    let isSelected: Bool

    @Environment(\.syteTheme) private var theme

    var body: some View {
        Circle()
            .fill(isSelected ? theme.accent : Color.white)
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
            .scaleEffect(isSelected ? 1.2 : 1)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

}
