import { createContext, useContext, useState, useEffect, type ReactNode } from 'react'

interface AiPreferences {
  selectedModelId?: string
  disableCloudProviders: boolean
  preferredSources: string[]
}

interface AiProviderContextType {
  selectedModelId?: string
  setSelectedModelId: (modelId?: string) => void
  disableCloudProviders: boolean
  setDisableCloudProviders: (disable: boolean) => void
  preferredSources: string[]
  resetToDefault: () => void
}

const AiProviderContext = createContext<AiProviderContextType | undefined>(undefined)

const AI_PREFERENCES_KEY = 'halext_ai_preferences'

function loadPreferences(): AiPreferences {
  try {
    const stored = localStorage.getItem(AI_PREFERENCES_KEY)
    if (stored) {
      return JSON.parse(stored)
    }
  } catch (error) {
    console.error('Failed to load AI preferences:', error)
  }
  return {
    disableCloudProviders: false,
    preferredSources: [],
  }
}

function savePreferences(preferences: AiPreferences) {
  try {
    localStorage.setItem(AI_PREFERENCES_KEY, JSON.stringify(preferences))
  } catch (error) {
    console.error('Failed to save AI preferences:', error)
  }
}

export function AiProviderProvider({ children }: { children: ReactNode }) {
  const [preferences, setPreferences] = useState<AiPreferences>(loadPreferences)

  useEffect(() => {
    savePreferences(preferences)
  }, [preferences])

  const setSelectedModelId = (modelId?: string) => {
    setPreferences((prev) => ({ ...prev, selectedModelId: modelId }))
  }

  const setDisableCloudProviders = (disable: boolean) => {
    setPreferences((prev) => ({
      ...prev,
      disableCloudProviders: disable,
      preferredSources: disable ? ['remote', 'openwebui'] : [],
    }))
  }

  const resetToDefault = () => {
    setPreferences({
      disableCloudProviders: false,
      preferredSources: [],
    })
  }

  return (
    <AiProviderContext.Provider
      value={{
        selectedModelId: preferences.selectedModelId,
        setSelectedModelId,
        disableCloudProviders: preferences.disableCloudProviders,
        setDisableCloudProviders,
        preferredSources: preferences.preferredSources,
        resetToDefault,
      }}
    >
      {children}
    </AiProviderContext.Provider>
  )
}

export function useAiProvider() {
  const context = useContext(AiProviderContext)
  if (!context) {
    throw new Error('useAiProvider must be used within AiProviderProvider')
  }
  return context
}
