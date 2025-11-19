import { useMemo, useState } from 'react'
import type { LayoutWidget } from '../../types/models'
import { randomId } from '../../utils/helpers'
import './Widget.css'

type GiftListItem = {
  id: string
  name: string
  recipient?: string
  occasion?: string
  purchased?: boolean
}

type GiftListWidgetProps = {
  widget: LayoutWidget
  onUpdate: (widget: LayoutWidget) => void
}

export const GiftListWidget = ({ widget, onUpdate }: GiftListWidgetProps) => {
  const [giftForm, setGiftForm] = useState({
    name: '',
    recipient: '',
    occasion: '',
  })

  const giftItems = useMemo<GiftListItem[]>(() => {
    if (!Array.isArray(widget.config?.items)) {
      return []
    }

    return (widget.config?.items as unknown[]).reduce<GiftListItem[]>(
      (acc, item, index) => {
        let normalized: GiftListItem | null = null
        if (typeof item === 'string') {
          normalized = {
            id: item,
            name: item,
            purchased: false,
          }
        } else if (item && typeof item === 'object') {
          const raw = item as Record<string, unknown>
          const id =
            typeof raw.id === 'string'
              ? raw.id
              : `gift-${widget.id}-${index}`
          const name =
            typeof raw.name === 'string' && raw.name.trim().length > 0
              ? raw.name
              : 'Gift idea'
          normalized = {
            id,
            name,
            recipient: typeof raw.recipient === 'string' ? raw.recipient : undefined,
            occasion: typeof raw.occasion === 'string' ? raw.occasion : undefined,
            purchased: typeof raw.purchased === 'boolean' ? raw.purchased : false,
          }
        }

        if (normalized) {
          acc.push(normalized)
        }
        return acc
      },
      []
    )
  }, [widget.config?.items, widget.id])

  const persistItems = (items: GiftListItem[]) => {
    onUpdate({
      ...widget,
      config: { ...widget.config, items },
    })
  }

  const addGiftItem = () => {
    if (!giftForm.name.trim()) return
    const newItem: GiftListItem = {
      id: randomId(),
      name: giftForm.name.trim(),
      recipient: giftForm.recipient.trim() || undefined,
      occasion: giftForm.occasion.trim() || undefined,
      purchased: false,
    }
    persistItems([newItem, ...giftItems])
    setGiftForm({ name: '', recipient: '', occasion: '' })
  }

  const removeGiftItem = (id: string) => {
    persistItems(giftItems.filter((entry) => entry.id !== id))
  }

  const togglePurchased = (id: string) => {
    persistItems(
      giftItems.map((item) =>
        item.id === id ? { ...item, purchased: !item.purchased } : item
      )
    )
  }

  return (
    <div className="widget-body">
      <ul className="widget-list">
        {giftItems.length === 0 && (
          <li className="muted">Add gift ideas without sharing the surprise.</li>
        )}
        {giftItems.map((item) => (
          <li key={item.id} className={`gift-item ${item.purchased ? 'purchased' : ''}`}>
            <div className="gift-item-details">
              <div className="gift-item-name">{item.name}</div>
              {(item.recipient || item.occasion) && (
                <div className="gift-item-meta">
                  {item.recipient && <span>For: {item.recipient}</span>}
                  {item.occasion && <span>Occasion: {item.occasion}</span>}
                </div>
              )}
            </div>
            <div className="gift-item-actions">
              <button type="button" onClick={() => togglePurchased(item.id)}>
                {item.purchased ? 'Unmark' : 'Mark purchased'}
              </button>
              <button type="button" onClick={() => removeGiftItem(item.id)}>
                Remove
              </button>
            </div>
          </li>
        ))}
      </ul>
      <div className="inline-form gift-form">
        <input
          value={giftForm.name}
          onChange={(e) => setGiftForm((prev) => ({ ...prev, name: e.target.value }))}
          placeholder="Gift idea"
        />
        <input
          value={giftForm.recipient}
          onChange={(e) => setGiftForm((prev) => ({ ...prev, recipient: e.target.value }))}
          placeholder="Recipient (optional)"
        />
        <input
          value={giftForm.occasion}
          onChange={(e) => setGiftForm((prev) => ({ ...prev, occasion: e.target.value }))}
          placeholder="Occasion (optional)"
        />
        <button type="button" onClick={addGiftItem} disabled={!giftForm.name.trim()}>
          Add
        </button>
      </div>
    </div>
  )
}
