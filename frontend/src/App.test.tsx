import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders the main heading', () => {
    render(<App />);
    const heading = screen.getByText(/Task Manager/i);
    expect(heading).toBeDefined();
  });

  it('renders the task form', () => {
    render(<App />);
    const titleInput = screen.getByPlaceholderText(/Task title/i);
    const descInput = screen.getByPlaceholderText(/Description/i);
    expect(titleInput).toBeDefined();
    expect(descInput).toBeDefined();
  });

  it('renders add task button', () => {
    render(<App />);
    // Button text changes based on loading state: "Add Task" or "Adding..."
    const addButton = screen.getByRole('button', { name: /add task|adding/i });
    expect(addButton).toBeDefined();
  });
});

