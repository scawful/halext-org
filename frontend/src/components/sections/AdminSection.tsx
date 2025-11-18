import { useState, useEffect } from 'react'
import {
  MdComputer,
  MdRefresh,
  MdAdd,
  MdDelete,
  MdCheckCircle,
  MdError,
  MdInfo,
  MdSettingsRemote,
  MdBuild,
} from 'react-icons/md'
import './AdminSection.css'

interface AIClient {
  id: number
  name: string
  node_type: string
  hostname: string
  port: number
  is_active: boolean
  is_public: boolean
  status: string
  last_seen_at: string | null
  capabilities: {
    models?: string[]
    model_count?: number
    last_response_time_ms?: number
  }
  node_metadata: Record<string, any>
  base_url: string
  owner_id: number
}

interface AdminSectionProps {
  token: string
}

export const AdminSection = ({ token }: AdminSectionProps) => {
  const [clients, setClients] = useState<AIClient[]>([])
  const [loading, setLoading] = useState(true)
  const [showAddForm, setShowAddForm] = useState(false)
  const [selectedClient, setSelectedClient] = useState<AIClient | null>(null)
  const [testingClient, setTestingClient] = useState<number | null>(null)
  const [rebuilding, setRebuilding] = useState(false)

  // Form state
  const [formData, setFormData] = useState({
    name: '',
    node_type: 'ollama',
    hostname: '',
    port: 11434,
    is_public: false,
  })

  const API_BASE = 'http://localhost:8000'

  const fetchClients = async () => {
    try {
      const response = await fetch(`${API_BASE}/admin/ai-clients`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })
      if (response.ok) {
        const data = await response.json()
        setClients(data)
      }
    } catch (error) {
      console.error('Error fetching clients:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchClients()
  }, [token])

  const handleAddClient = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      const response = await fetch(`${API_BASE}/admin/ai-clients`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(formData),
      })

      if (response.ok) {
        await fetchClients()
        setShowAddForm(false)
        setFormData({
          name: '',
          node_type: 'ollama',
          hostname: '',
          port: 11434,
          is_public: false,
        })
      }
    } catch (error) {
      console.error('Error adding client:', error)
    }
  }

  const handleTestConnection = async (clientId: number) => {
    setTestingClient(clientId)
    try {
      const response = await fetch(`${API_BASE}/admin/ai-clients/${clientId}/test`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        await fetchClients()
      }
    } catch (error) {
      console.error('Error testing connection:', error)
    } finally {
      setTestingClient(null)
    }
  }

  const handleDeleteClient = async (clientId: number) => {
    if (!confirm('Delete this AI client?')) return

    try {
      const response = await fetch(`${API_BASE}/admin/ai-clients/${clientId}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        await fetchClients()
        if (selectedClient?.id === clientId) {
          setSelectedClient(null)
        }
      }
    } catch (error) {
      console.error('Error deleting client:', error)
    }
  }

  const handleRebuildFrontend = async () => {
    if (!confirm('Rebuild frontend? This will take a few minutes.')) return

    setRebuilding(true)
    try {
      const response = await fetch(`${API_BASE}/admin/rebuild-frontend`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (response.ok) {
        const data = await response.json()
        alert(`✅ ${data.message}`)
      } else {
        const error = await response.json()
        alert(`❌ Build failed: ${error.detail}`)
      }
    } catch (error) {
      console.error('Error rebuilding frontend:', error)
      alert('❌ Error triggering rebuild')
    } finally {
      setRebuilding(false)
    }
  }

  const getStatusIcon = (status: string, online?: boolean) => {
    if (status === 'online' || online) {
      return <MdCheckCircle className="text-green-500" size={20} />
    }
    return <MdError className="text-red-500" size={20} />
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online':
        return 'bg-green-500/20 text-green-300 border-green-500/30'
      case 'offline':
        return 'bg-red-500/20 text-red-300 border-red-500/30'
      case 'timeout':
        return 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30'
      default:
        return 'bg-gray-500/20 text-gray-300 border-gray-500/30'
    }
  }

  if (loading) {
    return <div className="admin-section loading">Loading admin panel...</div>
  }

  return (
    <div className="admin-section">
      <div className="admin-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">AI Client Management</h2>
          <p className="text-sm text-gray-400 mt-1">
            Manage your distributed AI nodes (Ollama, OpenWebUI)
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => fetchClients()}
            className="btn-secondary"
          >
            <MdRefresh size={20} />
            Refresh
          </button>
          <button
            onClick={handleRebuildFrontend}
            disabled={rebuilding}
            className="btn-secondary"
          >
            <MdBuild size={20} />
            {rebuilding ? 'Building...' : 'Rebuild Frontend'}
          </button>
          <button
            onClick={() => setShowAddForm(!showAddForm)}
            className="btn-primary"
          >
            <MdAdd size={20} />
            Add Client
          </button>
        </div>
      </div>

      {/* Add Client Form */}
      {showAddForm && (
        <div className="client-form-card">
          <h3 className="text-lg font-semibold text-purple-300 mb-4">Add AI Client Node</h3>
          <form onSubmit={handleAddClient} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-300 mb-2">Name</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Mac Studio"
                  className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white"
                  required
                />
              </div>

              <div>
                <label className="block text-sm text-gray-300 mb-2">Type</label>
                <select
                  value={formData.node_type}
                  onChange={(e) => setFormData({ ...formData, node_type: e.target.value })}
                  className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white"
                >
                  <option value="ollama">Ollama</option>
                  <option value="openwebui">OpenWebUI</option>
                </select>
              </div>

              <div>
                <label className="block text-sm text-gray-300 mb-2">Hostname/IP</label>
                <input
                  type="text"
                  value={formData.hostname}
                  onChange={(e) => setFormData({ ...formData, hostname: e.target.value })}
                  placeholder="192.168.1.100 or mac.local"
                  className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white"
                  required
                />
              </div>

              <div>
                <label className="block text-sm text-gray-300 mb-2">Port</label>
                <input
                  type="number"
                  value={formData.port}
                  onChange={(e) => setFormData({ ...formData, port: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white"
                  required
                />
              </div>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="is_public"
                checked={formData.is_public}
                onChange={(e) => setFormData({ ...formData, is_public: e.target.checked })}
                className="w-4 h-4"
              />
              <label htmlFor="is_public" className="text-sm text-gray-300">
                Make public (available to all users)
              </label>
            </div>

            <div className="flex gap-2">
              <button type="submit" className="btn-primary">
                Add Client
              </button>
              <button
                type="button"
                onClick={() => setShowAddForm(false)}
                className="btn-secondary"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Clients Grid */}
      <div className="clients-grid">
        {clients.map((client) => (
          <div key={client.id} className="client-card">
            <div className="client-card-header">
              <div className="flex items-center gap-2">
                <MdComputer size={24} className="text-purple-400" />
                <div>
                  <h3 className="font-semibold text-white">{client.name}</h3>
                  <p className="text-xs text-gray-400">{client.node_type}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {getStatusIcon(client.status)}
                <span className={`px-2 py-1 rounded text-xs border ${getStatusColor(client.status)}`}>
                  {client.status}
                </span>
              </div>
            </div>

            <div className="client-card-body">
              <div className="client-info">
                <div className="info-row">
                  <MdSettingsRemote className="text-gray-400" />
                  <span className="text-sm">{client.base_url}</span>
                </div>

                {client.capabilities.models && (
                  <div className="info-row">
                    <MdInfo className="text-gray-400" />
                    <span className="text-sm">
                      {client.capabilities.model_count} models loaded
                    </span>
                  </div>
                )}

                {client.capabilities.last_response_time_ms && (
                  <div className="info-row">
                    <span className="text-xs text-gray-400">
                      Response: {client.capabilities.last_response_time_ms}ms
                    </span>
                  </div>
                )}

                {client.is_public && (
                  <div className="info-row">
                    <span className="text-xs text-blue-300">🌐 Public</span>
                  </div>
                )}
              </div>

              {/* Models List */}
              {client.capabilities.models && client.capabilities.models.length > 0 && (
                <div className="models-list">
                  <p className="text-xs text-gray-400 mb-2">Available Models:</p>
                  <div className="flex flex-wrap gap-1">
                    {client.capabilities.models.slice(0, 5).map((model) => (
                      <span
                        key={model}
                        className="px-2 py-1 bg-purple-500/20 text-purple-300 rounded text-xs"
                      >
                        {model}
                      </span>
                    ))}
                    {client.capabilities.models.length > 5 && (
                      <span className="px-2 py-1 text-gray-400 text-xs">
                        +{client.capabilities.models.length - 5} more
                      </span>
                    )}
                  </div>
                </div>
              )}
            </div>

            <div className="client-card-actions">
              <button
                onClick={() => handleTestConnection(client.id)}
                disabled={testingClient === client.id}
                className="action-btn"
              >
                <MdRefresh size={16} />
                {testingClient === client.id ? 'Testing...' : 'Test'}
              </button>
              <button
                onClick={() => setSelectedClient(client)}
                className="action-btn"
              >
                <MdInfo size={16} />
                Details
              </button>
              <button
                onClick={() => handleDeleteClient(client.id)}
                className="action-btn danger"
              >
                <MdDelete size={16} />
                Delete
              </button>
            </div>
          </div>
        ))}
      </div>

      {clients.length === 0 && !showAddForm && (
        <div className="empty-state">
          <MdComputer size={64} className="text-gray-600 mb-4" />
          <p className="text-gray-400 mb-4">No AI clients configured</p>
          <button onClick={() => setShowAddForm(true)} className="btn-primary">
            <MdAdd size={20} />
            Add Your First Client
          </button>
        </div>
      )}

      {/* Client Details Modal */}
      {selectedClient && (
        <div className="modal-overlay" onClick={() => setSelectedClient(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="text-xl font-bold text-purple-300">{selectedClient.name}</h3>
              <button onClick={() => setSelectedClient(null)} className="text-gray-400 hover:text-white">
                ×
              </button>
            </div>
            <div className="modal-body">
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-gray-400">Type</p>
                  <p className="text-white">{selectedClient.node_type}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-400">URL</p>
                  <p className="text-white font-mono">{selectedClient.base_url}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-400">Status</p>
                  <div className="flex items-center gap-2 mt-1">
                    {getStatusIcon(selectedClient.status)}
                    <span className={`px-2 py-1 rounded text-xs border ${getStatusColor(selectedClient.status)}`}>
                      {selectedClient.status}
                    </span>
                  </div>
                </div>
                {selectedClient.last_seen_at && (
                  <div>
                    <p className="text-sm text-gray-400">Last Seen</p>
                    <p className="text-white">{new Date(selectedClient.last_seen_at).toLocaleString()}</p>
                  </div>
                )}
                <div>
                  <p className="text-sm text-gray-400 mb-2">All Models ({selectedClient.capabilities.models?.length || 0})</p>
                  <div className="flex flex-wrap gap-2">
                    {selectedClient.capabilities.models?.map((model) => (
                      <span
                        key={model}
                        className="px-2 py-1 bg-purple-500/20 text-purple-300 rounded text-sm"
                      >
                        {model}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
