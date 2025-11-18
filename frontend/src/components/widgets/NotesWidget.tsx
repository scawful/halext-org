import { useState, useEffect } from 'react'
import type { LayoutWidget } from '../../types/models'
import './Widget.css'

type NotesWidgetProps = {
  widget: LayoutWidget
  onUpdate: (widget: LayoutWidget) => void
}

export const NotesWidget = ({ widget, onUpdate }: NotesWidgetProps) => {
  const [notesContent, setNotesContent] = useState<string>(
    () => (widget.config?.content as string) ?? ''
  )

  useEffect(() => {
    setNotesContent((widget.config?.content as string) ?? '')
  }, [widget.config?.content])

  const persistNotes = () => {
    const updated = {
      ...widget,
      config: { ...widget.config, content: notesContent },
    }
    onUpdate(updated)
  }

  return (
    <div className="widget-body notes-widget">
      <textarea
        value={notesContent}
        onChange={(e) => setNotesContent(e.target.value)}
        onBlur={persistNotes}
        placeholder="Capture lightweight notes or a micro agenda..."
      />
      <span className="muted">Changes save automatically when you leave the field.</span>
    </div>
  )
}
