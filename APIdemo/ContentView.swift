import SwiftUI

// MARK: - Models

// Model for Rating (as returned by the API)
struct Rating: Codable {
    let rate: Double
    let count: Int
}

// Model for Product
struct Product: Identifiable, Codable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let image: String
    let rating: Rating
}

// Structure to track a product’s favorite state
struct Favourite {
    var isFavorite: Bool = false
}

// MARK: - View Model

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var errorMessage: String = ""
    
    func fetchProducts() {
        // Initialize URL and ensure it's valid
        guard let url = URL(string: "https://fakestoreapi.com/products") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return
        }

        // Created a custom URLSession with the delegate from Certoverride
        let session = URLSession(configuration: .default, delegate: CustomURLSessionDelegate(), delegateQueue: nil)
        
        // Perform the data task using the custom session
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }

            do {
                let products = try JSONDecoder().decode([Product].self, from: data)
                DispatchQueue.main.async {
                    self.products = products
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }.resume()
    }
}

// MARK: - Views

// Main ContentView
struct ContentView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var cart: [Product] = []
    @State private var favorites: [Int: Favourite] = [:]
    
    // Grid layout definition for two columns
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Display an error message if one exists.
                if !viewModel.errorMessage.isEmpty {
                    Text("Error: \(viewModel.errorMessage)")
                        .foregroundColor(.red)
                }
                
                ScrollView {
                    if viewModel.products.isEmpty {
                        ProgressView("Loading Products...")
                            .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.products) { product in
                                // Create a binding for the product’s favorite state.
                                let favouriteBinding = Binding(
                                    get: {
                                        favorites[product.id, default: Favourite()]
                                    },
                                    set: { newValue in
                                        favorites[product.id] = newValue
                                    }
                                )
                                
                                // When tapping the card, navigate to the ProductPreview and pass the cart and favorites.
                                NavigationLink(
                                    destination: ProductPreview(
                                        product: product,
                                        cart: $cart,
                                        favorites: $favorites
                                    )
                                ) {
                                    ProductCard(
                                        product: product,
                                        favourite: favouriteBinding,
                                        cart: $cart
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Product Store")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ZStack {
                            NavigationLink(destination: CartView(cart: cart)) {
                                Image(systemName: "cart")
                                    .imageScale(.large)
                            }
                            
                            // Dynamic badge for the cart count.
                            if cart.count > 0 {
                                Text("\(cart.count)")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                }
                .onAppear {
                    viewModel.fetchProducts()
                }
            }
        }
    }
}

// View to display each product in a grid cell (Product Card)
struct ProductCard: View {
    let product: Product
    @Binding var favourite: Favourite
    @Binding var cart: [Product]
    
    @StateObject private var imageLoader = ImageLoader()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                // Custom Image Loader
                Group {
                    if let uiImage = imageLoader.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        ProgressView() // Show a progress view while loading
                            .onAppear {
                                imageLoader.loadImage(from: product.image)
                            }
                    }
                }
                .frame(height: 150)
                .cornerRadius(10)
                
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(product.rating.rate.rounded()) ? "star.fill" : "star")
                            .foregroundColor(index < Int(product.rating.rate.rounded()) ? .yellow : .gray)
                    }
                    Text("(\(product.rating.count))")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
            
            // Heart button toggles the favorite state and adds/removes the item from the cart.
            Button(action: {
                favourite.isFavorite.toggle()
                if favourite.isFavorite {
                    if !cart.contains(where: { $0.id == product.id }) {
                        cart.append(product)
                    }
                } else {
                    cart.removeAll { $0.id == product.id }
                }
            }) {
                Image(systemName: favourite.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(.red)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding(10)
        }
        .padding(.vertical, 5)
    }
}


// Detailed Product Preview view
struct ProductPreview: View {
    let product: Product
    @Binding var cart: [Product]
    @Binding var favorites: [Int: Favourite]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack {
                AsyncImage(url: URL(string: product.image)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        ProgressView()
                    }
                }
                .frame(height: 250)
                .cornerRadius(10)
                .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(product.rating.rate.rounded()) ? "star.fill" : "star")
                                .foregroundColor(index < Int(product.rating.rate.rounded()) ? .yellow : .gray)
                        }
                        Text("(\(product.rating.count))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                .padding()
                
                // Add to Cart button; when tapped, it adds the product to the cart and marks it as favorite.
                Button(action: {
                    if !cart.contains(where: { $0.id == product.id }) {
                        cart.append(product)
                    }
                    favorites[product.id] = Favourite(isFavorite: true)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Add to Cart")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Close")
                .font(.headline)
                .foregroundColor(.red)
        })
        .navigationTitle("Product Preview")
    }
}

// View to display the Cart and Checkout option
struct CartView: View {
    let cart: [Product] // Cart passed from ContentView
    @State private var showThankYouAlert = false // State to control alert visibility

    var body: some View {
        VStack {
            if cart.isEmpty {
                Text("Your Cart is Empty!")
                    .font(.title)
                    .foregroundColor(.gray)
            } else {
                // List of Products in the Cart
                List(cart) { product in
                    HStack {
                        Image(product.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .cornerRadius(5)

                        VStack(alignment: .leading) {
                            Text(product.title)
                                .font(.headline)
                            Text("Price: $\(product.price, specifier: "%.2f")")
                                .font(.subheadline)
                        }

                        Spacer()
                    }
                }
                .listStyle(PlainListStyle())

                // "Check Out" Button
                Button(action: {
                    showThankYouAlert = true // Show the Thank You alert
                }) {
                    Text("Check Out")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding()
                .alert(isPresented: $showThankYouAlert) {
                    Alert(
                        title: Text("Thank You"),
                        message: Text("Your order has been placed successfully!"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .navigationTitle("Your Cart")
    }
}
#Preview {
    ContentView()
}
