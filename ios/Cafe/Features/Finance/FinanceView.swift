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
    @State private var showingAddAccount = false
    @State private var selectedTab: FinanceTab = .overview

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
                    FinanceOverviewView(summary: summary, accounts: accounts)
                        .tag(FinanceTab.overview)

                    AccountsListView(accounts: accounts, onRefresh: loadAccounts)
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
            .task {
                await loadData()
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
            errorMessage = error.localizedDescription
        }
    }

    private func loadSummary() async {
        do {
            summary = try await APIClient.shared.getFinancialSummary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncAllAccounts() {
        _Concurrency.Task {
            for account in accounts {
                do {
                    _ = try await APIClient.shared.syncBankAccount(id: account.id)
                } catch {
                    print("Failed to sync account \(account.id): \(error)")
                }
            }
            await loadData()
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

                // Recent Transactions placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .padding(.horizontal)

                    Text("Transactions will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
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
    var body: some View {
        List {
            Text("Transactions feature coming soon")
                .foregroundColor(.secondary)
        }
        .listStyle(.plain)
    }
}

struct BudgetsListView: View {
    var body: some View {
        List {
            Text("Budgets feature coming soon")
                .foregroundColor(.secondary)
        }
        .listStyle(.plain)
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
                print("Failed to create account: \(error)")
            }

            isSubmitting = false
        }
    }
}

// MARK: - Preview

#Preview {
    FinanceView()
}
