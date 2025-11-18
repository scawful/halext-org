import { TasksSection } from './sections/TasksSection';
import type { Task, Label } from '../../types/models';
import './TasksPage.css';

interface TasksPageProps {
  token: string;
  tasks: Task[];
  availableLabels: Label[];
  onCreateTask: (task: {
    title: string;
    description?: string;
    due_date?: string;
    labels: string[];
  }) => Promise<void>;
  onUpdateTask: (id: number, updates: Partial<Task> & { labels?: string[] }) => Promise<void>;
  onDeleteTask: (id: number) => Promise<void>;
}

export const TasksPage = (props: TasksPageProps) => {
  return (
    <div className="tasks-page">
      <TasksSection {...props} />
    </div>
  );
};
