#!/bin/bash
# Team Portal API Diagnostic Script
# Tests all team-related API endpoints

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
echo "  Team Portal API Diagnostics"
echo "========================================="
echo ""
echo "API URL: $API_URL"
echo "Auth Token: ${AUTH_TOKEN:+[SET]}${AUTH_TOKEN:-[NOT SET]}"
echo ""

# Check if auth token is set
if [ -z "$AUTH_TOKEN" ]; then
    echo -e "${YELLOW}Warning: AUTH_TOKEN not set. Some endpoints may fail.${NC}"
    echo "Set it with: export AUTH_TOKEN=your_jwt_token"
    echo ""
fi

PASS=0
FAIL=0

# Helper function for API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4

    echo -e "${BLUE}Testing: $description${NC}"
    echo "$method $endpoint"

    if [ -n "$AUTH_TOKEN" ]; then
        AUTH_HEADER="Authorization: Bearer $AUTH_TOKEN"
    else
        AUTH_HEADER=""
    fi

    if [ "$method" == "GET" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            ${AUTH_HEADER:+-H "$AUTH_HEADER"} 2>&1)
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$method" "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
            -d "$data" 2>&1)
    fi

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
        echo -e "${GREEN}✓ $HTTP_CODE OK${NC}"
        ((PASS++))
    elif [[ "$HTTP_CODE" == "401" ]]; then
        echo -e "${YELLOW}! $HTTP_CODE Unauthorized (need AUTH_TOKEN)${NC}"
        ((FAIL++))
    elif [[ "$HTTP_CODE" == "403" ]]; then
        echo -e "${YELLOW}! $HTTP_CODE Forbidden (insufficient permissions)${NC}"
        ((FAIL++))
    else
        echo -e "${RED}✗ $HTTP_CODE Failed${NC}"
        ((FAIL++))
    fi

    # Show response body (truncated)
    if [ -n "$BODY" ]; then
        echo "$BODY" | jq . 2>/dev/null | head -10 || echo "$BODY" | head -5
    fi
    echo ""
}

# ==========================================
# Health Check
# ==========================================
echo -e "${CYAN}=== Health Check ===${NC}"
api_call GET "/api/health" "" "Server health"

# ==========================================
# Team Members Endpoints
# ==========================================
echo -e "${CYAN}=== Team Members ===${NC}"

api_call GET "/api/team/members" "" "Get all team members"

api_call GET "/api/team/members/me" "" "Get current user's team membership"

# ==========================================
# Team Stats
# ==========================================
echo -e "${CYAN}=== Team Stats ===${NC}"

api_call GET "/api/team/stats" "" "Get team statistics"

# ==========================================
# Team Invites
# ==========================================
echo -e "${CYAN}=== Team Invites ===${NC}"

api_call GET "/api/team/invites" "" "Get pending invites"

# ==========================================
# Role Permissions
# ==========================================
echo -e "${CYAN}=== Role Permissions ===${NC}"

for role in OWNER ADMIN DESIGNER VIEWER; do
    api_call GET "/api/team/permissions/$role" "" "Get $role permissions"
done

# ==========================================
# Test Invite Flow (if token set)
# ==========================================
if [ -n "$AUTH_TOKEN" ]; then
    echo -e "${CYAN}=== Invite Flow Test ===${NC}"

    TEST_EMAIL="test-$(date +%s)@example.com"
    echo "Testing invite with email: $TEST_EMAIL"
    echo ""

    # Create invite
    INVITE_RESPONSE=$(curl -s -X POST "$API_URL/api/team/invite" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "{\"email\": \"$TEST_EMAIL\", \"role\": \"VIEWER\"}")

    echo "$INVITE_RESPONSE" | jq . 2>/dev/null || echo "$INVITE_RESPONSE"

    if echo "$INVITE_RESPONSE" | jq -e '.invite.id' > /dev/null 2>&1; then
        INVITE_ID=$(echo "$INVITE_RESPONSE" | jq -r '.invite.id')
        echo -e "${GREEN}✓ Invite created: $INVITE_ID${NC}"
        ((PASS++))

        # Cancel the test invite
        echo ""
        echo "Cleaning up test invite..."
        CANCEL_RESPONSE=$(curl -s -X DELETE "$API_URL/api/team/invite/$INVITE_ID" \
            -H "Authorization: Bearer $AUTH_TOKEN")

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Test invite cleaned up${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to create invite${NC}"
        ((FAIL++))
    fi
    echo ""
fi

# ==========================================
# WebSocket Check
# ==========================================
echo -e "${CYAN}=== WebSocket Check ===${NC}"

WS_URL=$(echo "$API_URL" | sed 's/http/ws/')
echo "WebSocket URL would be: $WS_URL"
echo "(WebSocket testing requires a dedicated client)"
echo ""

# ==========================================
# Summary
# ==========================================
echo "========================================="
echo "  Diagnostic Results"
echo "========================================="
echo ""
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${YELLOW}Some tests failed. Check:${NC}"
    echo "1. Is the backend server running?"
    echo "2. Is AUTH_TOKEN set correctly?"
    echo "3. Does your user have team permissions?"
    echo ""
    echo "Common fixes:"
    echo "  export API_URL=http://localhost:3001"
    echo "  export AUTH_TOKEN=\$(curl -s -X POST \$API_URL/api/auth/login \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"email\":\"admin@example.com\",\"password\":\"yourpassword\"}' | jq -r '.token')"
else
    echo -e "${GREEN}All tests passed! Team API is working correctly.${NC}"
fi
