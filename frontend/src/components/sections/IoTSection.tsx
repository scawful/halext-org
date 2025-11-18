import { useState } from 'react'
import { MdDeviceHub, MdLightbulbOutline, MdThermostat } from 'react-icons/md'
import './Section.css'

type Device = {
  id: number
  name: string
  type: 'light' | 'sensor' | 'arduino'
  status: 'online' | 'offline'
  value?: string
}

export const IoTSection = () => {
  const [devices] = useState<Device[]>([
    { id: 1, name: 'Living Room Light', type: 'light', status: 'online', value: 'On' },
    { id: 2, name: 'Temperature Sensor', type: 'sensor', status: 'online', value: '72°F' },
    { id: 3, name: 'Arduino Board #1', type: 'arduino', status: 'offline' },
  ])

  const getDeviceIcon = (type: string) => {
    switch (type) {
      case 'light':
        return <MdLightbulbOutline size={32} />
      case 'sensor':
        return <MdThermostat size={32} />
      default:
        return <MdDeviceHub size={32} />
    }
  }

  return (
    <div className="section-container">
      <div className="section-header">
        <h2>IoT & Devices</h2>
        <p className="muted">Monitor and control your connected devices</p>
      </div>

      <div className="devices-grid">
        {devices.map((device) => (
          <div
            key={device.id}
            className={`device-card ${device.status === 'offline' ? 'offline' : ''}`}
          >
            <div className="device-icon">{getDeviceIcon(device.type)}</div>
            <div className="device-info">
              <h3>{device.name}</h3>
              <div className="device-status">
                <span className={`status-dot ${device.status}`}></span>
                <span>{device.status}</span>
              </div>
              {device.value && <p className="device-value">{device.value}</p>}
            </div>
          </div>
        ))}

        <div className="device-card add-device">
          <button className="add-device-btn">
            <MdDeviceHub size={32} />
            <span>Add Device</span>
          </button>
        </div>
      </div>
    </div>
  )
}
