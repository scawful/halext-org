import { useState, useEffect } from 'react'
import type { OpenWebUiStatus } from '../../types/models'
import { getOpenWebUISyncStatus, syncUserToOpenWebUI, getOpenWebUISSO } from '../../utils/aiApi'
import './Widget.css'

type OpenWebUIWidgetProps = {
  openwebui: OpenWebUiStatus | null
  token: string
}

export const OpenWebUIWidget = ({ openwebui, token }: OpenWebUIWidgetProps) => {
  const [syncStatus, setSyncStatus] = useState<any>(null)
  const [syncing, setSyncing] = useState(false)
  const [ssoUrl, setSsoUrl] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadSyncStatus()
  }, [token])

  const loadSyncStatus = async () => {
    try {
      const status = await getOpenWebUISyncStatus(token)
      setSyncStatus(status)
    } catch (error) {
      console.error('Failed to load sync status:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSync = async () => {
    setSyncing(true)
    try {
      const result = await syncUserToOpenWebUI(token)
      if (result.success) {
        alert(`✓ ${result.message}`)
        loadSyncStatus()
      } else {
        alert(`✗ ${result.error || 'Sync failed'}`)
      }
    } catch (error) {
      alert('Failed to sync user')
    } finally {
      setSyncing(false)
    }
  }

  const handleOpenSSO = async () => {
    try {
      const result = await getOpenWebUISSO(token)
      window.open(result.sso_url, '_blank')
    } catch (error) {
      alert('Failed to generate SSO link')
    }
  }

  if (!openwebui?.enabled || !openwebui.url) {
    return (
      <div className="widget-body">
        <div className="space-y-4 p-4">
          <p className="text-gray-400 text-sm">OpenWebUI is not configured.</p>

          {!loading && syncStatus && (
            <div className="space-y-2 text-xs text-gray-400">
              <p>Status: {syncStatus.configured ? '✓ Configured' : '✗ Not configured'}</p>
              {syncStatus.openwebui_url && (
                <p className="font-mono text-xs truncate">{syncStatus.openwebui_url}</p>
              )}
            </div>
          )}

          <p className="text-sm text-gray-500 italic">
            Start OpenWebUI on the server to use this feature.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="widget-body">
      <div className="space-y-4 p-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-sm font-medium text-purple-300">OpenWebUI</h3>
            <p className="text-xs text-gray-400">Advanced AI chat interface</p>
          </div>

          {syncStatus?.features?.sso && (
            <button
              onClick={handleOpenSSO}
              className="px-3 py-1.5 bg-purple-600 hover:bg-purple-700 rounded text-xs font-medium transition-colors"
            >
              Open WebUI
            </button>
          )}
        </div>

        {syncStatus?.enabled && (
          <div className="space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="text-gray-400">User Sync:</span>
              <span className={syncStatus.features.user_provisioning ? 'text-green-400' : 'text-gray-400'}>
                {syncStatus.features.user_provisioning ? '✓ Enabled' : '✗ Disabled'}
              </span>
            </div>

            {syncStatus.features.user_provisioning && (
              <button
                onClick={handleSync}
                disabled={syncing}
                className="w-full px-3 py-1.5 bg-white/10 hover:bg-white/20 border border-white/20 rounded text-xs transition-colors disabled:opacity-50"
              >
                {syncing ? 'Syncing...' : 'Sync Account'}
              </button>
            )}
          </div>
        )}

        <div className="border-t border-white/10 pt-4">
          <div className="aspect-video rounded overflow-hidden border border-white/10 bg-white/5">
            <iframe
              title="OpenWebUI"
              src={openwebui.url}
              className="w-full h-full"
            />
          </div>
        </div>

        <p className="text-xs text-gray-500 text-center">
          Use the "Open WebUI" button above for full-screen access with SSO
        </p>
      </div>
    </div>
  )
}
