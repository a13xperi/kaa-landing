#!/bin/bash
# Stripe Edge Case Test Script
# Tests error handling and edge cases

set -e

# Configuration
API_URL=${API_URL:-"http://localhost:3001"}
AUTH_TOKEN=${AUTH_TOKEN:-""}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "========================================="
echo "  Stripe Edge Case Tests"
echo "========================================="
echo ""
echo "API URL: $API_URL"
echo ""

# Helper function for API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ -n "$AUTH_TOKEN" ]; then
        AUTH_HEADER="Authorization: Bearer $AUTH_TOKEN"
    else
        AUTH_HEADER=""
    fi

    if [ "$method" == "GET" ]; then
        curl -s -X GET "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            ${AUTH_HEADER:+-H "$AUTH_HEADER"}
    else
        curl -s -X "$method" "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
            -d "$data"
    fi
}

PASS=0
FAIL=0

test_case() {
    local name=$1
    local expected=$2
    local actual=$3

    if [ "$expected" == "$actual" ]; then
        echo -e "${GREEN}✓ $name${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗ $name${NC}"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((FAIL++))
    fi
}

# ==========================================
# Edge Case 1: Non-existent Lead
# ==========================================
echo -e "${BLUE}Edge Case 1: Create session with non-existent lead${NC}"

RESPONSE=$(api_call POST "/api/checkout/create-session" '{
    "leadId": "non-existent-lead-12345",
    "tier": 1,
    "successUrl": "http://localhost:3000/success",
    "cancelUrl": "http://localhost:3000/cancel"
}')

HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Non-existent lead returns error" "yes" "$HAS_ERROR"
echo ""

# ==========================================
# Edge Case 2: Already Converted Lead
# ==========================================
echo -e "${BLUE}Edge Case 2: Create session for already converted lead${NC}"
echo "(Requires a converted lead ID - set CONVERTED_LEAD_ID env var)"

CONVERTED_LEAD_ID=${CONVERTED_LEAD_ID:-""}
if [ -n "$CONVERTED_LEAD_ID" ]; then
    RESPONSE=$(api_call POST "/api/checkout/create-session" "{
        \"leadId\": \"$CONVERTED_LEAD_ID\",
        \"tier\": 1,
        \"successUrl\": \"http://localhost:3000/success\",
        \"cancelUrl\": \"http://localhost:3000/cancel\"
    }")

    ERROR_CODE=$(echo "$RESPONSE" | jq -r '.code // .error // "none"')
    if [[ "$ERROR_CODE" == *"ALREADY_CONVERTED"* ]] || [[ "$ERROR_CODE" == *"already"* ]]; then
        test_case "Already converted lead rejected" "pass" "pass"
    else
        test_case "Already converted lead rejected" "ALREADY_CONVERTED" "$ERROR_CODE"
    fi
else
    echo -e "${YELLOW}! Skipped - set CONVERTED_LEAD_ID to test${NC}"
fi
echo ""

# ==========================================
# Edge Case 3: Invalid Tier Values
# ==========================================
echo -e "${BLUE}Edge Case 3: Invalid tier values${NC}"

# Tier 0
RESPONSE=$(api_call POST "/api/checkout/create-session" '{
    "leadId": "test-lead",
    "tier": 0,
    "successUrl": "http://localhost:3000/success",
    "cancelUrl": "http://localhost:3000/cancel"
}')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Tier 0 rejected" "yes" "$HAS_ERROR"

# Tier -1
RESPONSE=$(api_call POST "/api/checkout/create-session" '{
    "leadId": "test-lead",
    "tier": -1,
    "successUrl": "http://localhost:3000/success",
    "cancelUrl": "http://localhost:3000/cancel"
}')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Tier -1 rejected" "yes" "$HAS_ERROR"

# Tier 5
RESPONSE=$(api_call POST "/api/checkout/create-session" '{
    "leadId": "test-lead",
    "tier": 5,
    "successUrl": "http://localhost:3000/success",
    "cancelUrl": "http://localhost:3000/cancel"
}')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Tier 5 rejected" "yes" "$HAS_ERROR"

# Tier as string
RESPONSE=$(api_call POST "/api/checkout/create-session" '{
    "leadId": "test-lead",
    "tier": "one",
    "successUrl": "http://localhost:3000/success",
    "cancelUrl": "http://localhost:3000/cancel"
}')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Tier as string rejected" "yes" "$HAS_ERROR"
echo ""

