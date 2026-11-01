import SwiftUI
import SyteUI
import iOS_SDK

/// A product page with the three recommendation rows Syte offers for it.
struct ProductPage: View {

    let product: SyteUIProduct
    let open: (Route) -> Void

    @Environment(\.syteService) private var service
    @Environment(\.syteTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    SyteProductImage(url: product.imageURL)
                        .frame(maxWidth: 420)
                        .frame(maxWidth: .infinity)
                    if let brand = product.brand {
                        Text(brand).font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
                    }
                    Text(product.title ?? "").font(.title3)
                    SytePriceView(product: product)
                    if product.imageURL != nil {
                        Button {
                            open(.similarLooks(product))
                        } label: {
                            Label("Find similar looks", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, theme.edgeInset)

                if let sku = product.sku, let image = product.imageURL?.absoluteString {
                    SyteProductCarousel(.similar(sku: sku, imageURL: image), title: "Similar items", pageName: "pdp") { open(.product($0)) }
                    SyteProductCarousel(.shopTheLook(sku: sku, imageURL: image), title: "Complete the look", pageName: "pdp") { open(.product($0)) }
                    SyteProductCarousel(.boughtTogether(skus: [sku]), title: "Often bought together", pageName: "pdp") { open(.product($0)) }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(product.brand ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // The app's own job, not the kit's: tell Syte the product was viewed, which also
            // feeds "Picked for you".
            if let sku = product.sku {
                service?.track(EventPageView(sku: sku, pageName: "pdp"))
            }
        }
    }

}
