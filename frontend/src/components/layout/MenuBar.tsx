import { useState, useMemo } from 'react'
import {
  MdDashboard,
  MdTask,
  MdChat,
  MdSettings,
  MdCalendarToday,
  MdDeviceHub,
  MdImage,
  MdAdminPanelSettings,
  MdAdd,
  MdRestaurant,
  MdSearch,
  MdSavings,
  MdGroups,
} from 'react-icons/md'
import { FaRobot } from 'react-icons/fa'
import { ThemeSwitcher } from '../common/ThemeSwitcher'
import type { Task, EventItem, PageDetail } from '../../types/models'
import './MenuBar.css'

type MenuSection =
  | 'dashboard'
  | 'tasks'
  | 'chat'
  | 'calendar'
  | 'iot'
  | 'settings'
  | 'image-gen'
  | 'anime'
  | 'admin'
  | 'recipes'
  | 'finance'
  | 'social'

type MenuBarProps = {
  activeSection: MenuSection
  onSectionChange: (section: MenuSection) => void
  onLogout: () => void
  onOpenCreate: () => void
  username?: string
  tasks?: Task[]
  events?: EventItem[]
  pages?: PageDetail[]
}

export const MenuBar = ({
  activeSection,
  onSectionChange,
  onLogout,
  onOpenCreate,
  username,
  tasks = [],
  events = [],
  pages = [],
}: MenuBarProps) => {
  const [showSettings, setShowSettings] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [showSearchResults, setShowSearchResults] = useState(false)

  const menuItems = [
    { id: 'dashboard' as MenuSection, icon: MdDashboard, label: 'Dashboard' },
    { id: 'tasks' as MenuSection, icon: MdTask, label: 'Tasks' },
    { id: 'calendar' as MenuSection, icon: MdCalendarToday, label: 'Calendar' },
    { id: 'chat' as MenuSection, icon: MdChat, label: 'AI Chat' },
    { id: 'recipes' as MenuSection, icon: MdRestaurant, label: 'Recipes' },
    { id: 'finance' as MenuSection, icon: MdSavings, label: 'Finance' },
    { id: 'social' as MenuSection, icon: MdGroups, label: 'Social Circles' },
    { id: 'image-gen' as MenuSection, icon: MdImage, label: 'Image Generation' },
    { id: 'anime' as MenuSection, icon: FaRobot, label: 'Anime Girls' },
    { id: 'iot' as MenuSection, icon: MdDeviceHub, label: 'IoT & Devices' },
    { id: 'admin' as MenuSection, icon: MdAdminPanelSettings, label: 'Admin Panel' },
  ]

  const handleMenuClick = (section: MenuSection) => {
    onSectionChange(section)
    setShowSettings(false)
  }

  const searchResults = useMemo(() => {
    if (!searchQuery.trim()) return { tasks: [], events: [], pages: [] }
    const query = searchQuery.toLowerCase()
    return {
      tasks: tasks.filter(t => t.title.toLowerCase().includes(query)).slice(0, 5),
      events: events.filter(e => e.title.toLowerCase().includes(query)).slice(0, 5),
      pages: pages.filter(p => p.title.toLowerCase().includes(query)).slice(0, 5),
    }
  }, [searchQuery, tasks, events, pages])

  const hasResults = searchResults.tasks.length > 0 || searchResults.events.length > 0 || searchResults.pages.length > 0

  return (
    <nav className="menu-bar">
      <div className="menu-left">
        <div className="menu-brand">
          <span className="menu-logo">☕</span>
          <h1>Halext Org</h1>
        </div>
      </div>

      <div className="menu-items">
        {menuItems.map((item) => (
          <button
            key={item.id}
            className={`menu-item ${activeSection === item.id ? 'active' : ''}`}
            onClick={() => handleMenuClick(item.id)}
            title={item.label}
          >
            <item.icon size={24} />
          </button>
        ))}
      </div>

      <div className="global-search-container">
        <div className="search-input-wrapper">
          <MdSearch size={20} className="search-icon" />
          <input 
            type="text" 
            placeholder="Search..." 
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value)
              setShowSearchResults(true)
            }}
            onFocus={() => setShowSearchResults(true)}
            onBlur={() => setTimeout(() => setShowSearchResults(false), 200)}
          />
        </div>
        {showSearchResults && searchQuery && hasResults && (
          <div className="search-results-dropdown">
            {searchResults.tasks.length > 0 && (
              <div className="search-result-group">
                <div className="group-title">Tasks</div>
                {searchResults.tasks.map(task => (
                  <div 
                    key={task.id} 
                    className="search-result-item"
                    onClick={() => onSectionChange('tasks')}
                  >
                    <span className="result-title">{task.title}</span>
                    <span className="result-subtitle">
                      {task.due_date ? new Date(task.due_date).toLocaleDateString() : 'No date'}
                    </span>
                  </div>
                ))}
              </div>
            )}
            {searchResults.events.length > 0 && (
              <div className="search-result-group">
                <div className="group-title">Events</div>
                {searchResults.events.map(event => (
                  <div 
                    key={event.id} 
                    className="search-result-item"
                    onClick={() => onSectionChange('calendar')}
                  >
                    <span className="result-title">{event.title}</span>
                    <span className="result-subtitle">
                      {new Date(event.start_time).toLocaleDateString()}
                    </span>
                  </div>
                ))}
              </div>
            )}
            {searchResults.pages.length > 0 && (
              <div className="search-result-group">
                <div className="group-title">Pages</div>
                {searchResults.pages.map(page => (
                  <div 
                    key={page.id} 
                    className="search-result-item"
                    onClick={() => onSectionChange('dashboard')}
                  >
                    <span className="result-title">{page.title}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      <div className="menu-right">
        <button
          className="menu-item create-button"
          onClick={onOpenCreate}
          title="Create"
        >
          <MdAdd size={24} />
        </button>
        <div className="menu-user">
          <button
            className={`menu-item ${showSettings ? 'active' : ''}`}
            onClick={() => setShowSettings(!showSettings)}
            title="Workspace settings"
          >
            <MdSettings size={24} />
          </button>
          {showSettings && (
            <div className="settings-dropdown">
              <div className="settings-header">
                <strong>{username}</strong>
              </div>
              <ThemeSwitcher />
              <button onClick={onLogout} className="logout-button">
                Logout
              </button>
            </div>
          )}
        </div>
      </div>
    </nav>
  )
}

export type { MenuSection }
