#!/bin/bash
# Stripe Webhook Test Script
# Tests webhook handling using Stripe CLI

set -e

# Configuration
API_URL=${API_URL:-"http://localhost:3001"}
WEBHOOK_ENDPOINT="/api/webhooks/stripe"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "========================================="
echo "  Stripe Webhook Tests"
echo "========================================="
echo ""

# Check if Stripe CLI is available
if ! command -v stripe &> /dev/null; then
    echo -e "${RED}✗ Stripe CLI not installed${NC}"
    echo ""
    echo "Install Stripe CLI first:"
    echo "  macOS: brew install stripe/stripe-cli/stripe"
    echo "  Linux: See https://stripe.com/docs/stripe-cli#install"
    exit 1
fi

echo -e "${GREEN}✓ Stripe CLI found${NC}"
echo ""

# Function to run webhook listener in background
start_webhook_listener() {
    echo -e "${BLUE}Starting webhook listener...${NC}"
    echo "Forwarding to: $API_URL$WEBHOOK_ENDPOINT"
    echo ""

    # Run in background and capture webhook secret
    stripe listen --forward-to "$API_URL$WEBHOOK_ENDPOINT" > /tmp/stripe_webhook_output.log 2>&1 &
    LISTENER_PID=$!
    echo $LISTENER_PID > /tmp/stripe_listener_pid

    # Wait for webhook secret to be printed
    sleep 3

    if [ -f /tmp/stripe_webhook_output.log ]; then
        WEBHOOK_SECRET=$(grep -o 'whsec_[a-zA-Z0-9]*' /tmp/stripe_webhook_output.log | head -1)
        if [ -n "$WEBHOOK_SECRET" ]; then
            echo -e "${GREEN}✓ Webhook listener started (PID: $LISTENER_PID)${NC}"
            echo -e "${CYAN}Webhook Secret: $WEBHOOK_SECRET${NC}"
            echo ""
            echo -e "${YELLOW}! Important: Update your .env with this webhook secret:${NC}"
            echo "  STRIPE_WEBHOOK_SECRET=$WEBHOOK_SECRET"
            echo ""
            echo "$WEBHOOK_SECRET" > /tmp/stripe_webhook_secret
        fi
    fi
}

# Function to stop webhook listener
stop_webhook_listener() {
    if [ -f /tmp/stripe_listener_pid ]; then
        PID=$(cat /tmp/stripe_listener_pid)
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID 2>/dev/null
            echo -e "${GREEN}✓ Webhook listener stopped${NC}"
        fi
        rm /tmp/stripe_listener_pid
    fi
}

# Cleanup on exit
trap stop_webhook_listener EXIT

# Menu
echo "Select test option:"
echo "1. Start webhook listener (for manual testing)"
echo "2. Trigger test checkout.session.completed event"
echo "3. Trigger test payment_intent.succeeded event"
echo "4. Trigger test payment_intent.payment_failed event"
echo "5. Trigger test customer.subscription.created event"
echo "6. Trigger test customer.subscription.updated event"
echo "7. Trigger test customer.subscription.deleted event"
echo "8. Run all webhook tests"
echo "9. View recent webhook events"
echo "0. Exit"
echo ""
read -p "Enter option: " OPTION

case $OPTION in
    1)
        echo ""
        start_webhook_listener
        echo "Webhook listener is running. Press Ctrl+C to stop."
        echo "In another terminal, complete a test checkout to trigger webhooks."
        echo ""
        # Wait for user interrupt
        wait $LISTENER_PID 2>/dev/null
        ;;

    2)
        echo ""
        echo -e "${BLUE}Triggering checkout.session.completed event...${NC}"
        stripe trigger checkout.session.completed
        echo ""
        echo "Check your server logs for webhook processing."
        ;;

    3)
        echo ""
        echo -e "${BLUE}Triggering payment_intent.succeeded event...${NC}"
        stripe trigger payment_intent.succeeded
        echo ""
        echo "Check your server logs for webhook processing."
        ;;

    4)
        echo ""
        echo -e "${BLUE}Triggering payment_intent.payment_failed event...${NC}"
        stripe trigger payment_intent.payment_failed
        echo ""
        echo "Check your server logs for webhook processing."
        ;;

    5)
        echo ""
        echo -e "${BLUE}Triggering customer.subscription.created event...${NC}"
        stripe trigger customer.subscription.created
        echo ""
        echo "Check your server logs for webhook processing."
        ;;

    6)
        echo ""
        echo -e "${BLUE}Triggering customer.subscription.updated event...${NC}"
        stripe trigger customer.subscription.updated
        echo ""
        echo "Check your server logs for webhook processing."
        ;;

    7)
        echo ""
        echo -e "${BLUE}Triggering customer.subscription.deleted event...${NC}"
        stripe trigger customer.subscription.deleted
        echo ""
        echo "Check your server logs for webhook processing."
        ;;

    8)
        echo ""
        echo -e "${BLUE}Running all webhook tests...${NC}"
        echo ""

        EVENTS=(
            "checkout.session.completed"
            "payment_intent.succeeded"
            "payment_intent.payment_failed"
            "customer.subscription.created"
            "customer.subscription.updated"
            "customer.subscription.deleted"
        )

        for EVENT in "${EVENTS[@]}"; do
            echo -e "${CYAN}Testing: $EVENT${NC}"
            stripe trigger "$EVENT"
            sleep 2
            echo ""
        done

        echo -e "${GREEN}✓ All webhook tests triggered${NC}"
        echo "Check your server logs for webhook processing results."
        ;;

    9)
        echo ""
        echo -e "${BLUE}Recent webhook events:${NC}"
        echo ""
        stripe events list --limit 10
        ;;

    0)
        echo "Exiting."
        exit 0
        ;;

    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "  Webhook Test Complete"
echo "========================================="