# ==========================================
# Edge Case 4: Missing Required Fields
# ==========================================
echo -e "${BLUE}Edge Case 4: Missing required fields${NC}"

# Missing leadId
RESPONSE=$(api_call POST "/api/checkout/create-session" '{
    "tier": 1,
    "successUrl": "http://localhost:3000/success",
    "cancelUrl": "http://localhost:3000/cancel"
}')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Missing leadId rejected" "yes" "$HAS_ERROR"

# Missing tier
RESPONSE=$(api_call POST "/api/checkout/create-session" '{
    "leadId": "test-lead",
    "successUrl": "http://localhost:3000/success",
    "cancelUrl": "http://localhost:3000/cancel"
}')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Missing tier rejected" "yes" "$HAS_ERROR"

# Empty body
RESPONSE=$(api_call POST "/api/checkout/create-session" '{}')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Empty body rejected" "yes" "$HAS_ERROR"
echo ""

# ==========================================
# Edge Case 5: Invalid Session ID
# ==========================================
echo -e "${BLUE}Edge Case 5: Invalid session ID${NC}"

RESPONSE=$(api_call GET "/api/checkout/session/invalid-session-id-12345")
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Invalid session ID returns error" "yes" "$HAS_ERROR"
echo ""

# ==========================================
# Edge Case 6: Non-existent Subscription
# ==========================================
echo -e "${BLUE}Edge Case 6: Non-existent subscription${NC}"

RESPONSE=$(api_call GET "/api/subscriptions/non-existent-client-12345")
# This might return 404 or empty subscription - both are valid
HTTP_CODE=$(echo "$RESPONSE" | jq -r '.statusCode // .status // "200"')
HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
HAS_NULL=$(echo "$RESPONSE" | jq -e '.subscription == null' 2>/dev/null && echo "yes" || echo "no")

if [ "$HAS_ERROR" == "yes" ] || [ "$HAS_NULL" == "yes" ]; then
    test_case "Non-existent subscription handled gracefully" "pass" "pass"
else
    test_case "Non-existent subscription handled gracefully" "error or null" "unexpected response"
fi
echo ""

# ==========================================
# Edge Case 7: Webhook Signature Validation
# ==========================================
echo -e "${BLUE}Edge Case 7: Invalid webhook signature${NC}"

# Send webhook without signature
RESPONSE=$(curl -s -X POST "$API_URL/api/webhooks/stripe" \
    -H "Content-Type: application/json" \
    -d '{"type": "fake.event", "data": {}}')

HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Webhook without signature rejected" "yes" "$HAS_ERROR"

# Send webhook with invalid signature
RESPONSE=$(curl -s -X POST "$API_URL/api/webhooks/stripe" \
    -H "Content-Type: application/json" \
    -H "Stripe-Signature: invalid_signature" \
    -d '{"type": "fake.event", "data": {}}')

HAS_ERROR=$(echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1 && echo "yes" || echo "no")
test_case "Webhook with invalid signature rejected" "yes" "$HAS_ERROR"
echo ""

# ==========================================
# Edge Case 8: Rate Limiting (if implemented)
# ==========================================
echo -e "${BLUE}Edge Case 8: Rate limiting check${NC}"

echo "Sending 20 rapid requests to pricing endpoint..."
SUCCESS_COUNT=0
RATE_LIMITED=0

for i in {1..20}; do
    RESPONSE=$(api_call GET "/api/checkout/pricing")
    if echo "$RESPONSE" | jq -e '.tiers' > /dev/null 2>&1; then
        ((SUCCESS_COUNT++))
    elif echo "$RESPONSE" | jq -e '.error' | grep -qi "rate" 2>/dev/null; then
        ((RATE_LIMITED++))
    fi
done

echo "  Successful: $SUCCESS_COUNT"
echo "  Rate limited: $RATE_LIMITED"

if [ $RATE_LIMITED -gt 0 ]; then
    echo -e "${GREEN}✓ Rate limiting is active${NC}"
else
    echo -e "${YELLOW}! Rate limiting may not be configured (all requests succeeded)${NC}"
fi
echo ""

# ==========================================
# Summary
# ==========================================
echo "========================================="
echo "  Edge Case Tests Complete"
echo "========================================="
echo ""
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Some edge cases are not handled correctly.${NC}"
    echo "Review the failed tests and update error handling."
    exit 1
else
    echo -e "${GREEN}All edge cases handled correctly!${NC}"
    exit 0
fi
