//
//  ErrorCategorizer.swift
//  Cafe
//
//  Utility for categorizing errors and determining retry behavior
//

import Foundation

struct ErrorCategorizer {
    /// Determines if an error should show a retry option
    /// - Parameter error: The error to categorize
    /// - Returns: true if retry should be shown, false otherwise
    static func shouldShowRetry(for error: Error) -> Bool {
        if let apiError = error as? APIError {
            // Don't show retry for authentication errors
            return apiError != .unauthorized && apiError != .notAuthenticated
        } else if error is URLError {
            // Always show retry for network errors
            return true
        } else {
            // For unknown errors, allow retry (user can decide)
            return true
        }
    }
    
    /// Provides a user-friendly error message for an error
    /// - Parameter error: The error to convert
    /// - Returns: A user-friendly error message
    static func userFriendlyMessage(for error: Error, defaultMessage: String = "An error occurred. Please try again.") -> String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? defaultMessage
        } else if let urlError = error as? URLError {
            return "Network error: \(urlError.localizedDescription). Please check your connection and try again."
        } else {
            return error.localizedDescription.isEmpty ? defaultMessage : error.localizedDescription
        }
    }
    
    /// Categorizes an error and returns both user-friendly message and retry flag
    /// - Parameters:
    ///   - error: The error to categorize
    ///   - defaultMessage: Default message if error doesn't provide one
    /// - Returns: Tuple containing (message: String, shouldShowRetry: Bool)
    static func categorize(error: Error, defaultMessage: String = "An error occurred. Please try again.") -> (message: String, shouldShowRetry: Bool) {
        let message = userFriendlyMessage(for: error, defaultMessage: defaultMessage)
        let showRetry = shouldShowRetry(for: error)
        return (message, showRetry)
    }
}

