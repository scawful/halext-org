import type { EventItem } from '../../types/models'
import './Section.css'

type CalendarSectionProps = {
  events: EventItem[]
}

export const CalendarSection = ({ events }: CalendarSectionProps) => {
  const groupEventsByDate = () => {
    const grouped: Record<string, EventItem[]> = {}

    events.forEach((event) => {
      const date = new Date(event.start_time).toLocaleDateString()
      if (!grouped[date]) {
        grouped[date] = []
      }
      grouped[date].push(event)
    })

    return grouped
  }

  const groupedEvents = groupEventsByDate()
  const dates = Object.keys(groupedEvents).sort()

  return (
    <div className="section-container">
      <div className="section-header">
        <h2>Calendar</h2>
        <p className="muted">View and manage your events</p>
      </div>

      <div className="calendar-view">
        {dates.length === 0 && (
          <div className="empty-state">
            <p className="muted">No events scheduled. Create one from the sidebar!</p>
          </div>
        )}

        {dates.map((date) => (
          <div key={date} className="calendar-day-group">
            <h3 className="calendar-date">{date}</h3>
            <div className="events-list">
              {groupedEvents[date].map((event) => (
                <div key={event.id} className="event-card">
                  <div className="event-time">
                    {new Date(event.start_time).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </div>
                  <div className="event-details">
                    <h4>{event.title}</h4>
                    {event.description && <p className="muted">{event.description}</p>}
                    {event.location && (
                      <p className="event-location">📍 {event.location}</p>
                    )}
                    {event.recurrence_type !== 'none' && (
                      <span className="recurrence-badge">
                        Repeats {event.recurrence_type}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
