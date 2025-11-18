import type { EventItem } from '../../types/models'
import './Widget.css'

type EventsWidgetProps = {
  events: EventItem[]
}

export const EventsWidget = ({ events }: EventsWidgetProps) => {
  return (
    <div className="widget-body">
      <ul className="widget-list">
        {events.length === 0 && <li className="muted">No events scheduled</li>}
        {events.slice(0, 5).map((event) => (
          <li key={event.id}>
            <strong>{event.title}</strong>
            <span className="muted">
              {' · '}
              {new Date(event.start_time).toLocaleString()} –{' '}
              {new Date(event.end_time).toLocaleTimeString()}
            </span>
          </li>
        ))}
      </ul>
    </div>
  )
}
