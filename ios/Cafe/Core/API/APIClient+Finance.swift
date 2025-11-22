//
//  APIClient+Finance.swift
//  Cafe
//
//  Finance API endpoints
//

import Foundation

extension APIClient {
    // MARK: - Bank Accounts

    func getBankAccounts() async throws -> [BankAccount] {
        let request = try authorizedRequest(path: "/finance/accounts", method: "GET")
        return try await performRequest(request)
    }

    func getBankAccount(id: Int) async throws -> BankAccount {
        let request = try authorizedRequest(path: "/finance/accounts/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func createBankAccount(_ account: BankAccountCreate) async throws -> BankAccount {
        var request = try authorizedRequest(path: "/finance/accounts", method: "POST")
        request.httpBody = try JSONEncoder().encode(account)
        return try await performRequest(request)
    }

    func updateBankAccount(id: Int, update: BankAccountUpdate) async throws -> BankAccount {
        var request = try authorizedRequest(path: "/finance/accounts/\(id)", method: "PUT")
        request.httpBody = try JSONEncoder().encode(update)
        return try await performRequest(request)
    }

    func deleteBankAccount(id: Int) async throws {
        let request = try authorizedRequest(path: "/finance/accounts/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    func syncBankAccount(id: Int) async throws -> BankAccount {
        let request = try authorizedRequest(path: "/finance/accounts/\(id)/sync", method: "POST")
        return try await performRequest(request)
    }

    // MARK: - Transactions

    func getTransactions(accountId: Int? = nil, limit: Int = 100) async throws -> [Transaction] {
        var path = "/finance/transactions?limit=\(limit)"
        if let accountId = accountId {
            path += "&account_id=\(accountId)"
        }
        let request = try authorizedRequest(path: path, method: "GET")
        return try await performRequest(request)
    }

    func getTransaction(id: Int) async throws -> Transaction {
        let request = try authorizedRequest(path: "/finance/transactions/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func createTransaction(_ transaction: TransactionCreate) async throws -> Transaction {
        var request = try authorizedRequest(path: "/finance/transactions", method: "POST")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(transaction)
        return try await performRequest(request)
    }

    func deleteTransaction(id: Int) async throws {
        let request = try authorizedRequest(path: "/finance/transactions/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Budgets

    func getBudgets() async throws -> [Budget] {
        let request = try authorizedRequest(path: "/finance/budgets", method: "GET")
        return try await performRequest(request)
    }

    func getBudget(id: Int) async throws -> Budget {
        let request = try authorizedRequest(path: "/finance/budgets/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func createBudget(_ budget: BudgetCreate) async throws -> Budget {
        var request = try authorizedRequest(path: "/finance/budgets", method: "POST")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(budget)
        return try await performRequest(request)
    }

    func deleteBudget(id: Int) async throws {
        let request = try authorizedRequest(path: "/finance/budgets/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Budget Progress

    /// Get budget progress for all active budgets
    /// - Returns: Array of budget progress for each active budget
    func getBudgetProgress() async throws -> [BudgetProgressResponse] {
        let request = try authorizedRequest(path: "/finance/budgets/progress", method: "GET")
        return try await performRequest(request)
    }

    /// Get progress for a specific budget
    /// - Parameter budgetId: The ID of the budget to get progress for
    /// - Returns: Budget progress for the specified budget
    func getBudgetProgress(budgetId: Int) async throws -> BudgetProgressResponse {
        let request = try authorizedRequest(path: "/finance/budgets/\(budgetId)/progress", method: "GET")
        return try await performRequest(request)
    }

    /// Get aggregated budget progress summary
    /// - Returns: Summary with total budgeted, spent, remaining across all budgets
    func getBudgetProgressSummary() async throws -> BudgetProgressSummary {
        let request = try authorizedRequest(path: "/finance/budgets/progress/summary", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - Analytics

    func getFinancialSummary(startDate: Date? = nil, endDate: Date? = nil) async throws -> FinancialSummary {
        var path = "/finance/summary"
        var queryItems: [String] = []

        if let start = startDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("start_date=\(formatter.string(from: start))")
        }

        if let end = endDate {
            let formatter = ISO8601DateFormatter()
            queryItems.append("end_date=\(formatter.string(from: end))")
        }

        if !queryItems.isEmpty {
            path += "?" + queryItems.joined(separator: "&")
        }

        let request = try authorizedRequest(path: path, method: "GET")
        return try await performRequest(request)
    }

    func getCategorySpending(startDate: Date, endDate: Date) async throws -> [String: Decimal] {
        let formatter = ISO8601DateFormatter()
        let path = "/finance/analytics/category-spending?start_date=\(formatter.string(from: startDate))&end_date=\(formatter.string(from: endDate))"
        let request = try authorizedRequest(path: path, method: "GET")
        return try await performRequest(request)
    }

    // MARK: - Plaid Integration

    func createPlaidLinkToken() async throws -> PlaidLinkToken {
        let request = try authorizedRequest(path: "/finance/plaid/link-token", method: "POST")
        return try await performRequest(request)
    }

    func exchangePlaidPublicToken(publicToken: String) async throws -> [BankAccount] {
        var request = try authorizedRequest(path: "/finance/plaid/exchange-token", method: "POST")
        let body = ["public_token": publicToken]
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }
}

// MARK: - Plaid Models

struct PlaidLinkToken: Codable {
    let linkToken: String
    let expiration: Date

    enum CodingKeys: String, CodingKey {
        case linkToken = "link_token"
        case expiration
    }
}
