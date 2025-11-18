import { useState } from 'react'
import type { LayoutWidget } from '../../types/models'
import './Widget.css'

type GiftListWidgetProps = {
  widget: LayoutWidget
  onUpdate: (widget: LayoutWidget) => void
}

export const GiftListWidget = ({ widget, onUpdate }: GiftListWidgetProps) => {
  const [giftInput, setGiftInput] = useState('')

  const giftItems = Array.isArray(widget.config?.items)
    ? (widget.config?.items as string[])
    : []

  const addGiftItem = () => {
    if (!giftInput.trim()) return
    const updated = {
      ...widget,
      config: { ...widget.config, items: [...giftItems, giftInput.trim()] },
    }
    onUpdate(updated)
    setGiftInput('')
  }

  const removeGiftItem = (item: string) => {
    const updated = {
      ...widget,
      config: {
        ...widget.config,
        items: giftItems.filter((entry) => entry !== item),
      },
    }
    onUpdate(updated)
  }

  return (
    <div className="widget-body">
      <ul className="widget-list">
        {giftItems.length === 0 && (
          <li className="muted">Add gift ideas without sharing the surprise.</li>
        )}
        {giftItems.map((item) => (
          <li key={item} className="gift-item">
            <span>{item}</span>
            <button type="button" onClick={() => removeGiftItem(item)}>
              remove
            </button>
          </li>
        ))}
      </ul>
      <div className="inline-form">
        <input
          value={giftInput}
          onChange={(e) => setGiftInput(e.target.value)}
          placeholder="Gift idea"
        />
        <button type="button" onClick={addGiftItem}>
          Add
        </button>
      </div>
    </div>
  )
}
