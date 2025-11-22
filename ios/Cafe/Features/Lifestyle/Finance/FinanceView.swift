//
//  FinanceView.swift
//  Cafe
//
//  Main financial management interface
//

import SwiftUI

struct FinanceView: View {
    @State private var accounts: [BankAccount] = []
    @State private var summary: FinancialSummary?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRetry = false
    @State private var showingAddAccount = false
    @State private var selectedTab: FinanceTab = .overview
    @State private var searchText = ""

    var filteredAccounts: [BankAccount] {
        if searchText.isEmpty {
            return accounts
        }
        return accounts.filter { account in
            account.accountName.localizedCaseInsensitiveContains(searchText) ||
            account.institutionName.localizedCaseInsensitiveContains(searchText) ||
            account.accountType.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    enum FinanceTab: String, CaseIterable {
        case overview = "Overview"
        case accounts = "Accounts"
        case transactions = "Transactions"
        case budgets = "Budgets"

        var icon: String {
            switch self {
            case .overview: return "chart.pie"
            case .accounts: return "building.columns"
            case .transactions: return "list.bullet.rectangle"
            case .budgets: return "chart.bar"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    ForEach(FinanceTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    FinanceOverviewView(summary: summary, accounts: filteredAccounts)
                        .tag(FinanceTab.overview)

                    AccountsListView(accounts: filteredAccounts, onRefresh: loadAccounts)
                        .tag(FinanceTab.accounts)

                    TransactionsListView()
                        .tag(FinanceTab.transactions)

                    BudgetsListView()
                        .tag(FinanceTab.budgets)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Finance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingAddAccount = true }) {
                            Label("Add Account", systemImage: "plus.circle")
                        }

                        Button(action: syncAllAccounts) {
                            Label("Sync All", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddBankAccountView(onAccountAdded: loadAccounts)
            }
            .searchable(text: $searchText, prompt: "Search accounts")
            .task {
                await loadData()
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                    showRetry = false
                }
                if showRetry {
                    Button("Retry") {
                        errorMessage = nil
                        showRetry = false
                        _Concurrency.Task {
                            await loadData()
                        }
                    }
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private func loadData() async {
        await loadAccounts()
        await loadSummary()
    }

    private func loadAccounts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            accounts = try await APIClient.shared.getBankAccounts()
        } catch {
            let categorized = ErrorCategorizer.categorize(error: error, defaultMessage: "Failed to load accounts")
            errorMessage = categorized.message
            showRetry = categorized.shouldShowRetry
        }
    }

    private func loadSummary() async {
        do {
            summary = try await APIClient.shared.getFinancialSummary()
        } catch {
            let categorized = ErrorCategorizer.categorize(error: error, defaultMessage: "Failed to load financial summary")
            errorMessage = categorized.message
            showRetry = categorized.shouldShowRetry
        }
    }

    private func syncAllAccounts() {
        _Concurrency.Task {
            var syncErrors: [String] = []
            for account in accounts {
                do {
                    _ = try await APIClient.shared.syncBankAccount(id: account.id)
                } catch {
                    syncErrors.append(account.accountName)
                }
            }
            await loadData()
            if !syncErrors.isEmpty {
                let categorized = ErrorCategorizer.categorize(
                    error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sync: \(syncErrors.joined(separator: ", "))"]),
                    defaultMessage: "Failed to sync some accounts"
                )
                errorMessage = categorized.message
                showRetry = categorized.shouldShowRetry
            }
        }
    }
}

// MARK: - Finance Overview

struct FinanceOverviewView: View {
    let summary: FinancialSummary?
    let accounts: [BankAccount]

    var totalBalance: Decimal {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Total Balance Card
                VStack(spacing: 12) {
                    Text("Total Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("$\(formattedAmount(totalBalance))")
                        .font(.system(size: 36, weight: .bold))

                    if let summary = summary {
                        HStack(spacing: 32) {
                            StatItem(
                                title: "Income",
                                value: "$\(formattedAmount(summary.totalIncome))",
                                color: .green
                            )

                            StatItem(
                                title: "Expenses",
                                value: "$\(formattedAmount(summary.totalExpenses))",
                                color: .red
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Accounts Summary
                if !accounts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accounts")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(accounts.prefix(3)) { account in
                            AccountRowView(account: account)
                        }

                        if accounts.count > 3 {
                            Text("+ \(accounts.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                }

                // Recent Transactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .padding(.horizontal)

                    if let summary = summary, summary.transactionCount > 0 {
                        NavigationLink(destination: TransactionsListView()) {
                            HStack {
                                Text("\(summary.transactionCount) transactions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    } else {
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Account Row

struct AccountRowView: View {
    let account: BankAccount

    var body: some View {
        HStack {
            Image(systemName: account.accountType.icon)
                .font(.title2)
                .foregroundColor(colorFromString(account.accountType.color))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(account.accountName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack {
                    Text(account.institutionName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•••• \(account.accountNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("$\(formattedAmount(account.balance))")
                .font(.body)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Placeholder Views

struct AccountsListView: View {
    let accounts: [BankAccount]
    let onRefresh: () async -> Void

    var body: some View {
        List {
            ForEach(accounts) { account in
                NavigationLink(destination: AccountDetailView(account: account)) {
                    AccountRowView(account: account)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await onRefresh()
        }
    }
}

struct AccountDetailView: View {
    let account: BankAccount

    var body: some View {
        List {
            Section("Account Details") {
                LabeledContent("Name", value: account.accountName)
                LabeledContent("Type", value: account.accountType.rawValue.capitalized)
                LabeledContent("Institution", value: account.institutionName)
                LabeledContent("Account Number", value: "•••• \(account.accountNumber)")
                LabeledContent("Balance", value: "$\(formattedAmount(account.balance))")
            }

            if let lastSynced = account.lastSynced {
                Section("Sync") {
                    LabeledContent("Last Synced", value: lastSynced, format: .dateTime)
                }
            }
        }
        .navigationTitle(account.accountName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}

struct TransactionsListView: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRetry = false
    @State private var selectedAccountId: Int?
    @State private var showingAddTransaction = false
    @State private var accounts: [BankAccount] = []
    
    private func transactionAddedCallback() {
        _Concurrency.Task {
            await loadTransactions()
        }
    }

    var body: some View {
        List {
            if isLoading && transactions.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if transactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Transactions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a transaction to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(transactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await loadTransactions()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTransaction = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(accounts: accounts, onTransactionAdded: { transactionAddedCallback() })
        }
        .task {
            await loadAccounts()
            await loadTransactions()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {
                errorMessage = nil
                showRetry = false
            }
            if showRetry {
                Button("Retry") {
                    errorMessage = nil
                    showRetry = false
                    _Concurrency.Task {
                        await loadTransactions()
                    }
                }
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    private func loadAccounts() async {
        do {
            accounts = try await APIClient.shared.getBankAccounts()
        } catch {
            let categorized = ErrorCategorizer.categorize(error: error, defaultMessage: "Failed to load accounts")
            errorMessage = categorized.message
            showRetry = categorized.shouldShowRetry
        }
    }

    private func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            transactions = try await APIClient.shared.getTransactions(accountId: selectedAccountId, limit: 100)
        } catch {
            let categorized = ErrorCategorizer.categorize(error: error, defaultMessage: "Failed to load transactions")
            errorMessage = categorized.message
            showRetry = categorized.shouldShowRetry
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundColor(colorFromString(transaction.category.color))
                .frame(width: 40, height: 40)
                .background(colorFromString(transaction.category.color).opacity(0.1))
                .clipShape(Circle())

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(transaction.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let merchant = transaction.merchant {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(merchant)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.transactionType == .debit ? "-$\(formattedAmount(abs(transaction.amount)))" : "+$\(formattedAmount(transaction.amount))")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.transactionType == .debit ? .red : .green)

                Text(transaction.transactionDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink": return .pink
        case "teal": return .teal
        case "brown": return .brown
        case "indigo": return .indigo
        case "cyan": return .cyan
        case "mint": return .mint
        case "gray": return .gray
        default: return .blue
        }
    }
}

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    let accounts: [BankAccount]
    let onTransactionAdded: () -> Void

    @State private var selectedAccountId: Int?
    @State private var amount = ""
    @State private var description = ""
    @State private var category: TransactionCategory = .other
    @State private var transactionType: TransactionType = .debit
    @State private var merchant = ""
    @State private var notes = ""
    @State private var transactionDate = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    Picker("Account", selection: $selectedAccountId) {
                        Text("Select Account").tag(nil as Int?)
                        ForEach(accounts) { account in
                            Text(account.accountName).tag(account.id as Int?)
                        }
                    }

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    TextField("Description", text: $description)

                    Picker("Category", selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue.capitalized, systemImage: cat.icon).tag(cat)
                        }
                    }

                    Picker("Type", selection: $transactionType) {
                        Text("Debit").tag(TransactionType.debit)
                        Text("Credit").tag(TransactionType.credit)
                    }

                    DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                }

                Section("Additional Information") {
                    TextField("Merchant (optional)", text: $merchant)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button(action: submitTransaction) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add Transaction")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting || !isValid)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    var isValid: Bool {
        guard selectedAccountId != nil,
              Decimal(string: amount) != nil,
              !description.isEmpty else {
            return false
        }
        return true
    }

    private func submitTransaction() {
        guard let accountId = selectedAccountId,
              let amountDecimal = Decimal(string: amount) else { return }

        isSubmitting = true

        _Concurrency.Task {
            do {
                let transaction = TransactionCreate(
                    accountId: accountId,
                    amount: amountDecimal,
                    description: description,
                    category: category.rawValue,
                    transactionDate: transactionDate,
                    transactionType: transactionType.rawValue,
                    merchant: merchant.isEmpty ? nil : merchant,
                    notes: notes.isEmpty ? nil : notes,
                    tags: []
                )

                _ = try await APIClient.shared.createTransaction(transaction)
                onTransactionAdded()
                dismiss()
            } catch {
                errorMessage = ErrorCategorizer.userFriendlyMessage(for: error, defaultMessage: "Failed to create transaction")
            }

            isSubmitting = false
        }
    }
}

struct BudgetsListView: View {
    @State private var budgets: [Budget] = []
    @State private var isLoading = false
    @State private var isLoadingProgress = false
    @State private var errorMessage: String?
    @State private var showRetry = false
    @State private var showingAddBudget = false
    @State private var budgetProgressMap: [Int: BudgetProgressResponse] = [:]
    @State private var progressSummary: BudgetProgressSummary?

    private func budgetAddedCallback() {
        _Concurrency.Task {
            await loadBudgetsAndProgress()
        }
    }

    var body: some View {
        List {
            if isLoading && budgets.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if budgets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Budgets")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Create a budget to track your spending")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Budget Progress Summary Card
                if let summary = progressSummary {
                    BudgetSummaryCard(summary: summary)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                ForEach(budgets) { budget in
                    BudgetRowView(
                        budget: budget,
                        progress: budgetProgressMap[budget.id].map { response in
                            BudgetProgress(from: response, budget: budget)
                        }
                    )
                }
                .onDelete(perform: deleteBudgets)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await loadBudgetsAndProgress()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddBudget = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetView(onBudgetAdded: { budgetAddedCallback() })
        }
        .task {
            await loadBudgetsAndProgress()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {
                errorMessage = nil
                showRetry = false
            }
            if showRetry {
                Button("Retry") {
                    errorMessage = nil
                    showRetry = false
                    _Concurrency.Task {
                        await loadBudgetsAndProgress()
                    }
                }
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    private func loadBudgetsAndProgress() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load budgets first
            budgets = try await APIClient.shared.getBudgets()

            // Then load budget progress from API
            await loadBudgetProgress()
        } catch {
            let categorized = ErrorCategorizer.categorize(error: error, defaultMessage: "Failed to load budgets")
            errorMessage = categorized.message
            showRetry = categorized.shouldShowRetry
        }
    }

    private func loadBudgetProgress() async {
        isLoadingProgress = true
        defer { isLoadingProgress = false }

        do {
            // Load the budget progress summary which includes all individual progress
            let summary = try await APIClient.shared.getBudgetProgressSummary()
            progressSummary = summary

            // Build a map for quick lookup by budget ID
            budgetProgressMap = Dictionary(
                uniqueKeysWithValues: summary.budgetProgress.map { ($0.budgetId, $0) }
            )
        } catch {
            // Log the error but don't show to user - budgets still work without progress
            #if DEBUG
            print("Failed to load budget progress: \(error.localizedDescription)")
            #endif

            // Clear progress data on error
            budgetProgressMap = [:]
            progressSummary = nil
        }
    }

    private func deleteBudgets(at offsets: IndexSet) {
        for index in offsets {
            let budget = budgets[index]
            _Concurrency.Task {
                do {
                    try await APIClient.shared.deleteBudget(id: budget.id)
                    await loadBudgetsAndProgress()
                } catch {
                    errorMessage = ErrorCategorizer.userFriendlyMessage(for: error, defaultMessage: "Failed to delete budget")
                }
            }
        }
    }
}

// MARK: - Budget Summary Card

struct BudgetSummaryCard: View {
    let summary: BudgetProgressSummary

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Budget Overview")
                    .font(.headline)
                Spacer()
                Text("\(summary.budgetsOnTrack) on track")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)

                if summary.budgetsOverLimit > 0 {
                    Text("\(summary.budgetsOverLimit) over")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("$\(formattedAmount(summary.totalSpent)) spent")
                        .font(.subheadline)
                        .foregroundColor(summary.totalSpent > summary.totalBudgeted ? .red : .primary)

                    Spacer()

                    Text("of $\(formattedAmount(summary.totalBudgeted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)
                            .cornerRadius(5)

                        Rectangle()
                            .fill(summary.overallPercentUsed > 100 ? Color.red : Color.blue)
                            .frame(width: geometry.size.width * min(summary.overallPercentUsed / 100, 1.0), height: 10)
                            .cornerRadius(5)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(Int(summary.overallPercentUsed))% used")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("$\(formattedAmount(summary.totalRemaining)) remaining")
                        .font(.caption)
                        .foregroundColor(summary.totalRemaining < 0 ? .red : .green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}

struct BudgetRowView: View {
    let budget: Budget
    let progress: BudgetProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: budget.category.icon)
                    .font(.title3)
                    .foregroundColor(colorFromString(budget.category.color))
                    .frame(width: 40, height: 40)
                    .background(colorFromString(budget.category.color).opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.headline)

                    Text(budget.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(formattedAmount(budget.amount))")
                        .font(.headline)

                    Text(budget.period.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let progress = progress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Spent: $\(formattedAmount(progress.spent))")
                            .font(.subheadline)
                            .foregroundColor(progress.isOverBudget ? .red : .primary)

                        Spacer()

                        Text("\(Int(progress.percentUsed))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(progress.isOverBudget ? .red : .primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)

                            Rectangle()
                                .fill(progress.isOverBudget ? Color.red : Color.green)
                                .frame(width: geometry.size.width * min(progress.percentUsed / 100, 1.0), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)

                    if progress.isOverBudget {
                        Text("Over budget by $\(formattedAmount(progress.spent - budget.amount))")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("$\(formattedAmount(progress.remaining)) remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink": return .pink
        case "teal": return .teal
        case "brown": return .brown
        case "indigo": return .indigo
        case "cyan": return .cyan
        case "mint": return .mint
        case "gray": return .gray
        default: return .blue
        }
    }
}

struct AddBudgetView: View {
    @Environment(\.dismiss) var dismiss
    let onBudgetAdded: () -> Void

    @State private var name = ""
    @State private var category: TransactionCategory = .other
    @State private var amount = ""
    @State private var period: BudgetPeriod = .monthly
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue.capitalized, systemImage: cat.icon).tag(cat)
                        }
                    }

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Period", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized).tag(p)
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section {
                    Button(action: submitBudget) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Budget")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting || !isValid)
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    var isValid: Bool {
        guard !name.isEmpty,
              Decimal(string: amount) != nil else {
            return false
        }
        return true
    }

    private func submitBudget() {
        guard let amountDecimal = Decimal(string: amount) else { return }

        isSubmitting = true

        _Concurrency.Task {
            do {
                let budget = BudgetCreate(
                    name: name,
                    category: category.rawValue,
                    amount: amountDecimal,
                    period: period.rawValue,
                    startDate: startDate,
                    endDate: endDate
                )

                _ = try await APIClient.shared.createBudget(budget)
                onBudgetAdded()
                dismiss()
            } catch {
                errorMessage = ErrorCategorizer.userFriendlyMessage(for: error, defaultMessage: "Failed to create budget")
            }

            isSubmitting = false
        }
    }
}

// MARK: - Add Account View

struct AddBankAccountView: View {
    @Environment(\.dismiss) var dismiss
    let onAccountAdded: () async -> Void

    @State private var accountName = ""
    @State private var institutionName = ""
    @State private var accountType: AccountType = .checking
    @State private var accountNumber = ""
    @State private var balance = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Information") {
                    TextField("Account Name", text: $accountName)
                    TextField("Institution Name", text: $institutionName)

                    Picker("Account Type", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Label(type.rawValue.capitalized, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    TextField("Last 4 Digits", text: $accountNumber)
                        .keyboardType(.numberPad)

                    TextField("Current Balance", text: $balance)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button(action: submitAccount) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting || !isValid)
                }
            }
            .navigationTitle("Add Bank Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    var isValid: Bool {
        !accountName.isEmpty && !institutionName.isEmpty && !accountNumber.isEmpty && !balance.isEmpty
    }

    private func submitAccount() {
        guard let balanceDecimal = Decimal(string: balance) else { return }

        isSubmitting = true

        _Concurrency.Task {
            do {
                let account = BankAccountCreate(
                    accountName: accountName,
                    accountType: accountType.rawValue,
                    institutionName: institutionName,
                    accountNumber: accountNumber,
                    balance: balanceDecimal,
                    currency: "USD"
                )

                _ = try await APIClient.shared.createBankAccount(account)
                await onAccountAdded()
                dismiss()
            } catch {
                errorMessage = ErrorCategorizer.userFriendlyMessage(for: error, defaultMessage: "Failed to create account")
            }

            isSubmitting = false
        }
    }
}

// MARK: - Preview

#Preview {
    FinanceView()
}
