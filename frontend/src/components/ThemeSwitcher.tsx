import { useEffect, useState } from 'react'
import './ThemeSwitcher.css'

type Theme = 'purple' | 'mocha' | 'catppuccin' | 'strawberry-matcha'

const themes: { id: Theme; name: string; icon: string }[] = [
  { id: 'purple', name: 'Purple Twilight', icon: '🌙' },
  { id: 'mocha', name: 'Mocha', icon: '☕' },
  { id: 'catppuccin', name: 'Catppuccin', icon: '🎨' },
  { id: 'strawberry-matcha', name: 'Strawberry Matcha', icon: '🍓' },
]

export const ThemeSwitcher = () => {
  const [currentTheme, setCurrentTheme] = useState<Theme>(() => {
    return (localStorage.getItem('cafe-theme') as Theme) || 'purple'
  })

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', currentTheme)
    localStorage.setItem('cafe-theme', currentTheme)
  }, [currentTheme])

  return (
    <div className="theme-switcher">
      <div className="theme-switcher-header">Theme</div>
      <div className="theme-grid">
        {themes.map((theme) => (
          <button
            key={theme.id}
            className={`theme-button ${currentTheme === theme.id ? 'active' : ''}`}
            onClick={() => setCurrentTheme(theme.id)}
            title={theme.name}
          >
            <span className="theme-icon">{theme.icon}</span>
            <span className="theme-name">{theme.name}</span>
          </button>
        ))}
      </div>
    </div>
  )
}
