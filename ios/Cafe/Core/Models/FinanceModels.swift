//
//  FinanceModels.swift
//  Cafe
//
//  Financial management models
//

import Foundation

// MARK: - Bank Account

struct BankAccount: Codable, Identifiable {
    let id: Int
    let userId: Int
    var accountName: String
    var accountType: AccountType
    var institutionName: String
    var accountNumber: String // Last 4 digits only
    var balance: Decimal
    var currency: String
    var isActive: Bool
    var lastSynced: Date?
    var plaidAccountId: String? // For Plaid integration

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case accountName = "account_name"
        case accountType = "account_type"
        case institutionName = "institution_name"
        case accountNumber = "account_number"
        case balance, currency
        case isActive = "is_active"
        case lastSynced = "last_synced"
        case plaidAccountId = "plaid_account_id"
    }
}

enum AccountType: String, Codable, CaseIterable {
    case checking = "checking"
    case savings = "savings"
    case credit = "credit"
    case investment = "investment"
    case loan = "loan"
    case other = "other"

    var icon: String {
        switch self {
        case .checking: return "dollarsign.circle"
        case .savings: return "banknote"
        case .credit: return "creditcard"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .loan: return "building.columns"
        case .other: return "wallet.pass"
        }
    }

    var color: String {
        switch self {
        case .checking: return "blue"
        case .savings: return "green"
        case .credit: return "orange"
        case .investment: return "purple"
        case .loan: return "red"
        case .other: return "gray"
        }
    }
}

struct BankAccountCreate: Codable {
    var accountName: String
    var accountType: String
    var institutionName: String
    var accountNumber: String
    var balance: Decimal
    var currency: String
    var plaidAccountId: String?

    enum CodingKeys: String, CodingKey {
        case accountName = "account_name"
        case accountType = "account_type"
        case institutionName = "institution_name"
        case accountNumber = "account_number"
        case balance, currency
        case plaidAccountId = "plaid_account_id"
    }
}

struct BankAccountUpdate: Codable {
    var accountName: String?
    var balance: Decimal?
    var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case accountName = "account_name"
        case balance
        case isActive = "is_active"
    }
}

// MARK: - Transaction

struct Transaction: Codable, Identifiable {
    let id: Int
    let accountId: Int
    var amount: Decimal
    var description: String
    var category: TransactionCategory
    var transactionDate: Date
    var transactionType: TransactionType
    var merchant: String?
    var notes: String?
    var tags: [String]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case amount, description, category
        case transactionDate = "transaction_date"
        case transactionType = "transaction_type"
        case merchant, notes, tags
        case createdAt = "created_at"
    }
}

enum TransactionCategory: String, Codable, CaseIterable {
    case income = "income"
    case groceries = "groceries"
    case dining = "dining"
    case transportation = "transportation"
    case utilities = "utilities"
    case entertainment = "entertainment"
    case healthcare = "healthcare"
    case shopping = "shopping"
    case housing = "housing"
    case insurance = "insurance"
    case education = "education"
    case travel = "travel"
    case transfer = "transfer"
    case other = "other"

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle"
        case .groceries: return "cart"
        case .dining: return "fork.knife"
        case .transportation: return "car"
        case .utilities: return "bolt"
        case .entertainment: return "tv"
        case .healthcare: return "cross.case"
        case .shopping: return "bag"
        case .housing: return "house"
        case .insurance: return "shield"
        case .education: return "book"
        case .travel: return "airplane"
        case .transfer: return "arrow.left.arrow.right"
        case .other: return "ellipsis.circle"
        }
    }

    var color: String {
        switch self {
        case .income: return "green"
        case .groceries: return "orange"
        case .dining: return "red"
        case .transportation: return "blue"
        case .utilities: return "yellow"
        case .entertainment: return "purple"
        case .healthcare: return "pink"
        case .shopping: return "teal"
        case .housing: return "brown"
        case .insurance: return "indigo"
        case .education: return "cyan"
        case .travel: return "mint"
        case .transfer: return "gray"
        case .other: return "gray"
        }
    }
}

