import { useEffect, useMemo, useState } from 'react'
import { MdSavings, MdRocketLaunch, MdAdd, MdAutoAwesome, MdWallet, MdTrendingUp, MdRefresh } from 'react-icons/md'
import {
  createFinanceAccount,
  createFinanceBudget,
  createFinanceTransaction,
  getFinanceAccounts,
  getFinanceBudgets,
  getFinanceSummary,
  type FinanceAccount,
  type FinanceBudget,
  type FinanceTransaction,
} from '../../utils/financeApi'
import './FinanceSection.css'

interface FinanceSectionProps {
  token: string
}

const pastelBadges = ['#f472b6', '#fb923c', '#818cf8', '#34d399', '#38bdf8']

export const FinanceSection = ({ token }: FinanceSectionProps) => {
  const [accounts, setAccounts] = useState<FinanceAccount[]>([])
  const [budgets, setBudgets] = useState<FinanceBudget[]>([])
  const [summary, setSummary] = useState<{ total_balance: number; monthly_spending: number; monthly_income: number; recent_transactions: FinanceTransaction[] }>({
    total_balance: 0,
    monthly_spending: 0,
    monthly_income: 0,
    recent_transactions: [],
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [accountForm, setAccountForm] = useState({
    account_name: '',
    account_type: 'checking',
    institution_name: 'Halext Credit Union',
    balance: 1200,
    currency: 'USD',
    theme_emoji: '💖',
  })

  const [budgetForm, setBudgetForm] = useState({
    name: 'Cafe Adventures',
    category: 'experiences',
    limit_amount: 200,
    period: 'monthly',
    emoji: '🌈',
  })

  const [transactionForm, setTransactionForm] = useState({
    account_id: 0,
    amount: 24,
    description: 'Cozy Latte Date',
    category: 'dining',
    transaction_type: 'debit' as 'debit' | 'credit',
    mood_icon: '☕️',
  })

  useEffect(() => {
    refreshData()
  }, [token])

  const refreshData = async () => {
    setLoading(true)
    setError(null)
    try {
      const [acct, b, sum] = await Promise.all([
        getFinanceAccounts(token),
        getFinanceBudgets(token),
        getFinanceSummary(token),
      ])
      setAccounts(acct)
      setBudgets(b)
      setSummary(sum)
      if (acct.length > 0) {
        setTransactionForm((prev) => ({ ...prev, account_id: prev.account_id || acct[0].id }))
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load finance data')
    } finally {
      setLoading(false)
    }
  }

  const gradients = useMemo(() => {
    return accounts.reduce<Record<number, string>>((acc, account, index) => {
      acc[account.id] = pastelBadges[index % pastelBadges.length]
      return acc
    }, {})
  }, [accounts])

  const handleCreateAccount = async () => {
    if (!accountForm.account_name.trim()) return
    try {
      await createFinanceAccount(token, accountForm)
      setAccountForm((prev) => ({ ...prev, account_name: '' }))
      await refreshData()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not add account')
    }
  }

  const handleCreateBudget = async () => {
    if (!budgetForm.name.trim()) return
    try {
      await createFinanceBudget(token, budgetForm)
      setBudgetForm((prev) => ({ ...prev, name: 'Adventure Snacks' }))
      await refreshData()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not add budget')
    }
  }

  const handleCreateTransaction = async () => {
    if (!transactionForm.account_id) return
    try {
      await createFinanceTransaction(token, {
        ...transactionForm,
        tags: ['cafe'],
      })
      await refreshData()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not send sparkle')
    }
  }

  return (
    <div className="finance-section">
      <header className="finance-header">
        <div>
          <p className="overline">Halext Piggy Bank</p>
          <h2>
            <span className="emoji">✨</span> Playful Finance
          </h2>
          <p className="muted">Budget with vibes, celebrate cozy wins, and keep group adventures on track.</p>
        </div>
        <button className="refresh-btn" onClick={refreshData} disabled={loading}>
          <MdRefresh />
          Refresh
        </button>
      </header>

      {error && <div className="finance-error">{error}</div>}

      <section className="finance-summary-grid">
        <div className="summary-card">
          <div className="summary-icon gradient-purple">
            <MdSavings size={22} />
          </div>
          <div>
            <p className="label">Total Balance</p>
            <h3>${summary.total_balance.toLocaleString(undefined, { maximumFractionDigits: 0 })}</h3>
          </div>
        </div>
        <div className="summary-card">
          <div className="summary-icon gradient-pink">
            <MdTrendingUp size={22} />
          </div>
          <div>
            <p className="label">Monthly Income</p>
            <h3>${summary.monthly_income.toFixed(0)}</h3>
          </div>
        </div>
        <div className="summary-card">
          <div className="summary-icon gradient-teal">
            <MdRocketLaunch size={22} />
          </div>
          <div>
            <p className="label">Adventures Spent</p>
            <h3>${summary.monthly_spending.toFixed(0)}</h3>
          </div>
        </div>
      </section>

      <section className="finance-panels">
        <div className="panel">
          <div className="panel-header">
            <h3>
              <span className="emoji">💼</span> Dreamy Accounts
            </h3>
            <small>{accounts.length} linked</small>
          </div>
          <div className="account-grid">
            {accounts.map((account) => (
              <div key={account.id} className="account-card" style={{ borderColor: gradients[account.id] }}>
                <div className="account-top">
                  <span className="account-emoji">{account.theme_emoji || '💳'}</span>
                  <div>
                    <p className="account-name">{account.account_name}</p>
                    <p className="muted">{account.institution_name}</p>
                  </div>
                </div>
                <p className="balance">${account.balance.toLocaleString(undefined, { maximumFractionDigits: 0 })}</p>
                <p className="muted">{account.account_type}</p>
              </div>
            ))}
          </div>
          <div className="mini-form">
            <input
              type="text"
              placeholder="Add sparkle account"
              value={accountForm.account_name}
              onChange={(e) => setAccountForm({ ...accountForm, account_name: e.target.value })}
            />
            <button onClick={handleCreateAccount}>
              <MdAdd /> Add
            </button>
          </div>
        </div>

        <div className="panel">
          <div className="panel-header">
            <h3>
              <span className="emoji">🍥</span> Budgets with Personality
            </h3>
            <small>{budgets.length} active</small>
          </div>
          <div className="budget-stack">
            {budgets.map((budget) => {
              const percent = Math.min(100, Math.round((budget.spent_amount / budget.limit_amount) * 100))
              return (
                <div key={budget.id} className="budget-row">
                  <div className="budget-label">
                    <span className="budget-emoji">{budget.emoji || '🥨'}</span>
                    <div>
                      <p>{budget.name}</p>
                      <small>{budget.category}</small>
                    </div>
                  </div>
                  <div className="budget-progress">
                    <div
                      className="budget-bar"
                      style={{
                        width: `${percent}%`,
                        background: budget.color_hex || '#a78bfa',
                      }}
                    />
                  </div>
                  <div className="budget-amounts">
                    <span>${budget.spent_amount.toFixed(0)}</span>
                    <small>/ ${budget.limit_amount.toFixed(0)}</small>
                  </div>
                </div>
              )
            })}
          </div>
          <div className="mini-form">
            <input
              type="text"
              placeholder="Dreamy budget name"
              value={budgetForm.name}
              onChange={(e) => setBudgetForm({ ...budgetForm, name: e.target.value })}
            />
            <button onClick={handleCreateBudget}>
              <MdAdd /> Track
            </button>
          </div>
        </div>

        <div className="panel">
          <div className="panel-header">
            <h3>
              <span className="emoji">💌</span> Send a Cozy Transaction
            </h3>
          </div>
          <div className="transaction-form">
            <select
              value={transactionForm.account_id}
              onChange={(e) => setTransactionForm({ ...transactionForm, account_id: Number(e.target.value) })}
            >
              {accounts.map((account) => (
                <option key={account.id} value={account.id}>
                  {account.account_name}
                </option>
              ))}
            </select>
            <input
              type="number"
              value={transactionForm.amount}
              onChange={(e) => setTransactionForm({ ...transactionForm, amount: Number(e.target.value) })}
            />
            <input
              type="text"
              value={transactionForm.description}
              onChange={(e) => setTransactionForm({ ...transactionForm, description: e.target.value })}
            />
            <div className="toggle">
              <button
                className={transactionForm.transaction_type === 'debit' ? 'active' : ''}
                onClick={() => setTransactionForm({ ...transactionForm, transaction_type: 'debit' })}
                type="button"
              >
                Spend
              </button>
              <button
                className={transactionForm.transaction_type === 'credit' ? 'active' : ''}
                onClick={() => setTransactionForm({ ...transactionForm, transaction_type: 'credit' })}
                type="button"
              >
                Boost
              </button>
            </div>
            <button className="cta" onClick={handleCreateTransaction} disabled={!transactionForm.account_id}>
              <MdAutoAwesome /> Sprinkle Magic
            </button>
          </div>

          <div className="recent-feed">
            {summary.recent_transactions.map((tx) => (
              <div key={tx.id} className="feed-row">
                <div className={`feed-icon ${tx.transaction_type === 'credit' ? 'credit' : 'debit'}`}>
                  <MdWallet />
                </div>
                <div>
                  <p>{tx.description}</p>
                  <small>{new Date(tx.transaction_date).toLocaleDateString()}</small>
                </div>
                <div className={tx.transaction_type === 'credit' ? 'credit' : ''}>
                  {tx.transaction_type === 'credit' ? '+' : '-'}${tx.amount.toFixed(0)}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}
