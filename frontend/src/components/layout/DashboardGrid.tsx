import { DndContext, closestCenter, PointerSensor, useSensor, useSensors } from '@dnd-kit/core'
import type { DragEndEvent } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy, arrayMove } from '@dnd-kit/sortable'
import { DraggableWidget } from '../widgets/DraggableWidget'
import { TasksWidget } from '../widgets/TasksWidget'
import { EventsWidget } from '../widgets/EventsWidget'
import { NotesWidget } from '../widgets/NotesWidget'
import { GiftListWidget } from '../widgets/GiftListWidget'
import { OpenWebUIWidget } from '../widgets/OpenWebUIWidget'
import type { LayoutColumn, LayoutWidget, Task, EventItem, OpenWebUiStatus } from '../../types/models'
import './DashboardGrid.css'

type DashboardGridProps = {
  columns: LayoutColumn[]
  tasks: Task[]
  events: EventItem[]
  openwebui: OpenWebUiStatus | null
  token: string
  onUpdateColumn: (columnId: string, widgets: LayoutWidget[]) => void
  onUpdateWidget: (columnId: string, widget: LayoutWidget) => void
  onRemoveWidget: (columnId: string, widgetId: string) => void
  onAddWidget: (columnId: string, type: string) => void
  onAddColumn: () => void
  onRemoveColumn: (columnId: string) => void
  onUpdateColumnTitle: (columnId: string, title: string) => void
}

export const DashboardGrid = ({
  columns,
  tasks,
  events,
  openwebui,
  token,
  onUpdateColumn,
  onUpdateWidget,
  onRemoveWidget,
  onAddWidget,
  onAddColumn,
  onRemoveColumn,
  onUpdateColumnTitle,
}: DashboardGridProps) => {
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  )

  const handleDragEnd = (event: DragEndEvent, columnId: string) => {
    const { active, over } = event

    if (!over || active.id === over.id) return

    const column = columns.find((col) => col.id === columnId)
    if (!column) return

    const oldIndex = column.widgets.findIndex((w) => w.id === active.id)
    const newIndex = column.widgets.findIndex((w) => w.id === over.id)

    if (oldIndex !== -1 && newIndex !== -1) {
      const newWidgets = arrayMove(column.widgets, oldIndex, newIndex)
      onUpdateColumn(columnId, newWidgets)
    }
  }

  const renderWidgetContent = (widget: LayoutWidget, columnId: string) => {
    switch (widget.type) {
      case 'tasks':
        return <TasksWidget tasks={tasks} />
      case 'events':
        return <EventsWidget events={events} />
      case 'notes':
        return (
          <NotesWidget
            widget={widget}
            onUpdate={(updated) => onUpdateWidget(columnId, updated)}
          />
        )
      case 'gift-list':
        return (
          <GiftListWidget
            widget={widget}
            onUpdate={(updated) => onUpdateWidget(columnId, updated)}
          />
        )
      case 'openwebui':
        return <OpenWebUIWidget openwebui={openwebui} token={token} />
      default:
        return <div className="muted">Widget not configured.</div>
    }
  }

  return (
    <div className="dashboard-grid">
      {columns.map((column) => (
        <div key={column.id} className="dashboard-column">
          <div className="column-header">
            <input
              value={column.title}
              onChange={(e) => onUpdateColumnTitle(column.id, e.target.value)}
              className="column-title-input"
            />
            <button
              type="button"
              className="column-remove"
              onClick={() => onRemoveColumn(column.id)}
            >
              Remove column
            </button>
          </div>

          <DndContext
            sensors={sensors}
            collisionDetection={closestCenter}
            onDragEnd={(event) => handleDragEnd(event, column.id)}
          >
            <SortableContext
              items={column.widgets.map((w) => w.id)}
              strategy={verticalListSortingStrategy}
            >
              <div className="widgets-container">
                {column.widgets.map((widget) => (
                  <DraggableWidget
                    key={widget.id}
                    id={widget.id}
                    title={widget.title}
                    onRemove={() => onRemoveWidget(column.id, widget.id)}
                  >
                    {renderWidgetContent(widget, column.id)}
                  </DraggableWidget>
                ))}
              </div>
            </SortableContext>
          </DndContext>

          <div className="add-widget-section">
            <select
              onChange={(e) => {
                if (e.target.value) {
                  onAddWidget(column.id, e.target.value)
                  e.target.value = ''
                }
              }}
              className="add-widget-select"
              defaultValue=""
            >
              <option value="" disabled>
                + Add widget
              </option>
              <option value="tasks">Tasks</option>
              <option value="events">Events</option>
              <option value="notes">Notes</option>
              <option value="gift-list">Gift List</option>
              <option value="openwebui">OpenWebUI</option>
            </select>
          </div>
        </div>
      ))}

      <button className="add-column-btn" onClick={onAddColumn}>
        + Add column
      </button>
    </div>
  )
}
