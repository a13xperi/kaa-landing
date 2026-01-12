# Pull Request: Verify TypeScript Fixes & Add Integration Tools

## Summary
This PR verifies the TypeScript fixes and adds comprehensive tooling for Stripe testing, team portal fixes, and landing page integration.

### What's Included
- **Stripe Integration Test Suite** - Executable scripts for testing checkout, webhooks, and subscriptions
- **Team Portal Fix** - New `useTeam` hook and component patches to fix data reflection issues
- **Landing Page Integration** - Connect CTAs to main app checkout/contact flows
- **Next Steps Documentation** - Google OAuth frontend integration and Karen/Pam stakeholder view specs

## Changes

### Scripts
- `scripts/stripe-tests/` - Complete test suite for Stripe integration
  - `env-check.sh` - Environment verification
  - `test-checkout-flow.sh` - Checkout session tests
  - `test-webhooks.sh` - Webhook handling tests
  - `test-subscriptions.sh` - Subscription CRUD tests
  - `test-edge-cases.sh` - Error handling tests

### Team Portal Fix
- `scripts/team-portal-fix/useTeam.ts` - New React Query hook (copy to kaa-app)
- `scripts/team-portal-fix/TeamLogin.tsx.fixed` - Fixed login component
- `scripts/team-portal-fix/TeamManagement.tsx.fixed` - Fixed management component
- `scripts/team-portal-fix/DIAGNOSIS.md` - Root cause analysis

### Landing Integration
- `src/config.ts` - Centralized URL configuration
- `astro.config.mjs` - Updated site URL
- `.env.example` - Environment template
- Hero, CallToAction, index.astro - Updated CTAs with proper links

### Documentation
- `docs/APP_INTEGRATION.md` - Full integration guide with CORS setup
- `docs/NEXT_STEPS.md` - Google OAuth + Karen/Pam admin view specs

## Test Plan
- [x] Build passes (`npm run build`)
- [ ] Stripe tests run successfully
- [ ] Team API tests pass
- [ ] Landing page CTAs link correctly
- [ ] Vercel deployment works

## Next Steps (After Merge)
1. **Merge PR #82 in kaa-notion-backend** - Enables Google OAuth
2. **Add Google Sign-In button** - Frontend integration per docs/NEXT_STEPS.md
3. **Implement Karen/Pam filtered view** - Stakeholder dashboard in admin portal
4. **Configure CORS** - Add landing page URL to backend allowed origins
