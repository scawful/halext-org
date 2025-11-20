import { API_BASE_URL } from './helpers'

export interface FinanceAccount {
  id: number
  account_name: string
  account_type: string
  institution_name?: string | null
  account_number?: string | null
  balance: number
  currency: string
  is_active: boolean
  theme_emoji?: string | null
  accent_color?: string | null
  last_synced?: string | null
}

export interface FinanceAccountCreate {
  account_name: string
  account_type: string
  institution_name?: string
  account_number?: string
  balance: number
  currency?: string
  theme_emoji?: string
  accent_color?: string
}

export interface FinanceBudget {
  id: number
  name: string
  category: string
  limit_amount: number
  spent_amount: number
  period: string
  emoji?: string | null
  color_hex?: string | null
}

export interface FinanceBudgetCreate {
  name: string
  category: string
  limit_amount: number
  period?: string
  emoji?: string
  color_hex?: string
}

export interface FinanceTransaction {
  id: number
  account_id: number
  amount: number
  description: string
  category: string
  transaction_type: string
  transaction_date: string
  merchant?: string | null
  notes?: string | null
  tags: string[]
  mood_icon?: string | null
}

export interface FinanceTransactionCreate {
  account_id: number
  amount: number
  description: string
  category: string
  transaction_type: 'debit' | 'credit'
  transaction_date?: string
  merchant?: string
  notes?: string
  tags?: string[]
  mood_icon?: string
}

export interface FinanceSummary {
  total_balance: number
  active_accounts: number
  monthly_spending: number
  monthly_income: number
  budget_progress: FinanceBudget[]
  recent_transactions: FinanceTransaction[]
}

const authHeaders = (token: string) => ({
  Authorization: `Bearer ${token}`,
  'Content-Type': 'application/json',
})

export async function getFinanceAccounts(token: string): Promise<FinanceAccount[]> {
  const response = await fetch(`${API_BASE_URL}/finance/accounts`, {
    headers: authHeaders(token),
  })
  if (!response.ok) throw new Error('Failed to load accounts')
  return response.json()
}

export async function createFinanceAccount(token: string, payload: FinanceAccountCreate) {
  const response = await fetch(`${API_BASE_URL}/finance/accounts`, {
    method: 'POST',
    headers: authHeaders(token),
    body: JSON.stringify(payload),
  })
  if (!response.ok) throw new Error('Failed to create account')
  return response.json()
}

export async function getFinanceBudgets(token: string): Promise<FinanceBudget[]> {
  const response = await fetch(`${API_BASE_URL}/finance/budgets`, {
    headers: authHeaders(token),
  })
  if (!response.ok) throw new Error('Failed to load budgets')
  return response.json()
}

export async function createFinanceBudget(token: string, payload: FinanceBudgetCreate) {
  const response = await fetch(`${API_BASE_URL}/finance/budgets`, {
    method: 'POST',
    headers: authHeaders(token),
    body: JSON.stringify(payload),
  })
  if (!response.ok) throw new Error('Failed to create budget')
  return response.json()
}

export async function getFinanceSummary(token: string): Promise<FinanceSummary> {
  const response = await fetch(`${API_BASE_URL}/finance/summary`, {
    headers: authHeaders(token),
  })
  if (!response.ok) throw new Error('Failed to load summary')
  return response.json()
}

export async function createFinanceTransaction(token: string, payload: FinanceTransactionCreate) {
  const response = await fetch(`${API_BASE_URL}/finance/transactions`, {
    method: 'POST',
    headers: authHeaders(token),
    body: JSON.stringify({
      ...payload,
      tags: payload.tags ?? [],
    }),
  })
  if (!response.ok) throw new Error('Failed to create transaction')
  return response.json()
}

export async function getFinanceTransactions(token: string, accountId?: number, limit = 25) {
  const params = new URLSearchParams({ limit: String(limit) })
  if (accountId) params.append('account_id', String(accountId))
  const response = await fetch(`${API_BASE_URL}/finance/transactions?${params.toString()}`, {
    headers: authHeaders(token),
  })
  if (!response.ok) throw new Error('Failed to load transactions')
  return response.json()
}
