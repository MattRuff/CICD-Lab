import json
import os
from kafka import KafkaConsumer
import psycopg2
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

load_dotenv()

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'postgres'),
        port=int(os.getenv('DB_PORT', '5432')),
        database=os.getenv('DB_NAME', 'taskdb'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres')
    )

# Kafka consumer
def create_consumer():
    return KafkaConsumer(
        'task-events',
        bootstrap_servers=[os.getenv('KAFKA_BROKER', 'kafka:9092')],
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        group_id='task-consumer-group',
        value_deserializer=lambda x: json.loads(x.decode('utf-8'))
    )

def process_task_event(event_data, db_conn):
    """Process task events and log them to a separate audit table"""
    cursor = db_conn.cursor()
    
    try:
        # Create audit log table if it doesn't exist
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS task_audit_log (
                id SERIAL PRIMARY KEY,
                event_type VARCHAR(50) NOT NULL,
                task_id INTEGER,
                event_data JSONB NOT NULL,
                processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        event_type = event_data.get('event', 'unknown')
        task_data = event_data.get('task', {})
        task_id = task_data.get('id') if task_data else event_data.get('taskId')
        
        # Insert audit log
        cursor.execute(
            """
            INSERT INTO task_audit_log (event_type, task_id, event_data)
            VALUES (%s, %s, %s)
            """,
            (event_type, task_id, json.dumps(event_data))
        )
        
        db_conn.commit()
        logger.info(f"Processed event: {event_type} for task ID: {task_id}")
        
    except Exception as e:
        logger.error(f"Error processing event: {e}")
        db_conn.rollback()
    finally:
        cursor.close()

def main():
    logger.info("Starting Kafka consumer...")
    
    # Wait for Kafka to be ready
    import time
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            consumer = create_consumer()
            break
        except Exception as e:
            retry_count += 1
            logger.warning(f"Waiting for Kafka... attempt {retry_count}/{max_retries}")
            time.sleep(2)
    
    if retry_count >= max_retries:
        logger.error("Failed to connect to Kafka after maximum retries")
        return
    
    db_conn = get_db_connection()
    
    logger.info("Consumer ready, waiting for messages...")
    
    try:
        for message in consumer:
            event_data = message.value
            logger.info(f"Received message: {event_data}")
            process_task_event(event_data, db_conn)
    except KeyboardInterrupt:
        logger.info("Shutting down consumer...")
    finally:
        consumer.close()
        db_conn.close()

if __name__ == '__main__':
    main()

