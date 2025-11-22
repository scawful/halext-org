//
//  AIPageAssistant.swift
//  Cafe
//
//  AI-powered page writing assistant for content generation,
//  summarization, enhancement, and context-aware prompting
//

import Foundation
import Combine

/// Actions available for AI page assistance
enum AIPageAction: String, CaseIterable, Identifiable {
    case summarize = "summarize"
    case enhance = "enhance"
    case expand = "expand"
    case simplify = "simplify"
    case proofread = "proofread"
    case generateOutline = "outline"
    case askQuestion = "question"
    case continueWriting = "continue"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .summarize:
            return "Summarize"
        case .enhance:
            return "Enhance"
        case .expand:
            return "Expand"
        case .simplify:
            return "Simplify"
        case .proofread:
            return "Proofread"
        case .generateOutline:
            return "Generate Outline"
        case .askQuestion:
            return "Ask Question"
        case .continueWriting:
            return "Continue Writing"
        }
    }

    var description: String {
        switch self {
        case .summarize:
            return "Create a concise summary of the content"
        case .enhance:
            return "Improve clarity, style, and engagement"
        case .expand:
            return "Add more detail and depth to the content"
        case .simplify:
            return "Make the content easier to understand"
        case .proofread:
            return "Check for grammar, spelling, and style issues"
        case .generateOutline:
            return "Create a structured outline from the content"
        case .askQuestion:
            return "Ask a question about the content"
        case .continueWriting:
            return "Continue writing from where you left off"
        }
    }

    var icon: String {
        switch self {
        case .summarize:
            return "text.justify.leading"
        case .enhance:
            return "sparkles"
        case .expand:
            return "arrow.up.left.and.arrow.down.right"
        case .simplify:
            return "minus.magnifyingglass"
        case .proofread:
            return "checkmark.circle"
        case .generateOutline:
            return "list.bullet.indent"
        case .askQuestion:
            return "questionmark.circle"
        case .continueWriting:
            return "pencil.line"
        }
    }

    /// Build system prompt for the action
    func systemPrompt(pageTitle: String) -> String {
        switch self {
        case .summarize:
            return """
            You are a content summarizer. Create a clear, concise summary of the document titled "\(pageTitle)".
            Focus on the main points and key takeaways.
            Keep the summary brief but comprehensive.
            """
        case .enhance:
            return """
            You are a professional editor. Enhance the following content from "\(pageTitle)" to improve:
            - Clarity and readability
            - Engagement and flow
            - Professional tone
            - Sentence structure variety
            Return the enhanced version of the content.
            """
        case .expand:
            return """
            You are a content writer. Expand the following content from "\(pageTitle)" by:
            - Adding relevant details and examples
            - Elaborating on key points
            - Including supporting information
            - Maintaining the original tone and style
            Return the expanded version.
            """
        case .simplify:
            return """
            You are a plain language expert. Simplify the following content from "\(pageTitle)":
            - Use simpler words and shorter sentences
            - Break down complex ideas
            - Remove jargon and technical terms where possible
            - Make it accessible to a general audience
            Return the simplified version.
            """
        case .proofread:
            return """
            You are a professional proofreader. Review the content from "\(pageTitle)" for:
            - Grammar and spelling errors
            - Punctuation issues
            - Style inconsistencies
            - Awkward phrasing

            Return the corrected version with a brief summary of changes made at the end.
            """
        case .generateOutline:
            return """
            You are a document organizer. Create a structured outline from the content of "\(pageTitle)".
            Use clear headings and subheadings.
            Format as a hierarchical bullet list.
            Identify main themes and supporting points.
            """
        case .askQuestion:
            return """
            You are a helpful assistant with access to the document titled "\(pageTitle)".
            Answer questions based on the content provided.
            If the answer is not in the content, say so clearly.
            Be concise but thorough in your responses.
            """
        case .continueWriting:
            return """
            You are a creative writing assistant. Continue writing from where the content of "\(pageTitle)" left off.
            - Match the existing tone and style
            - Maintain consistency with the established content
            - Add natural, flowing continuation
            - Keep paragraphs well-structured
            Return only the new content to be appended.
            """
        }
    }
}

/// Progress state for page AI operations
enum PageAIProgress {
    case idle
    case processing(String)
    case streaming
    case complete
    case error(String)

