import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { MdDragIndicator } from 'react-icons/md'
import './DraggableWidget.css'

type DraggableWidgetProps = {
  id: string
  children: React.ReactNode
  title: string
  onRemove?: () => void
}

export const DraggableWidget = ({ id, children, title, onRemove }: DraggableWidgetProps) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  }

  return (
    <div ref={setNodeRef} style={style} className="draggable-widget">
      <div className="widget-header">
        <div className="widget-drag-handle" {...attributes} {...listeners}>
          <MdDragIndicator size={20} />
        </div>
        <h4>{title}</h4>
        {onRemove && (
          <button type="button" className="widget-remove" onClick={onRemove}>
            ×
          </button>
        )}
      </div>
      <div className="widget-content">
        {children}
      </div>
    </div>
  )
}
