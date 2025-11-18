import type { Task } from '../../types/models'
import './Widget.css'

type TasksWidgetProps = {
  tasks: Task[]
}

export const TasksWidget = ({ tasks }: TasksWidgetProps) => {
  return (
    <div className="widget-body">
      <ul className="widget-list">
        {tasks.length === 0 && <li className="muted">No tasks yet</li>}
        {tasks.slice(0, 5).map((task) => (
          <li key={task.id}>
            <strong>{task.title}</strong>
            {task.due_date && (
              <span className="muted">
                {' · Due '}
                {new Date(task.due_date).toLocaleDateString()}
              </span>
            )}
            {task.labels && task.labels.length > 0 && (
              <div className="label-chip-row">
                {task.labels.map((label) => (
                  <span
                    key={`${task.id}-${label.id}`}
                    className="label-chip"
                    style={{ borderColor: label.color }}
                  >
                    {label.name}
                  </span>
                ))}
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}