enum TransactionType: String, Codable {
    case debit = "debit"
    case credit = "credit"
}

struct TransactionCreate: Codable {
    var accountId: Int
    var amount: Decimal
    var description: String
    var category: String
    var transactionDate: Date
    var transactionType: String
    var merchant: String?
    var notes: String?
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case amount, description, category
        case transactionDate = "transaction_date"
        case transactionType = "transaction_type"
        case merchant, notes, tags
    }
}

// MARK: - Budget

struct Budget: Codable, Identifiable {
    let id: Int
    let userId: Int
    var name: String
    var category: TransactionCategory
    var amount: Decimal
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, category, amount, period
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

enum BudgetPeriod: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
}

struct BudgetCreate: Codable {
    var name: String
    var category: String
    var amount: Decimal
    var period: String
    var startDate: Date
    var endDate: Date?

    enum CodingKeys: String, CodingKey {
        case name, category, amount, period
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

// MARK: - Financial Summary

struct FinancialSummary: Codable {
    let totalBalance: Decimal
    let totalIncome: Decimal
    let totalExpenses: Decimal
    let netCashFlow: Decimal
    let accountCount: Int
    let transactionCount: Int
    let budgetCount: Int

    enum CodingKeys: String, CodingKey {
        case totalBalance = "total_balance"
        case totalIncome = "total_income"
        case totalExpenses = "total_expenses"
        case netCashFlow = "net_cash_flow"
        case accountCount = "account_count"
        case transactionCount = "transaction_count"
        case budgetCount = "budget_count"
    }
}

// MARK: - Budget Progress

/// API response model for budget progress
struct BudgetProgressResponse: Codable, Identifiable {
    let budgetId: Int
    let budgetName: String
    let category: TransactionCategory
    let period: BudgetPeriod
    let budgetAmount: Decimal
    let spent: Decimal
    let remaining: Decimal
    let percentUsed: Double
    let isOverBudget: Bool
    let periodStart: Date
    let periodEnd: Date
    let transactionCount: Int

    var id: Int { budgetId }

    enum CodingKeys: String, CodingKey {
        case budgetId = "budget_id"
        case budgetName = "budget_name"
        case category, period
        case budgetAmount = "budget_amount"
        case spent, remaining
        case percentUsed = "percent_used"
        case isOverBudget = "is_over_budget"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case transactionCount = "transaction_count"
    }
}

/// API response model for aggregated budget progress summary
struct BudgetProgressSummary: Codable {
    let totalBudgeted: Decimal
    let totalSpent: Decimal
    let totalRemaining: Decimal
    let overallPercentUsed: Double
    let budgetsOverLimit: Int
    let budgetsOnTrack: Int
    let budgetProgress: [BudgetProgressResponse]

    enum CodingKeys: String, CodingKey {
        case totalBudgeted = "total_budgeted"
        case totalSpent = "total_spent"
        case totalRemaining = "total_remaining"
        case overallPercentUsed = "overall_percent_used"
        case budgetsOverLimit = "budgets_over_limit"
        case budgetsOnTrack = "budgets_on_track"
        case budgetProgress = "budget_progress"
    }
}

/// Local view model for budget progress (can be created from API response)
struct BudgetProgress: Identifiable {
    let id: Int
    let budget: Budget
    let spent: Decimal
    let remaining: Decimal
    let percentUsed: Double

    var isOverBudget: Bool {
        spent > budget.amount
    }

    /// Initialize from API response and matching budget
    init(from response: BudgetProgressResponse, budget: Budget) {
        self.id = response.budgetId
        self.budget = budget
        self.spent = response.spent
        self.remaining = response.remaining
        self.percentUsed = response.percentUsed
    }

    /// Initialize with explicit values (for local calculation fallback)
    init(id: Int, budget: Budget, spent: Decimal, remaining: Decimal, percentUsed: Double) {
        self.id = id
        self.budget = budget
        self.spent = spent
        self.remaining = remaining
        self.percentUsed = percentUsed
    }
}
