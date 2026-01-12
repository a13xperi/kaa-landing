# Stripe Integration Test Suite

Comprehensive test scripts for verifying Stripe payment integration in kaa-notion-backend.

## Prerequisites

1. **Stripe Test Keys** - Get from [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)
2. **Stripe CLI** - Required for webhook testing
3. **Backend Server** - Running at localhost:3001 (or set `API_URL`)
4. **Database** - Seeded with test leads/users

## Quick Start

```bash
# 1. Set environment variables
export STRIPE_SECRET_KEY=sk_test_...
export STRIPE_PUBLISHABLE_KEY=pk_test_...
export STRIPE_WEBHOOK_SECRET=whsec_...
export API_URL=http://localhost:3001
export AUTH_TOKEN=your_jwt_token  # If auth required

# 2. Make scripts executable
chmod +x *.sh

# 3. Run all tests
./run-all-tests.sh
```

## Test Scripts

| Script | Purpose |
|--------|---------|
| `env-check.sh` | Verifies environment is configured correctly |
| `test-checkout-flow.sh` | Tests checkout session creation and verification |
| `test-webhooks.sh` | Tests webhook handling with Stripe CLI |
| `test-subscriptions.sh` | Tests subscription CRUD operations |
| `test-edge-cases.sh` | Tests error handling and edge cases |
| `run-all-tests.sh` | Runs all tests in sequence |

## Test Cards

| Card Number | Result |
|-------------|--------|
| `4242 4242 4242 4242` | Success |
| `4000 0000 0000 0002` | Declined |
| `4000 0025 0000 3155` | Requires 3D Secure |
| `4000 0000 0000 9995` | Insufficient funds |

Use any future expiry date and any 3-digit CVC.

## Environment Variables

```bash
# Required
STRIPE_SECRET_KEY=sk_test_...      # Stripe secret key
STRIPE_PUBLISHABLE_KEY=pk_test_... # Stripe publishable key
STRIPE_WEBHOOK_SECRET=whsec_...    # Webhook signing secret

# Optional
API_URL=http://localhost:3001      # Backend API URL
AUTH_TOKEN=eyJhb...                # JWT token for authenticated endpoints
TEST_LEAD_ID=abc123                # Lead ID for checkout tests
TEST_CLIENT_ID=xyz789              # Client ID for subscription tests
CONVERTED_LEAD_ID=def456           # Already converted lead for edge case
```

## Test Phases

### Phase A: Environment Verification
```bash
./env-check.sh
```
- Checks Stripe keys are set and valid
- Verifies Stripe CLI is installed and authenticated
- Tests API connectivity
- Validates backend server is running

### Phase B: Checkout Flow
```bash
./test-checkout-flow.sh
```
Tests:
- GET /api/checkout/pricing
- POST /api/checkout/create-session (tiers 1-3)
- GET /api/checkout/session/:id
- Invalid tier handling (tier 4, 5)

### Phase C: Webhook Handling
```bash
./test-webhooks.sh
```
Tests:
- Stripe CLI webhook forwarding
- checkout.session.completed
- payment_intent.succeeded
- payment_intent.payment_failed
- customer.subscription.* events

### Phase D: Subscription Management
```bash
./test-subscriptions.sh
```
Tests:
- GET /api/subscriptions/:clientId
- POST /api/subscriptions/:clientId/billing-portal
- PATCH /api/subscriptions/:clientId (tier change)
- DELETE /api/subscriptions/:clientId (cancel)
- POST /api/subscriptions/:clientId/resume
- GET /api/subscriptions/metrics

### Phase E: Edge Cases
```bash
./test-edge-cases.sh
```
Tests:
- Non-existent lead ID
- Already converted lead
- Invalid tier values (0, -1, 5, "one")
- Missing required fields
- Invalid session ID
- Non-existent subscription
- Invalid webhook signatures
- Rate limiting

## Manual Testing Checklist

After running automated tests, manually verify:

- [ ] Complete a full checkout in browser with test card
- [ ] Verify email receipts are sent (if configured)
- [ ] Check Stripe Dashboard shows test payment
- [ ] Verify subscription appears in admin dashboard
- [ ] Test billing portal (update card, view invoices)
- [ ] Test upgrade flow (Tier 1 → Tier 2)
- [ ] Test downgrade flow (Tier 2 → Tier 1)
- [ ] Test cancellation from billing portal
- [ ] Verify webhooks update database state

## Troubleshooting

### "Stripe CLI not authenticated"
```bash
stripe login
```

### "Backend server not reachable"
```bash
# Start the backend
cd /path/to/kaa-notion-backend
npm run dev
```

### "Invalid webhook signature"
The webhook secret changes each time you start `stripe listen`. Update your .env:
```bash
# Get the new secret from stripe listen output
STRIPE_WEBHOOK_SECRET=whsec_new_secret_here
```

### "Rate limited"
Wait a few minutes or use a different Stripe test key.

## CI/CD Integration

For automated testing in CI:

```yaml
# Example GitHub Actions
- name: Run Stripe Tests
  env:
    STRIPE_SECRET_KEY: ${{ secrets.STRIPE_TEST_SECRET_KEY }}
    STRIPE_PUBLISHABLE_KEY: ${{ secrets.STRIPE_TEST_PUBLISHABLE_KEY }}
    API_URL: http://localhost:3001
  run: |
    ./scripts/stripe-tests/env-check.sh
    ./scripts/stripe-tests/test-checkout-flow.sh
    ./scripts/stripe-tests/test-edge-cases.sh
```

Note: Webhook tests require Stripe CLI and are best run manually or with special CI setup.
