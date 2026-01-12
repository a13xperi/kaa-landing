# KAA Landing Page - App Integration Guide

This guide explains how to integrate the landing page with the main KAA application (kaa-notion-backend).

## Overview

The landing page connects to the main app for:
- User registration and login
- Checkout/payment processing
- Lead capture via contact forms
- Analytics tracking

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Site URL (where landing page is deployed)
PUBLIC_SITE_URL=https://kaa-landing.vercel.app

# Main app URL (frontend)
PUBLIC_APP_URL=https://app.karenaitkenassociates.com

# API URL (backend)
PUBLIC_API_URL=https://api.karenaitkenassociates.com

# Feature flags
PUBLIC_ENABLE_LEAD_CAPTURE=true
PUBLIC_ENABLE_DIRECT_CHECKOUT=true

# Typeform (existing contact form - optional)
PUBLIC_TYPEFORM_ID=Gqmo3i
```

### Vercel Configuration

Add these environment variables in Vercel Dashboard:
1. Go to Project Settings → Environment Variables
2. Add each `PUBLIC_*` variable for Production/Preview/Development

## URL Mapping

| Landing Page Element | Target URL |
|---------------------|------------|
| Hero "Get Started" | Typeform or `/contact` |
| Pricing Tier 1 | `/checkout?tier=1` |
| Pricing Tier 2 | `/checkout?tier=2` |
| Pricing Tier 3 | `/checkout?tier=3` |
| Footer CTA | Typeform or `/contact` |
| "Contact us" links | Typeform or `/contact` |

## Backend CORS Configuration

The backend (kaa-notion-backend) must allow requests from the landing page domain.

### Update `server/src/index.ts`:

```typescript
import cors from 'cors';

// CORS configuration
const corsOptions = {
  origin: [
    // Landing page
    'https://kaa-landing.vercel.app',
    process.env.LANDING_PAGE_URL,

    // Main app
    'https://app.karenaitkenassociates.com',
    process.env.FRONTEND_URL,

    // Development
    'http://localhost:4321',  // Astro dev server
    'http://localhost:3000',  // React dev server
    'http://localhost:5173',  // Vite dev server
  ].filter(Boolean),

  credentials: true,

  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'Accept',
  ],
};

app.use(cors(corsOptions));
```

### Add to `server/.env`:

```bash
# Landing page URL for CORS
LANDING_PAGE_URL=https://kaa-landing.vercel.app
```

## Lead Capture Integration

If you want leads submitted from the landing page to go directly to the backend:

### Option 1: Typeform (Current)
Leads go to Typeform → Webhook → Backend (if configured)

### Option 2: Direct API Integration

Create a contact form component that posts to the API:

```astro
---
// src/components/ContactForm.astro
import { apiUrls } from '../config';
---

<form id="contact-form" class="contact-form">
  <input type="text" name="name" placeholder="Your Name" required />
  <input type="email" name="email" placeholder="Email" required />
  <input type="text" name="company" placeholder="Company (optional)" />
  <select name="tier">
    <option value="">Interested in...</option>
    <option value="1">Single Render ($1,000)</option>
    <option value="2">Standard Render ($2,000)</option>
    <option value="3">Full Render ($3,000)</option>
    <option value="4">Custom Project</option>
  </select>
  <textarea name="message" placeholder="Tell us about your project"></textarea>
  <button type="submit">Send Message</button>
</form>

<script define:vars={{ apiUrl: apiUrls.leads }}>
  document.getElementById('contact-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const formData = new FormData(form);

    try {
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.get('name'),
          email: formData.get('email'),
          company: formData.get('company'),
          interestedTier: formData.get('tier'),
          message: formData.get('message'),
          source: 'landing_page',
          referrer: document.referrer,
        }),
      });

      if (response.ok) {
        // Show success message or redirect
        window.location.href = '/thank-you';
      } else {
        throw new Error('Submission failed');
      }
    } catch (error) {
      console.error('Form error:', error);
      alert('Something went wrong. Please try again.');
    }
  });
</script>
```

### Backend Lead Endpoint

Ensure the backend has a lead endpoint:

```typescript
// server/src/routes/leads.ts
router.post('/api/leads', async (req, res) => {
  const { name, email, company, interestedTier, message, source, referrer } = req.body;

  const lead = await prisma.lead.create({
    data: {
      name,
      email,
      company,
      interestedTier: interestedTier ? parseInt(interestedTier) : null,
      message,
      source: source || 'website',
      referrer,
      status: 'NEW',
    },
  });

  // Send notification email to admin
  await emailService.sendLeadNotification(lead);

  res.json({ success: true, leadId: lead.id });
});
```

## Analytics Tracking

The landing page includes `data-track` attributes on CTAs for analytics.

### Basic Event Tracking Script

Add to `src/layouts/DefaultLayout.astro`:

```astro
<script>
  // Track CTA clicks
  document.querySelectorAll('[data-track]').forEach((el) => {
    el.addEventListener('click', () => {
      const trackId = el.getAttribute('data-track');

      // Google Analytics 4
      if (typeof gtag !== 'undefined') {
        gtag('event', 'cta_click', {
          event_category: 'engagement',
          event_label: trackId,
          page_path: window.location.pathname,
        });
      }

      // Custom analytics endpoint
      fetch('/api/analytics/event', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event: 'cta_click',
          properties: {
            trackId,
            page: window.location.pathname,
            referrer: document.referrer,
          },
        }),
      }).catch(() => {}); // Don't block on analytics failures
    });
  });
</script>
```

## Shared Authentication (Optional)

If you want users to stay logged in across landing page and app:

### Cookie Domain Configuration

```typescript
// Backend: Set cookies for parent domain
res.cookie('token', token, {
  domain: '.karenaitkenassociates.com',  // Note the leading dot
  httpOnly: true,
  secure: true,
  sameSite: 'lax',
  maxAge: 30 * 24 * 60 * 60 * 1000,  // 30 days
});
```

### Landing Page Login Check

```astro
---
// Check if user is logged in
const token = Astro.cookies.get('token')?.value;
const isLoggedIn = !!token;
---

{isLoggedIn ? (
  <a href={appUrls.dashboard}>Go to Dashboard</a>
) : (
  <a href={appUrls.login}>Sign In</a>
)}
```

## Deployment Checklist

Before deploying the integrated landing page:

- [ ] Set all `PUBLIC_*` environment variables in Vercel
- [ ] Update CORS configuration in backend
- [ ] Test checkout flow end-to-end
- [ ] Test contact form submission
- [ ] Verify analytics tracking
- [ ] Check mobile responsiveness
- [ ] Test all CTA links
- [ ] Verify SEO meta tags (site URL is correct)

## Troubleshooting

### CORS Errors
- Check backend CORS configuration includes landing page URL
- Verify `credentials: true` is set
- Check for typos in origin URLs

### Links Not Working
- Verify `PUBLIC_APP_URL` is set correctly
- Check browser console for JavaScript errors
- Ensure config.ts is imported correctly

### Form Submissions Failing
- Check network tab for API errors
- Verify CORS allows POST requests
- Check backend logs for validation errors

### Analytics Not Tracking
- Verify GA measurement ID is set
- Check browser console for script errors
- Ensure ad blockers aren't blocking requests
