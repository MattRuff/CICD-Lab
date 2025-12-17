#!/bin/bash

echo "🧪 Running Local Test Suite"
echo "============================"
echo ""

FAILED=0
TEST_RESULTS=""

# Test Backend
echo "📦 Testing Backend..."
echo "--------------------"
cd backend
if npm install --silent 2>&1 | grep -q "error"; then
    echo "❌ Backend npm install failed"
    FAILED=1
    TEST_RESULTS="$TEST_RESULTS\n❌ Backend: npm install failed"
else
    if npm run build 2>&1 | grep -q "error"; then
        echo "❌ Backend build failed"
        FAILED=1
        TEST_RESULTS="$TEST_RESULTS\n❌ Backend: build failed"
    else
        if npm test 2>&1 | tee /tmp/backend-test.log | grep -q "FAIL"; then
            echo "❌ Backend tests failed"
            FAILED=1
            TEST_RESULTS="$TEST_RESULTS\n❌ Backend: tests failed"
            cat /tmp/backend-test.log
        else
            echo "✅ Backend tests passed"
            TEST_RESULTS="$TEST_RESULTS\n✅ Backend: All tests passed"
        fi
    fi
fi
cd ..
echo ""

# Test Consumer
echo "🐍 Testing Consumer..."
echo "---------------------"
cd consumer
if pip install -q -r requirements.txt 2>&1 | grep -q "error"; then
    echo "❌ Consumer pip install failed"
    FAILED=1
    TEST_RESULTS="$TEST_RESULTS\n❌ Consumer: pip install failed"
else
    if pytest test_consumer.py -v 2>&1 | tee /tmp/consumer-test.log | grep -q "FAILED"; then
        echo "❌ Consumer tests failed"
        FAILED=1
        TEST_RESULTS="$TEST_RESULTS\n❌ Consumer: tests failed"
        cat /tmp/consumer-test.log
    else
        echo "✅ Consumer tests passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ Consumer: All tests passed"
    fi
fi
cd ..
echo ""

# Test Frontend
echo "⚛️  Testing Frontend..."
echo "----------------------"
cd frontend
if npm install --silent 2>&1 | grep -q "error"; then
    echo "❌ Frontend npm install failed"
    FAILED=1
    TEST_RESULTS="$TEST_RESULTS\n❌ Frontend: npm install failed"
else
    if npm run build 2>&1 | tee /tmp/frontend-build.log | grep -q "error"; then
        echo "❌ Frontend build failed"
        FAILED=1
        TEST_RESULTS="$TEST_RESULTS\n❌ Frontend: build failed"
        cat /tmp/frontend-build.log
    else
        if npm test 2>&1 | tee /tmp/frontend-test.log | grep -q "FAIL"; then
            echo "❌ Frontend tests failed"
            FAILED=1
            TEST_RESULTS="$TEST_RESULTS\n❌ Frontend: tests failed"
            cat /tmp/frontend-test.log
        else
            echo "✅ Frontend tests passed"
            TEST_RESULTS="$TEST_RESULTS\n✅ Frontend: All tests passed"
        fi
    fi
fi
cd ..
echo ""

# Summary
echo "================================"
echo "📊 Test Summary"
echo "================================"
echo -e "$TEST_RESULTS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi

