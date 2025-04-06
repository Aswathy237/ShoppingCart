# Shopping App

Welcome to the **APIdemo**, a SwiftUI-based project that showcases dynamic product listing, a shopping cart functionality, and favorite tracking. 

---

## Features

- **Home Screen**: Displays a grid of products with dynamic heart icons to mark favorites and cart functionality.
- **Product Preview**: View detailed information about a product, including image, description, rating, and price.
- **Cart Management**: Track products added to the cart and remove them directly from the home screen using the heart icon.
- **Favorites Sync**: Products added to the cart automatically fill the heart icon, making favorites and cart states synchronized.

---

## How to Run the App

Follow these steps to run the Shopping App locally:

1. **Clone the Repository**:
   - Open the terminal and use the following command:
     ```bash
        https://github.com/Aswathy237/ShoppingCart.git
     ```

2. **Navigate to the Project Directory**:
   - Run:
     ```bash
     cd APIdemo
     ```

3. **Open in Xcode**:
   - Open Xcode and select `APIdemo.xcodeproj` from the project folder.

4. **Build the Project**:
   - Press `Shift + Command + K` to clean the build folder, then run `Command + R` to build and launch the app.

5. **Test the App**:
   - Run the app on a simulator or a connected physical device to explore its features.

---

## Additional Notes and Considerations

### Implementation Details:
- **Favorites and Cart Sync**:
  - The app ensures that any product added to the cart via the preview screen is also marked as a favorite on the home screen.
  - Favorites are tracked using a dictionary (`[Int: Favourite]`), ensuring efficient updates to the heart icon's state.

- **Dynamic Navigation**:
  - The app uses `NavigationLink` to navigate between screens, ensuring seamless transitions.
  - The cart badge dynamically updates based on the number of products in the cart.


---


Thank you for exploring the Shopping App. Enjoy coding! 🚀
