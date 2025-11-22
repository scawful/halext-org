#!/bin/bash
# Test script for new budget progress endpoints
# Run this after the halext-api service has been restarted

API_URL="https://org.halext.org/api"
TOKEN=""  # Set this to a valid auth token

echo "====================================="
echo "Testing Budget Progress Endpoints"
echo "====================================="
echo ""

# Function to make authenticated requests
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3

    echo "Testing: $method $endpoint"

    if [ -z "$TOKEN" ]; then
        echo "⚠️  No token set - request will likely fail with 401"
        curl -X "$method" \
             "$API_URL$endpoint" \
             -H "Accept: application/json" \
             ${data:+-H "Content-Type: application/json"} \
             ${data:+-d "$data"} \
             -w "\nHTTP Status: %{http_code}\n\n" \
             2>/dev/null | python3 -m json.tool 2>/dev/null || echo "Response parsing failed"
    else
        curl -X "$method" \
             "$API_URL$endpoint" \
             -H "Authorization: Bearer $TOKEN" \
             -H "Accept: application/json" \
             ${data:+-H "Content-Type: application/json"} \
             ${data:+-d "$data"} \
             -w "\nHTTP Status: %{http_code}\n\n" \
             2>/dev/null | python3 -m json.tool 2>/dev/null || echo "Response parsing failed"
    fi

    echo "-------------------------------------"
    echo ""
}

# 1. Test GET all budget progress
echo "1. Get all budget progress"
make_request "GET" "/finance/budgets/progress"

# 2. Test GET budget progress summary
echo "2. Get budget progress summary"
make_request "GET" "/finance/budgets/progress/summary"

# 3. Test sync all budgets (requires a budget to exist)
echo "3. Sync all budgets"
make_request "POST" "/finance/budgets/sync-all"

# If you know a specific budget ID, uncomment and set it here:
# BUDGET_ID="your-budget-id-here"
#
# echo "4. Get specific budget progress"
# make_request "GET" "/finance/budgets/$BUDGET_ID/progress"
#
# echo "5. Sync specific budget"
# make_request "POST" "/finance/budgets/$BUDGET_ID/sync"

echo ""
echo "====================================="
echo "Test Complete"
echo "====================================="
echo ""
echo "Note: To test authenticated endpoints, you need to:"
echo "1. Get an auth token:"
echo "   curl -X POST '$API_URL/token' \\"
echo "     -H 'Content-Type: application/x-www-form-urlencoded' \\"
echo "     -d 'username=YOUR_USER&password=YOUR_PASS'"
echo ""
echo "2. Set the TOKEN variable in this script with the returned access_token"
echo ""