    var isActive: Bool {
        switch self {
        case .processing, .streaming:
            return true
        default:
            return false
        }
    }
}

/// Result of an AI page operation
struct AIPageResult {
    let originalContent: String
    let generatedContent: String
    let action: AIPageAction
    let model: String
    let timestamp: Date

    /// Check if the result can replace the original content
    var canReplaceContent: Bool {
        switch action {
        case .summarize, .generateOutline, .askQuestion:
            return false
        case .enhance, .expand, .simplify, .proofread, .continueWriting:
            return true
        }
    }
}

/// Manager class for AI-powered page assistance
@MainActor
class AIPageAssistant: ObservableObject {
    static let shared = AIPageAssistant()

    @Published var isProcessing = false
    @Published var progress: PageAIProgress = .idle
    @Published var lastError: String?
    @Published var streamedContent: String = ""
    @Published var lastResult: AIPageResult?

    private let apiClient = APIClient.shared
    private var streamTask: _Concurrency.Task<Void, Never>?

    private init() {}

    // MARK: - Main AI Operations

    /// Execute an AI action on page content
    /// - Parameters:
    ///   - action: The AI action to perform
    ///   - content: The page content to process
    ///   - pageTitle: The title of the page for context
    ///   - additionalPrompt: Optional additional instructions
    /// - Returns: The AI-generated result
    func executeAction(
        _ action: AIPageAction,
        content: String,
        pageTitle: String,
        additionalPrompt: String? = nil
    ) async throws -> AIPageResult {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIPageError.emptyContent
        }

        isProcessing = true
        progress = .processing(action.displayName)
        lastError = nil
        streamedContent = ""

        defer {
            isProcessing = false
            progress = .idle
        }

