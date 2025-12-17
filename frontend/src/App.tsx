import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

interface Task {
  id: number;
  title: string;
  description: string;
  status: string;
  created_at: string;
  updated_at: string;
}

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [newTask, setNewTask] = useState({ title: '', description: '' });
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await axios.get(`${API_URL}/api/tasks`);
      setTasks(response.data);
    } catch (err) {
      setError('Failed to fetch tasks');
      console.error('Error fetching tasks:', err);
    } finally {
      setLoading(false);
    }
  };

  const createTask = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTask.title.trim()) return;

    try {
      setLoading(true);
      setError(null);
      await axios.post(`${API_URL}/api/tasks`, newTask);
      setNewTask({ title: '', description: '' });
      await fetchTasks();
    } catch (err) {
      setError('Failed to create task');
      console.error('Error creating task:', err);
    } finally {
      setLoading(false);
    }
  };

  const updateTask = async (task: Task) => {
    try {
      setLoading(true);
      setError(null);
      await axios.put(`${API_URL}/api/tasks/${task.id}`, task);
      setEditingTask(null);
      await fetchTasks();
    } catch (err) {
      setError('Failed to update task');
      console.error('Error updating task:', err);
    } finally {
      setLoading(false);
    }
  };

  const deleteTask = async (id: number) => {
    if (!window.confirm('Are you sure you want to delete this task?')) return;

    try {
      setLoading(true);
      setError(null);
      await axios.delete(`${API_URL}/api/tasks/${id}`);
      await fetchTasks();
    } catch (err) {
      setError('Failed to delete task');
      console.error('Error deleting task:', err);
    } finally {
      setLoading(false);
    }
  };

  const toggleStatus = async (task: Task) => {
    const newStatus = task.status === 'pending' ? 'completed' : 'pending';
    await updateTask({ ...task, status: newStatus });
  };

  return (
    <div className="app">
      <div className="container">
        <h1>Task Manager</h1>
        
        {error && <div className="error">{error}</div>}

        <form onSubmit={createTask} className="task-form">
          <input
            type="text"
            placeholder="Task title"
            value={newTask.title}
            onChange={(e) => setNewTask({ ...newTask, title: e.target.value })}
            disabled={loading}
          />
          <input
            type="text"
            placeholder="Description"
            value={newTask.description}
            onChange={(e) => setNewTask({ ...newTask, description: e.target.value })}
            disabled={loading}
          />
          <button type="submit" disabled={loading}>
            {loading ? 'Adding...' : 'Add Task'}
          </button>
        </form>

        <div className="task-list">
          {tasks.length === 0 && !loading && (
            <p className="empty-state">No tasks yet. Create one above!</p>
          )}
          
          {tasks.map((task) => (
            <div key={task.id} className={`task-item ${task.status}`}>
              {editingTask?.id === task.id ? (
                <div className="edit-form">
                  <input
                    type="text"
                    value={editingTask.title}
                    onChange={(e) =>
                      setEditingTask({ ...editingTask, title: e.target.value })
                    }
                  />
                  <input
                    type="text"
                    value={editingTask.description}
                    onChange={(e) =>
                      setEditingTask({ ...editingTask, description: e.target.value })
                    }
                  />
                  <select
                    value={editingTask.status}
                    onChange={(e) =>
                      setEditingTask({ ...editingTask, status: e.target.value })
                    }
                  >
                    <option value="pending">Pending</option>
                    <option value="completed">Completed</option>
                  </select>
                  <button onClick={() => updateTask(editingTask)}>Save</button>
                  <button onClick={() => setEditingTask(null)}>Cancel</button>
                </div>
              ) : (
                <>
                  <div className="task-content">
                    <h3>{task.title}</h3>
                    <p>{task.description}</p>
                    <span className="status-badge">{task.status}</span>
                  </div>
                  <div className="task-actions">
                    <button onClick={() => toggleStatus(task)} disabled={loading}>
                      {task.status === 'pending' ? '✓ Complete' : '↺ Reopen'}
                    </button>
                    <button onClick={() => setEditingTask(task)} disabled={loading}>
                      Edit
                    </button>
                    <button
                      onClick={() => deleteTask(task.id)}
                      className="delete-btn"
                      disabled={loading}
                    >
                      Delete
                    </button>
                  </div>
                </>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default App;

