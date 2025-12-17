// Set test environment before any imports
process.env.NODE_ENV = 'test';
// Silence Kafka partitioner warning in tests
process.env.KAFKAJS_NO_PARTITIONER_WARNING = '1';

