#!/bin/bash
# Master Stripe Test Runner
# Runs all Stripe integration tests in sequence

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "========================================="
echo "  Stripe Integration Test Suite"
echo "========================================="
echo ""
echo "This will run all Stripe integration tests."
echo ""

# Configuration
export API_URL=${API_URL:-"http://localhost:3001"}
export AUTH_TOKEN=${AUTH_TOKEN:-""}

echo "Configuration:"
echo "  API_URL: $API_URL"
echo "  AUTH_TOKEN: ${AUTH_TOKEN:+[SET]}${AUTH_TOKEN:-[NOT SET]}"
echo ""

# Test card numbers for reference
echo -e "${CYAN}Test Card Numbers:${NC}"
echo "  Success: 4242 4242 4242 4242"
echo "  Decline: 4000 0000 0000 0002"
echo "  Requires Auth: 4000 0025 0000 3155"
echo "  Insufficient Funds: 4000 0000 0000 9995"
echo ""
echo "Use any future expiry date and any 3-digit CVC."
echo ""

read -p "Press Enter to start tests or Ctrl+C to cancel..."
echo ""

# Phase 1: Environment Check
echo -e "${BLUE}Phase 1: Environment Verification${NC}"
echo "----------------------------------------"
if bash "$SCRIPT_DIR/env-check.sh"; then
    echo ""
    echo -e "${GREEN}✓ Environment check passed${NC}"
else
    echo ""
    echo -e "${RED}✗ Environment check failed${NC}"
    echo "Fix the issues above before continuing."
    exit 1
fi
echo ""

# Phase 2: Checkout Flow Tests
echo -e "${BLUE}Phase 2: Checkout Flow Tests${NC}"
echo "----------------------------------------"
bash "$SCRIPT_DIR/test-checkout-flow.sh"
echo ""

# Phase 3: Edge Case Tests
echo -e "${BLUE}Phase 3: Edge Case Tests${NC}"
echo "----------------------------------------"
bash "$SCRIPT_DIR/test-edge-cases.sh"
echo ""

# Phase 4: Subscription Tests (Interactive)
echo -e "${BLUE}Phase 4: Subscription Management Tests${NC}"
echo "----------------------------------------"
echo "Subscription tests require an existing client with a subscription."
read -p "Run subscription tests? (yes/no): " RUN_SUB

if [ "$RUN_SUB" == "yes" ]; then
    bash "$SCRIPT_DIR/test-subscriptions.sh"
fi
echo ""

# Phase 5: Webhook Tests (Interactive)
echo -e "${BLUE}Phase 5: Webhook Tests${NC}"
echo "----------------------------------------"
echo "Webhook tests require Stripe CLI and will start a listener."
read -p "Run webhook tests? (yes/no): " RUN_WEBHOOK

if [ "$RUN_WEBHOOK" == "yes" ]; then
    bash "$SCRIPT_DIR/test-webhooks.sh"
fi
echo ""

echo "========================================="
echo "  Test Suite Complete"
echo "========================================="
echo ""
echo -e "${GREEN}Manual verification checklist:${NC}"
echo "[ ] Checkout session created successfully"
echo "[ ] Payment completed with test card"
echo "[ ] Webhook received and processed"
echo "[ ] Subscription created in database"
echo "[ ] Billing portal accessible"
echo "[ ] Tier changes work correctly"
echo "[ ] Cancellation/resume works"
echo "[ ] Edge cases return proper errors"
echo ""
