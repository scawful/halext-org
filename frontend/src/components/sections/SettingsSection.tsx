import { useAiProvider } from '../../contexts/AiProviderContext'
import { useAiModels } from '../../hooks/useAiModels'
import { AiModelSelector } from '../ai/AiModelSelector'

interface SettingsSectionProps {
  token: string
}

export const SettingsSection = ({ token }: SettingsSectionProps) => {
  const {
    selectedModelId,
    disableCloudProviders,
    setDisableCloudProviders,
    resetToDefault,
  } = useAiProvider()

  const { defaultModelId, currentModel, isLoading } = useAiModels(token)

  return (
    <div className="h-full overflow-auto">
      <div className="p-6 border-b border-white/10">
        <h2 className="text-2xl font-bold text-purple-300">Settings</h2>
        <p className="text-sm text-gray-400 mt-1">
          Configure your AI preferences and application settings
        </p>
      </div>

      <div className="p-6 space-y-8">
        {/* AI Settings */}
        <section className="space-y-4">
          <div className="border-b border-white/10 pb-2">
            <h3 className="text-lg font-semibold text-purple-300">AI Settings</h3>
            <p className="text-xs text-gray-400 mt-1">
              Control which AI models and providers are available
            </p>
          </div>

          {/* Default Model Selection */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-300">
              Default AI Model
            </label>
            <p className="text-xs text-gray-400 mb-2">
              Select which model to use by default for all AI operations
            </p>
            <AiModelSelector
              token={token}
            />
            {defaultModelId && (
              <p className="text-xs text-gray-400">
                System default: <span className="text-purple-300">{defaultModelId}</span>
              </p>
            )}
          </div>

          {/* Cloud Provider Toggle */}
          <div className="space-y-2">
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={disableCloudProviders}
                onChange={(e) => setDisableCloudProviders(e.target.checked)}
                className="w-4 h-4 rounded border-white/20 bg-white/10 text-purple-600 focus:ring-purple-500 focus:ring-offset-0"
              />
              <div className="flex-1">
                <span className="text-sm font-medium text-gray-300">
                  Disable Cloud Providers
                </span>
                <p className="text-xs text-gray-400 mt-0.5">
                  Only use local and remote models (OpenAI, Gemini will be hidden)
                </p>
              </div>
            </label>
            {disableCloudProviders && (
              <div className="ml-7 p-3 bg-amber-500/10 border border-amber-500/30 rounded text-xs text-amber-300">
                Cloud providers are disabled. Only local and remote models will be available.
                Preferred sources: remote, openwebui
              </div>
            )}
          </div>

          {/* Reset to Default */}
          <div className="pt-4 border-t border-white/10">
            <button
              onClick={() => {
                if (confirm('Reset all AI preferences to default settings?')) {
                  resetToDefault()
                }
              }}
              className="px-4 py-2 bg-gray-600 hover:bg-gray-700 rounded transition-colors text-sm font-medium"
            >
              Reset to Default
            </button>
            <p className="text-xs text-gray-400 mt-2">
              This will clear your selected model and reset all AI preferences
            </p>
          </div>
        </section>

        {/* Model Information */}
        {!isLoading && currentModel && (
          <section className="space-y-4">
            <div className="border-b border-white/10 pb-2">
              <h3 className="text-lg font-semibold text-purple-300">Current Configuration</h3>
            </div>
            <div className="p-4 bg-white/5 backdrop-blur-sm rounded-lg border border-white/10 space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-400">Selected Model:</span>
                <span className="text-sm text-purple-300">
                  {selectedModelId || 'Using Default'}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-400">System Default:</span>
                <span className="text-sm text-purple-300">{defaultModelId || currentModel}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-400">Cloud Providers:</span>
                <span className="text-sm text-purple-300">
                  {disableCloudProviders ? 'Disabled' : 'Enabled'}
                </span>
              </div>
            </div>
          </section>
        )}

        {/* Info Section */}
        <section className="space-y-4">
          <div className="p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
            <h4 className="text-sm font-medium text-blue-300 mb-2">About AI Model Selection</h4>
            <ul className="text-xs text-gray-300 space-y-1.5 list-disc list-inside">
              <li>Your model preference applies across all AI features (chat, tasks, events, notes)</li>
              <li>Remote models run on your registered nodes (Mac Studio, Windows GPU, etc.)</li>
              <li>Cloud providers (OpenAI, Gemini) can be disabled for privacy</li>
              <li>Preferences are stored locally in your browser</li>
              <li>Reset to default to use the system-configured model</li>
            </ul>
          </div>
        </section>
      </div>
    </div>
  )
}