        do {
            let prompt = buildPrompt(
                action: action,
                content: content,
                pageTitle: pageTitle,
                additionalPrompt: additionalPrompt
            )

            let systemMessage = ChatMessage(
                role: "system",
                content: action.systemPrompt(pageTitle: pageTitle)
            )

            let response = try await apiClient.sendChatMessage(
                prompt: prompt,
                history: [systemMessage]
            )

            let result = AIPageResult(
                originalContent: content,
                generatedContent: response.response,
                action: action,
                model: response.model,
                timestamp: Date()
            )

            lastResult = result
            progress = .complete

            return result

        } catch let error as APIError {
            lastError = error.errorDescription
            progress = .error(error.localizedDescription)
            throw AIPageError.apiError(error)
        } catch {
            lastError = error.localizedDescription
            progress = .error(error.localizedDescription)
            throw AIPageError.unknownError(error.localizedDescription)
        }
    }

    /// Execute an AI action with streaming response
    /// - Parameters:
    ///   - action: The AI action to perform
    ///   - content: The page content to process
    ///   - pageTitle: The title of the page for context
    ///   - additionalPrompt: Optional additional instructions
    ///   - onToken: Callback for each streamed token
    func executeActionStreaming(
        _ action: AIPageAction,
        content: String,
        pageTitle: String,
        additionalPrompt: String? = nil,
        onToken: @escaping (String) -> Void
    ) async throws {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIPageError.emptyContent
        }

        isProcessing = true
        progress = .streaming
        lastError = nil
        streamedContent = ""

        defer {
            isProcessing = false
            progress = .idle
        }

        do {
            let prompt = buildPrompt(
                action: action,
                content: content,
                pageTitle: pageTitle,
                additionalPrompt: additionalPrompt
            )

            let systemMessage = ChatMessage(
                role: "system",
                content: action.systemPrompt(pageTitle: pageTitle)
            )

            let streamResult = try await apiClient.streamChatMessage(
                prompt: prompt,
                history: [systemMessage]
            )

            for try await token in streamResult.stream {
                streamedContent += token
                onToken(token)
            }

            let result = AIPageResult(
                originalContent: content,
                generatedContent: streamedContent,
                action: action,
                model: streamResult.modelIdentifier ?? "unknown",
                timestamp: Date()
            )

            lastResult = result
            progress = .complete

        } catch let error as APIError {
            lastError = error.errorDescription
            progress = .error(error.localizedDescription)
            throw AIPageError.apiError(error)
        } catch {
            lastError = error.localizedDescription
            progress = .error(error.localizedDescription)
            throw AIPageError.unknownError(error.localizedDescription)
        }
    }

    /// Ask a question about page content
    /// - Parameters:
    ///   - question: The question to ask
    ///   - content: The page content as context
    ///   - pageTitle: The title of the page
    /// - Returns: The AI response
    func askQuestion(
        _ question: String,
        content: String,
        pageTitle: String
    ) async throws -> String {
        let result = try await executeAction(
            .askQuestion,
            content: content,
            pageTitle: pageTitle,
            additionalPrompt: question
        )
        return result.generatedContent
    }

    /// Generate content for a new page based on a topic
    /// - Parameters:
    ///   - topic: The topic to write about
    ///   - style: Optional writing style preference
    /// - Returns: Generated content
    func generateContent(
        topic: String,
        style: String? = nil
    ) async throws -> String {
        isProcessing = true
        progress = .processing("Generating content")
        lastError = nil

        defer {
            isProcessing = false
            progress = .idle
        }

        let styleInstruction = style.map { " Write in a \($0) style." } ?? ""

        let systemPrompt = """
        You are a helpful writing assistant. Generate well-structured, engaging content on the requested topic.\(styleInstruction)
        Use clear paragraphs and organize the content logically.
        """

        let systemMessage = ChatMessage(role: "system", content: systemPrompt)

        let response = try await apiClient.sendChatMessage(
            prompt: "Write about: \(topic)",
            history: [systemMessage]
        )

        progress = .complete
        return response.response
    }

    /// Suggest titles for page content
    /// - Parameter content: The page content
    /// - Returns: Array of suggested titles
    func suggestTitles(for content: String) async throws -> [String] {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIPageError.emptyContent
        }

        isProcessing = true
        progress = .processing("Suggesting titles")

        defer {
            isProcessing = false
            progress = .idle
        }

        let systemPrompt = """
        You are a title writing expert. Generate 5 compelling, descriptive titles for the provided content.
        Return only the titles, one per line, numbered 1-5.
        """

        let systemMessage = ChatMessage(role: "system", content: systemPrompt)

        let response = try await apiClient.sendChatMessage(
            prompt: "Generate titles for this content:\n\n\(content.prefix(2000))",
            history: [systemMessage]
        )

        // Parse titles from response
        let titles = response.response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { line -> String in
                // Remove numbering like "1.", "1)", "1:"
                var cleaned = line
                if let range = cleaned.range(of: #"^\d+[\.\)\:]\s*"#, options: .regularExpression) {
                    cleaned.removeSubrange(range)
                }
                return cleaned
            }
            .filter { !$0.isEmpty }

        progress = .complete
        return titles
    }

    // MARK: - Context Building

    /// Build the full prompt for an action
    private func buildPrompt(
        action: AIPageAction,
        content: String,
        pageTitle: String,
        additionalPrompt: String?
    ) -> String {
        var prompt = ""

        switch action {
        case .askQuestion:
            prompt = """
            Document content:
            ---
            \(content)
            ---

            Question: \(additionalPrompt ?? "What is this document about?")
            """

        case .continueWriting:
            prompt = """
            Continue writing from this content:
            ---
            \(content)
            ---

            \(additionalPrompt.map { "Additional guidance: \($0)" } ?? "")
            """

        default:
            prompt = """
            Content to process:
            ---
            \(content)
            ---

            \(additionalPrompt.map { "Additional instructions: \($0)" } ?? "")
            """
        }

        return prompt
    }

    // MARK: - Utility

    /// Cancel any ongoing streaming operation
    func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isProcessing = false
        progress = .idle
    }

    /// Clear the last result
    func clearLastResult() {
        lastResult = nil
        streamedContent = ""
    }
}

// MARK: - Errors

/// Errors specific to AI page operations
enum AIPageError: LocalizedError {
    case emptyContent
    case emptyPrompt
    case apiError(APIError)
    case invalidResponse
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Please add some content to the page first"
        case .emptyPrompt:
            return "Please enter a question or prompt"
        case .apiError(let apiError):
            return apiError.errorDescription
        case .invalidResponse:
            return "Could not understand the AI response. Please try again."
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
}
