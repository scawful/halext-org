import { useEffect, useState } from 'react'
import {
  MdRefresh,
  MdAccessTime,
  MdOutlineSpeed,
  MdMemory,
  MdStorage,
  MdCommit,
  MdLink,
} from 'react-icons/md'
import { API_BASE_URL } from '../../utils/helpers'
import './ServerProjectsPanel.css'

type ResourceUsage = {
  total: number
  used: number
  free: number
  percent: number
}

type ServiceStatus = {
  name: string
  status: string
  last_checked: string
}

type ServerStatus = {
  hostname: string
  uptime_seconds: number
  uptime_human: string
  load_avg: {
    one: number
    five: number
    fifteen: number
  }
  memory: ResourceUsage
  disk: ResourceUsage
  services: ServiceStatus[]
  git: Record<string, string | null>
  generated_at: string
}

interface ServerProjectsPanelProps {
  token: string
}

const PROJECT_LINKS = [
  {
    label: 'Documentation Hub',
    url: 'https://github.com/halext-org/halext-org/tree/main/docs',
    description: 'Jump directly into the reorganized docs/ tree.',
  },
  {
    label: 'Server Field Guide',
    url: 'https://github.com/halext-org/halext-org/blob/main/docs/ops/SERVER_FIELD_GUIDE.md',
    description: 'Nginx, services, and SSH runbook.',
  },
  {
    label: 'AI Routing Plan',
    url: 'https://github.com/halext-org/halext-org/blob/main/docs/ai/AI_ROUTING_IMPLEMENTATION_PLAN.md',
    description: 'Current rollout checklist for distributed models.',
  },
  {
    label: 'Scripts Index',
    url: 'https://github.com/halext-org/halext-org/blob/main/scripts/README.md',
    description: 'One-stop reference for server/dev automation.',
  },
]

export const ServerProjectsPanel = ({ token }: ServerProjectsPanelProps) => {
  const [status, setStatus] = useState<ServerStatus | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const authHeaders: HeadersInit = {
    Authorization: `Bearer ${token}`,
  }

  const fetchStatus = async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetch(`${API_BASE_URL}/admin/server/status`, { headers: authHeaders })
      if (!response.ok) {
        throw new Error('Failed to load server status')
      }
      const data = await response.json()
      setStatus(data)
    } catch (err) {
      console.error('Server status error', err)
      setError(err instanceof Error ? err.message : 'Unable to load server status')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchStatus()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const formatBytes = (bytes: number) => {
    if (!bytes) return '0 B'
    const units = ['B', 'KB', 'MB', 'GB', 'TB']
    const index = Math.floor(Math.log(bytes) / Math.log(1024))
    const value = bytes / Math.pow(1024, index)
    return `${value.toFixed(index === 0 ? 0 : 1)} ${units[index]}`
  }

  const formatPercent = (value: number) => `${value.toFixed(1)}%`

  const statusClass = (value: string) => {
    if (!value) return 'status-badge status-unknown'
    const normalized = value.toLowerCase()
    if (normalized.includes('active') || normalized.includes('running')) {
      return 'status-badge status-ok'
    }
    if (normalized.includes('inactive') || normalized.includes('failed')) {
      return 'status-badge status-error'
    }
    return 'status-badge status-warn'
  }

  const formatDateTime = (iso?: string | null) => {
    if (!iso) return '—'
    return new Date(iso).toLocaleString()
  }

  if (loading && !status) {
    return (
      <div className="server-dashboard loading-state">
        Loading server metrics…
      </div>
    )
  }

  return (
    <div className="server-dashboard">
      <header className="admin-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">Server & Project Control</h2>
          <p className="text-sm text-gray-400">
            Monitor resource usage, service health, and jump to the docs/scripts that keep Halext + Zeniea moving.
          </p>
        </div>
        <button className="btn-secondary" onClick={fetchStatus} disabled={loading}>
          <MdRefresh size={18} /> {loading ? 'Refreshing…' : 'Refresh status'}
        </button>
      </header>

      {error && (
        <div className="server-alert">
          <span>{error}</span>
          <button className="btn-secondary" onClick={fetchStatus}>
            Retry
          </button>
        </div>
      )}

      <div className="server-grid">
        <div className="stat-card">
          <div className="stat-icon">
            <MdAccessTime size={20} />
          </div>
          <p className="stat-label">Uptime</p>
          <p className="stat-value">{status?.uptime_human ?? '—'}</p>
          <p className="stat-sub">{status?.hostname ?? ''}</p>
        </div>

        <div className="stat-card">
          <div className="stat-icon">
            <MdOutlineSpeed size={20} />
          </div>
          <p className="stat-label">Load Avg</p>
          <p className="stat-value">
            {status ? `${status.load_avg.one.toFixed(2)} / ${status.load_avg.five.toFixed(2)} / ${status.load_avg.fifteen.toFixed(2)}` : '—'}
          </p>
          <p className="stat-sub">1m / 5m / 15m</p>
        </div>

        <div className="stat-card">
          <div className="stat-icon">
            <MdMemory size={20} />
          </div>
          <p className="stat-label">Memory</p>
          <p className="stat-value">{status ? formatPercent(status.memory.percent) : '—'}</p>
          <p className="stat-sub">
            {status ? `${formatBytes(status.memory.used)} / ${formatBytes(status.memory.total)}` : ''}
          </p>
        </div>

        <div className="stat-card">
          <div className="stat-icon">
            <MdStorage size={20} />
          </div>
          <p className="stat-label">Disk</p>
          <p className="stat-value">{status ? formatPercent(status.disk.percent) : '—'}</p>
          <p className="stat-sub">
            {status ? `${formatBytes(status.disk.used)} / ${formatBytes(status.disk.total)}` : ''}
          </p>
        </div>

        <div className="stat-card">
          <div className="stat-icon">
            <MdCommit size={20} />
          </div>
          <p className="stat-label">Git</p>
          <p className="stat-value">
            {status?.git?.short_commit ?? '—'} {status?.git?.branch && `• ${status.git.branch}`}
          </p>
          <p className="stat-sub">Last commit {formatDateTime(status?.git?.last_commit_date)}</p>
        </div>
      </div>

      <div className="service-table">
        <div className="service-table-header">
          <h3 className="text-lg font-semibold text-purple-200">Core Services</h3>
          <span className="text-xs text-gray-400">
            Updated {status ? new Date(status.generated_at).toLocaleTimeString() : '—'}
          </span>
        </div>
        <div className="service-list">
          {(status?.services ?? []).map((service) => (
            <div key={service.name} className="service-row">
              <div>
                <p className="service-name">{service.name}</p>
                <p className="service-sub">Checked {formatDateTime(service.last_checked)}</p>
              </div>
              <span className={statusClass(service.status)}>{service.status}</span>
            </div>
          ))}
          {(!status || status.services.length === 0) && <p className="text-sm text-gray-400">No service data recorded yet.</p>}
        </div>
      </div>

      <div className="quick-links">
        <h3 className="text-lg font-semibold text-purple-200 mb-3">Project Shortcuts</h3>
        <div className="quick-links-grid">
          {PROJECT_LINKS.map((link) => (
            <a key={link.label} href={link.url} target="_blank" rel="noreferrer" className="quick-link-card">
              <div className="quick-link-icon">
                <MdLink size={18} />
              </div>
              <div>
                <p className="quick-link-title">{link.label}</p>
                <p className="quick-link-desc">{link.description}</p>
              </div>
            </a>
          ))}
        </div>
      </div>
    </div>
  )
}
