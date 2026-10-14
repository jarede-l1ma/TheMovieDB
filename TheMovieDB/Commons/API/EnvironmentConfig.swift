import Foundation
import os

/// Protocol for environment configuration provider.
protocol EnvironmentConfigProtocol {
    var apiBaseURL: URL { get }
    var apiBearerToken: String { get }
}

/// Secure environment configuration manager reading from Info.plist.
struct EnvironmentConfig: EnvironmentConfigProtocol {
    static let shared = EnvironmentConfig()
    
    let apiBaseURL: URL = {
        guard let url = URL(string: "https://api.themoviedb.org/3") else {
            fatalError("Invalid API Base URL configuration")
        }
        return url
    }()
    
    /// Fallback para desenvolvimento local: Substitua 'YOUR-BEARER-TOKEN-HERE' pelo seu Bearer Token do TMDB para testar o app.
    private let localDevBearerToken = "YOUR-BEARER-TOKEN-HERE"
    
    var apiBearerToken: String {
        if let token = Bundle.main.infoDictionary?["TMDB_API_TOKEN"] as? String,
           !token.isEmpty,
           token != "YOUR-BEARER-TOKEN-HERE",
           !token.hasPrefix("$(") {
            return token
        }
        
        if localDevBearerToken == "YOUR-BEARER-TOKEN-HERE" || localDevBearerToken.isEmpty {
            AppLogger.api.error("TMDB API Bearer Token não foi encontrado no Info.plist nem em localDevBearerToken. Substitua o valor em EnvironmentConfig.swift ou no Info.plist para autenticar com sucesso.")
        }
        return localDevBearerToken
    }
}
