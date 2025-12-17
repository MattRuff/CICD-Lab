#!/bin/bash

echo "🧪 Running All Tests"
echo "===================="
echo ""

FAILED=0

# Test Backend
echo "📦 Testing Backend..."
cd backend
if npm ci > /dev/null 2>&1 && npm run build > /dev/null 2>&1 && npm test; then
    echo "✅ Backend tests passed"
else
    echo "❌ Backend tests failed"
    FAILED=1
fi
cd ..
echo ""

# Test Consumer
echo "🐍 Testing Consumer..."
cd consumer
if pip install -r requirements.txt > /dev/null 2>&1 && pytest test_consumer.py -v; then
    echo "✅ Consumer tests passed"
else
    echo "❌ Consumer tests failed"
    FAILED=1
fi
cd ..
echo ""

# Test Frontend
echo "⚛️  Testing Frontend..."
cd frontend
if npm ci > /dev/null 2>&1 && npm run build > /dev/null 2>&1 && npm test; then
    echo "✅ Frontend tests passed"
else
    echo "❌ Frontend tests failed"
    FAILED=1
fi
cd ..
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi

