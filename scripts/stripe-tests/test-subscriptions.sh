#!/bin/bash
# Stripe Subscription Management Test Script
# Tests subscription CRUD operations

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
echo "  Stripe Subscription Management Tests"
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

# Get client ID from env or prompt
CLIENT_ID=${TEST_CLIENT_ID:-""}
if [ -z "$CLIENT_ID" ]; then
    echo -e "${YELLOW}Enter a client ID to test with:${NC}"
    read -p "Client ID: " CLIENT_ID
fi

if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}✗ Client ID required${NC}"
    exit 1
fi

echo "Testing with Client ID: $CLIENT_ID"
echo ""

# Test 1: Get Subscription
echo -e "${BLUE}Test 1: Get Current Subscription${NC}"
echo "GET /api/subscriptions/$CLIENT_ID"
echo ""

SUB_RESPONSE=$(api_call GET "/api/subscriptions/$CLIENT_ID")
echo "$SUB_RESPONSE" | jq . 2>/dev/null || echo "$SUB_RESPONSE"

if echo "$SUB_RESPONSE" | jq -e '.subscription' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Subscription found${NC}"
    CURRENT_TIER=$(echo "$SUB_RESPONSE" | jq -r '.subscription.tier // "unknown"')
    CURRENT_STATUS=$(echo "$SUB_RESPONSE" | jq -r '.subscription.status // "unknown"')
    echo "  Current Tier: $CURRENT_TIER"
    echo "  Status: $CURRENT_STATUS"
elif echo "$SUB_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo -e "${YELLOW}! No subscription found (may be expected for new clients)${NC}"
else
    echo -e "${RED}✗ Unexpected response${NC}"
fi
echo ""

# Test 2: Create Billing Portal Session
echo -e "${BLUE}Test 2: Create Billing Portal Session${NC}"
echo "POST /api/subscriptions/$CLIENT_ID/billing-portal"
echo ""

PORTAL_DATA=$(cat <<EOF
{
    "returnUrl": "http://localhost:3000/settings"
}
EOF
)

PORTAL_RESPONSE=$(api_call POST "/api/subscriptions/$CLIENT_ID/billing-portal" "$PORTAL_DATA")
echo "$PORTAL_RESPONSE" | jq . 2>/dev/null || echo "$PORTAL_RESPONSE"

if echo "$PORTAL_RESPONSE" | jq -e '.url' > /dev/null 2>&1; then
    PORTAL_URL=$(echo "$PORTAL_RESPONSE" | jq -r '.url')
    echo -e "${GREEN}✓ Billing portal session created${NC}"
    echo "  Portal URL: $PORTAL_URL"
else
    echo -e "${RED}✗ Failed to create billing portal session${NC}"
fi
echo ""

# Test 3: Update Subscription Tier (Upgrade)
echo -e "${BLUE}Test 3: Update Subscription Tier${NC}"
echo "PATCH /api/subscriptions/$CLIENT_ID"
echo ""
echo -e "${YELLOW}! This will attempt to change the subscription tier${NC}"
echo "Current tier: ${CURRENT_TIER:-unknown}"
echo ""
read -p "Enter new tier (1-3) or 'skip': " NEW_TIER

if [ "$NEW_TIER" != "skip" ] && [ -n "$NEW_TIER" ]; then
    UPDATE_DATA=$(cat <<EOF
{
    "tier": $NEW_TIER
}
EOF
)

    UPDATE_RESPONSE=$(api_call PATCH "/api/subscriptions/$CLIENT_ID" "$UPDATE_DATA")
    echo "$UPDATE_RESPONSE" | jq . 2>/dev/null || echo "$UPDATE_RESPONSE"

    if echo "$UPDATE_RESPONSE" | jq -e '.subscription' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Subscription tier updated${NC}"
    else
        echo -e "${RED}✗ Failed to update subscription${NC}"
    fi
else
    echo "Skipping tier update test."
fi
echo ""

# Test 4: Get Subscription Metrics
echo -e "${BLUE}Test 4: Get Subscription Metrics (Admin)${NC}"
echo "GET /api/subscriptions/metrics"
echo ""

METRICS_RESPONSE=$(api_call GET "/api/subscriptions/metrics")
echo "$METRICS_RESPONSE" | jq . 2>/dev/null || echo "$METRICS_RESPONSE"

if echo "$METRICS_RESPONSE" | jq -e '.mrr' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Metrics retrieved${NC}"
    MRR=$(echo "$METRICS_RESPONSE" | jq -r '.mrr // 0')
    ACTIVE=$(echo "$METRICS_RESPONSE" | jq -r '.activeSubscriptions // 0')
    CHURN=$(echo "$METRICS_RESPONSE" | jq -r '.churnRate // 0')
    echo "  MRR: \$$MRR"
    echo "  Active Subscriptions: $ACTIVE"
    echo "  Churn Rate: $CHURN%"
else
    echo -e "${YELLOW}! Metrics not available (may require admin access)${NC}"
fi
echo ""

# Test 5: Cancel Subscription
echo -e "${BLUE}Test 5: Cancel Subscription${NC}"
echo "DELETE /api/subscriptions/$CLIENT_ID"
echo ""
echo -e "${RED}! WARNING: This will cancel the subscription${NC}"
read -p "Cancel subscription? (yes/no): " CANCEL_CONFIRM

if [ "$CANCEL_CONFIRM" == "yes" ]; then
    CANCEL_RESPONSE=$(api_call DELETE "/api/subscriptions/$CLIENT_ID")
    echo "$CANCEL_RESPONSE" | jq . 2>/dev/null || echo "$CANCEL_RESPONSE"

    if echo "$CANCEL_RESPONSE" | jq -e '.subscription.status' > /dev/null 2>&1; then
        NEW_STATUS=$(echo "$CANCEL_RESPONSE" | jq -r '.subscription.status')
        echo -e "${GREEN}✓ Subscription canceled (status: $NEW_STATUS)${NC}"
    else
        echo -e "${RED}✗ Failed to cancel subscription${NC}"
    fi
else
    echo "Skipping cancel test."
fi
echo ""

# Test 6: Resume Subscription (if canceled)
echo -e "${BLUE}Test 6: Resume Subscription${NC}"
echo "POST /api/subscriptions/$CLIENT_ID/resume"
echo ""
read -p "Attempt to resume subscription? (yes/no): " RESUME_CONFIRM

if [ "$RESUME_CONFIRM" == "yes" ]; then
    RESUME_RESPONSE=$(api_call POST "/api/subscriptions/$CLIENT_ID/resume" "{}")
    echo "$RESUME_RESPONSE" | jq . 2>/dev/null || echo "$RESUME_RESPONSE"

    if echo "$RESUME_RESPONSE" | jq -e '.subscription.status' > /dev/null 2>&1; then
        NEW_STATUS=$(echo "$RESUME_RESPONSE" | jq -r '.subscription.status')
        echo -e "${GREEN}✓ Subscription resumed (status: $NEW_STATUS)${NC}"
    else
        echo -e "${RED}✗ Failed to resume subscription${NC}"
    fi
else
    echo "Skipping resume test."
fi
echo ""

echo "========================================="
echo "  Subscription Management Tests Complete"
echo "========================================="
