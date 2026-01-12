#!/bin/bash
# Stripe Checkout Flow Test Script
# Tests the complete checkout flow from session creation to verification

set -e

# Configuration
API_URL=${API_URL:-"http://localhost:3001"}
AUTH_TOKEN=${AUTH_TOKEN:-""}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================="
echo "  Stripe Checkout Flow Tests"
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

# Test 1: Get Pricing Information
echo -e "${BLUE}Test 1: Get Pricing Information${NC}"
echo "GET /api/checkout/pricing"
echo ""

PRICING_RESPONSE=$(api_call GET "/api/checkout/pricing")
echo "$PRICING_RESPONSE" | jq . 2>/dev/null || echo "$PRICING_RESPONSE"

if echo "$PRICING_RESPONSE" | jq -e '.tiers' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Pricing endpoint working${NC}"
    TIER_COUNT=$(echo "$PRICING_RESPONSE" | jq '.tiers | length')
    echo "  Found $TIER_COUNT tiers"
else
    echo -e "${RED}✗ Pricing endpoint failed${NC}"
fi
echo ""

# Test 2: Create Checkout Session (Tier 1)
echo -e "${BLUE}Test 2: Create Checkout Session - Tier 1 (Seedling)${NC}"
echo "POST /api/checkout/create-session"
echo ""

# You'll need a valid lead ID from your database
LEAD_ID=${TEST_LEAD_ID:-"test-lead-id"}

CREATE_SESSION_DATA=$(cat <<EOF
{
    "leadId": "$LEAD_ID",
    "tier": 1,
    "successUrl": "http://localhost:3000/checkout/success",
    "cancelUrl": "http://localhost:3000/checkout/cancel"
}
EOF
)

echo "Request body:"
echo "$CREATE_SESSION_DATA" | jq .
echo ""

SESSION_RESPONSE=$(api_call POST "/api/checkout/create-session" "$CREATE_SESSION_DATA")
echo "Response:"
echo "$SESSION_RESPONSE" | jq . 2>/dev/null || echo "$SESSION_RESPONSE"

if echo "$SESSION_RESPONSE" | jq -e '.sessionId' > /dev/null 2>&1; then
    SESSION_ID=$(echo "$SESSION_RESPONSE" | jq -r '.sessionId')
    CHECKOUT_URL=$(echo "$SESSION_RESPONSE" | jq -r '.url // .checkoutUrl')
    echo -e "${GREEN}✓ Checkout session created${NC}"
    echo "  Session ID: $SESSION_ID"
    echo "  Checkout URL: $CHECKOUT_URL"

    # Save for later tests
    echo "$SESSION_ID" > /tmp/stripe_test_session_id
else
    echo -e "${RED}✗ Failed to create checkout session${NC}"
    if echo "$SESSION_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
        ERROR=$(echo "$SESSION_RESPONSE" | jq -r '.error')
        echo "  Error: $ERROR"
    fi
fi
echo ""

# Test 3: Verify Session Status
echo -e "${BLUE}Test 3: Verify Session Status${NC}"

if [ -f /tmp/stripe_test_session_id ]; then
    SESSION_ID=$(cat /tmp/stripe_test_session_id)
    echo "GET /api/checkout/session/$SESSION_ID"
    echo ""

    STATUS_RESPONSE=$(api_call GET "/api/checkout/session/$SESSION_ID")
    echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"

    if echo "$STATUS_RESPONSE" | jq -e '.status' > /dev/null 2>&1; then
        STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
        echo -e "${GREEN}✓ Session status retrieved: $STATUS${NC}"
    else
        echo -e "${RED}✗ Failed to get session status${NC}"
    fi
else
    echo -e "${YELLOW}! Skipping - no session ID from previous test${NC}"
fi
echo ""

# Test 4: Test Invalid Tier (should fail)
echo -e "${BLUE}Test 4: Test Invalid Tier (Tier 5 - should fail)${NC}"
echo "POST /api/checkout/create-session"
echo ""

INVALID_TIER_DATA=$(cat <<EOF
{
    "leadId": "$LEAD_ID",
    "tier": 5,
    "successUrl": "http://localhost:3000/checkout/success",
    "cancelUrl": "http://localhost:3000/checkout/cancel"
}
EOF
)

INVALID_RESPONSE=$(api_call POST "/api/checkout/create-session" "$INVALID_TIER_DATA")
echo "$INVALID_RESPONSE" | jq . 2>/dev/null || echo "$INVALID_RESPONSE"

if echo "$INVALID_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Invalid tier correctly rejected${NC}"
else
    echo -e "${RED}✗ Invalid tier was not rejected (unexpected)${NC}"
fi
echo ""

# Test 5: Test Tier 4 (Custom - should fail or redirect)
echo -e "${BLUE}Test 5: Test Tier 4 (Custom pricing - should fail)${NC}"
echo "POST /api/checkout/create-session"
echo ""

TIER4_DATA=$(cat <<EOF
{
    "leadId": "$LEAD_ID",
    "tier": 4,
    "successUrl": "http://localhost:3000/checkout/success",
    "cancelUrl": "http://localhost:3000/checkout/cancel"
}
EOF
)

TIER4_RESPONSE=$(api_call POST "/api/checkout/create-session" "$TIER4_DATA")
echo "$TIER4_RESPONSE" | jq . 2>/dev/null || echo "$TIER4_RESPONSE"

if echo "$TIER4_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Tier 4 correctly requires custom handling${NC}"
else
    echo -e "${YELLOW}! Tier 4 behavior - check if this is expected${NC}"
fi
echo ""

echo "========================================="
echo "  Checkout Flow Tests Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. If session created, open the checkout URL in your browser"
echo "2. Use test card: 4242 4242 4242 4242"
echo "3. Any future date for expiry, any CVC"
echo "4. Complete the payment"
echo "5. Run test-webhooks.sh to verify webhook handling"
echo ""
