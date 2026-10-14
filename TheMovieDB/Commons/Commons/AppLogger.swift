import Foundation
@_exported import os

/// Production-ready structured logging utility built on Apple's unified os.Logger framework.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.themoviedb.app"
    
    static let api = Logger(subsystem: subsystem, category: "API")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let imageLoader = Logger(subsystem: subsystem, category: "ImageLoader")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
}
