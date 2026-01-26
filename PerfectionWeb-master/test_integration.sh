#!/bin/bash
# Test Script for PerfectionWeb Backend & Frontend Integration
# Run this after deployment to verify all endpoints are working

echo "=========================================="
echo "PerfectionWeb System Integration Test"
echo "=========================================="
echo ""

BASE_URL="http://localhost:5000/api"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to test endpoints
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    local description=$5
    
    echo -n "Testing: $description ... "
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL$endpoint")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}PASS${NC} (HTTP $status_code)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC} (Expected $expected_status, got $status_code)"
        echo "Response: $body"
        ((TESTS_FAILED++))
    fi
}

echo "=== Authentication Tests ==="
echo ""

# Test Parent Login
test_endpoint "POST" "/auth/login" \
    '{"phone_number": "01012345678", "password": "test123"}' \
    "200" \
    "Parent Login"

echo ""

# Test Change Password
test_endpoint "POST" "/auth/change-password" \
    '{"phone_number": "01012345678", "current_password": "test123", "new_password": "newtest123"}' \
    "200" \
    "Parent Change Password"

echo ""

# Test Admin Login
test_endpoint "POST" "/admin/login" \
    '{"username": "admin", "password": "admin123"}' \
    "200" \
    "Admin Login"

echo ""

# Test Admin Change Password
test_endpoint "POST" "/admin/change-password" \
    '{"username": "admin", "current_password": "admin123", "new_password": "newadmin123"}' \
    "200" \
    "Admin Change Password"

echo ""
echo "=== Data Retrieval Tests ==="
echo ""

# Test Get Groups
test_endpoint "GET" "/groups" \
    "" \
    "200" \
    "Get Available Groups"

echo ""

# Test Get Sessions
test_endpoint "GET" "/sessions" \
    "" \
    "200" \
    "Get Available Sessions"

echo ""

# Test Get Parent Sessions
test_endpoint "GET" "/parent/sessions?phone_number=01012345678" \
    "" \
    "200" \
    "Get Parent Sessions (with filtering)"

echo ""
echo "=== Upload Tests ==="
echo ""

# Note: Upload test requires an actual Excel file
# This is a placeholder - uncomment and modify if you have a test file
# test_endpoint "POST" "/upload-excel" \
#     "-F 'file=@test_students.xlsx' -F 'session_number=1' -F 'group=cam1' -F 'is_general_exam=false' -F 'lecture_name=Test Lecture' -F 'has_exam_grade=true' -F 'has_payment=true' -F 'has_time=true'" \
#     "200" \
#     "Upload Excel File with Lecture Metadata"

echo "⚠️  Excel upload test requires actual file - skipped (add test file to verify)"

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Check output above.${NC}"
    exit 1
fi
