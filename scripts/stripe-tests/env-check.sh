#!/bin/bash
# Stripe Environment Verification Script
# Run this first to ensure your environment is properly configured

set -e

echo "========================================="
echo "  Stripe Environment Verification"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAIL++))
    fi
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check for required environment variables
echo "Checking environment variables..."
echo ""

if [ -n "$STRIPE_SECRET_KEY" ]; then
    if [[ "$STRIPE_SECRET_KEY" == sk_test_* ]]; then
        check 0 "STRIPE_SECRET_KEY is set (test mode)"
    elif [[ "$STRIPE_SECRET_KEY" == sk_live_* ]]; then
        check 0 "STRIPE_SECRET_KEY is set (LIVE MODE - BE CAREFUL!)"
        warn "You are using LIVE Stripe keys!"
    else
        check 1 "STRIPE_SECRET_KEY format invalid"
    fi
else
    check 1 "STRIPE_SECRET_KEY not set"
fi

if [ -n "$STRIPE_PUBLISHABLE_KEY" ]; then
    if [[ "$STRIPE_PUBLISHABLE_KEY" == pk_test_* ]]; then
        check 0 "STRIPE_PUBLISHABLE_KEY is set (test mode)"
    elif [[ "$STRIPE_PUBLISHABLE_KEY" == pk_live_* ]]; then
        check 0 "STRIPE_PUBLISHABLE_KEY is set (LIVE MODE)"
    else
        check 1 "STRIPE_PUBLISHABLE_KEY format invalid"
    fi
else
    check 1 "STRIPE_PUBLISHABLE_KEY not set"
fi

if [ -n "$STRIPE_WEBHOOK_SECRET" ]; then
    if [[ "$STRIPE_WEBHOOK_SECRET" == whsec_* ]]; then
        check 0 "STRIPE_WEBHOOK_SECRET is set"
    else
        check 1 "STRIPE_WEBHOOK_SECRET format invalid (should start with whsec_)"
    fi
else
    check 1 "STRIPE_WEBHOOK_SECRET not set"
fi

echo ""
echo "Checking Stripe CLI..."

if command -v stripe &> /dev/null; then
    check 0 "Stripe CLI is installed"

    # Check if logged in
    if stripe config --list 2>/dev/null | grep -q "test_mode_api_key"; then
        check 0 "Stripe CLI is authenticated"
    else
        check 1 "Stripe CLI not authenticated (run: stripe login)"
    fi
else
    check 1 "Stripe CLI not installed"
    echo ""
    echo "Install Stripe CLI:"
    echo "  macOS: brew install stripe/stripe-cli/stripe"
    echo "  Linux: See https://stripe.com/docs/stripe-cli#install"
fi

echo ""
echo "Checking API connectivity..."

if [ -n "$STRIPE_SECRET_KEY" ]; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "$STRIPE_SECRET_KEY:" \
        https://api.stripe.com/v1/balance)

    if [ "$RESPONSE" == "200" ]; then
        check 0 "Stripe API connection successful"
    else
        check 1 "Stripe API connection failed (HTTP $RESPONSE)"
    fi
fi

echo ""
echo "Checking backend server..."

API_URL=${API_URL:-"http://localhost:3001"}

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/health" 2>/dev/null || echo "000")
if [ "$RESPONSE" == "200" ]; then
    check 0 "Backend server is running at $API_URL"
else
    check 1 "Backend server not reachable at $API_URL (HTTP $RESPONSE)"
    warn "Start your backend server first"
fi

echo ""
echo "========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================="

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "Fix the issues above before running Stripe tests."
    exit 1
else
    echo ""
    echo "Environment is ready for Stripe testing!"
    exit 0
fi
