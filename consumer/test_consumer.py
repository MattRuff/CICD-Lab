import pytest
import json
from consumer import process_task_event
from unittest.mock import Mock, MagicMock

def test_process_task_event():
    """Test that task events are processed correctly"""
    # Mock database connection and cursor
    mock_conn = Mock()
    mock_cursor = MagicMock()
    mock_conn.cursor.return_value = mock_cursor
    
    event_data = {
        'event': 'task.created',
        'task': {
            'id': 1,
            'title': 'Test Task',
            'description': 'Test Description'
        },
        'timestamp': '2024-01-01T00:00:00Z'
    }
    
    # Process the event
    process_task_event(event_data, mock_conn)
    
    # Verify that execute was called twice (CREATE TABLE and INSERT)
    assert mock_cursor.execute.call_count == 2
    assert mock_conn.commit.called
    mock_cursor.close.assert_called_once()

def test_process_task_event_error_handling():
    """Test that errors are handled gracefully"""
    mock_conn = Mock()
    mock_cursor = MagicMock()
    mock_cursor.execute.side_effect = Exception("Database error")
    mock_conn.cursor.return_value = mock_cursor
    
    event_data = {
        'event': 'task.created',
        'task': {'id': 1}
    }
    
    # Should not raise exception
    process_task_event(event_data, mock_conn)
    
    # Verify rollback was called
    mock_conn.rollback.assert_called_once()

