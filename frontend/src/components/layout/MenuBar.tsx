import { useState } from 'react'
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
} from 'react-icons/md'
import { FaRobot } from 'react-icons/fa'
import { ThemeSwitcher } from '../common/ThemeSwitcher'
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

type MenuBarProps = {
  activeSection: MenuSection
  onSectionChange: (section: MenuSection) => void
  onLogout: () => void
  onOpenCreate: () => void
  username?: string
}

export const MenuBar = ({
  activeSection,
  onSectionChange,
  onLogout,
  onOpenCreate,
  username,
}: MenuBarProps) => {
  const [showSettings, setShowSettings] = useState(false)

  const menuItems = [
    { id: 'dashboard' as MenuSection, icon: MdDashboard, label: 'Dashboard' },
    { id: 'tasks' as MenuSection, icon: MdTask, label: 'Tasks' },
    { id: 'calendar' as MenuSection, icon: MdCalendarToday, label: 'Calendar' },
    { id: 'chat' as MenuSection, icon: MdChat, label: 'AI Chat' },
    { id: 'image-gen' as MenuSection, icon: MdImage, label: 'Image Generation' },
    { id: 'anime' as MenuSection, icon: FaRobot, label: 'Anime Girls' },
    { id: 'iot' as MenuSection, icon: MdDeviceHub, label: 'IoT & Devices' },
    { id: 'admin' as MenuSection, icon: MdAdminPanelSettings, label: 'Admin Panel' },
  ]

  const handleMenuClick = (section: MenuSection) => {
    onSectionChange(section)
    setShowSettings(false)
  }

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
