# TheMovieDB iOS App

A modern iOS app built with Swift that allows users to explore movies now playing in theaters, view detailed information, and see beautiful movie posters — all powered by [The Movie Database (TMDb) API](https://www.themoviedb.org/).


![App Preview](https://github.com/user-attachments/assets/8929abc7-8642-418f-9b34-fbb70f9fb3d4)

## 📱 Features

- **Now Playing:** Browse a list of movies currently in theaters.
- **Movie Details:** See information such as synopsis, release date, rating, and poster.
- **Responsive Layout:** Adapts to device orientation (portrait/landscape) and screen sizes.
- **Localization:** Supports English and Brazilian Portuguese (auto-detects device language).
- **Asynchronous Networking:** Modern async/await API usage.
- **Image Caching:** Fast poster loading with local cache for smooth scrolling.

## 🚀 Getting Started

Follow these steps to build and run the app locally:

### 1. Clone the repository

```sh
git clone https://github.com/your-username/themoviedb-ios-app.git
cd themoviedb-ios-app

```

### 2. Open in Xcode:
   • Open the file TheMovieDB.xcodeproj using Xcode 15 or newer.

### 3. Setup TMDb API Token:
   • This app requires a TMDb API Bearer Token.
   • In APIClient.swift, replace the value of bearerToken with your own (find it on your TMDb dashboard):
   
        private let bearerToken = "YOUR-BEARER-TOKEN-HERE"
   • Important: Do not share your token publicly.

### 🏛️ Architectural Overview & Decisions

• Architecture:
The app is structured using VIP-C:
View – Interactor – Presenter – Coordinator, with ViewModels for UI adaptation.

• Layer descriptions:
   • View:
  Responsible for displaying UI and user interactions.  

  Receives data from the ViewModel and outputs user actions to the Interactor.

- **Interactor:**  

  Handles business logic, data fetching, and processing.  

  Calls API clients, manages pagination, and passes results to the Presenter.

- **Presenter:**  

  Prepares and formats raw data for display.  

  Converts models into `ViewModel` objects suitable for the UI, ensuring presentation separation.

- **ViewModel:**  

  Lightweight data structures tailored for each view, containing only what's needed for display (titles, subtitles, images, etc.).

- **Coordinator:**  

  Manages navigation and flow between screens, decoupling routing logic from UI code.

- **Localization:**  

  The interface and API requests adapt automatically to the device’s language (English or Brazilian Portuguese), with fallback to English.


• UI:
   • UIKit with programmatic layout.
   • Uses UICollectionViewCompositionalLayout for responsive, adaptive grids.
   • Image loading and caching are managed asynchronously for smooth scrolling.

⸻

### 🧰 Libraries & Tools Used

• UIKit:
For building the user interface, as it’s flexible and provides fine-grained control over layout and navigation.
• Swift Concurrency (async/await):
Provides modern, readable, and safe asynchronous networking and image loading.
• UICollectionViewCompositionalLayout:
Enables adaptive and highly customizable collection view layouts without third-party dependencies.
• Localization (Foundation):
Native support for English and Brazilian Portuguese, including dynamic request localization for the API.
• NSCache:
For efficient in-memory image caching, reducing redundant network requests.
• No third-party dependencies:
The app is built using only Apple’s frameworks for security, performance, and longevity.
