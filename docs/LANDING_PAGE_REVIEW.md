# Landing Page Review - January 2026

This document provides a comprehensive review of the KAA landing page current state and identifies areas for the next round of improvements.

---

## Executive Summary

The KAA landing page is a well-structured Astro 5.8.0 site with solid foundations:
- Clean component architecture
- Centralized configuration (`src/config.ts`)
- Good accessibility features (WCAG compliance goals)
- Integration points ready for the main KAA application
- Analytics tracking attributes in place

However, there are several bugs, placeholder content, and UX improvements that should be addressed.

---

## Current Status: What's Working Well

### Architecture & Tech Stack
| Component | Status | Notes |
|-----------|--------|-------|
| Astro 5.8.0 | Stable | Latest version |
| Tailwind CSS 4.1.7 | Stable | Modern utility classes |
| TypeScript | Configured | Strict mode enabled |
| SCSS | Working | Custom mixins and variables |
| Accessible Components | Integrated | Accordion, Tabs, Avatar, etc. |

### Features Implemented
- [x] Hero section with full-viewport background
- [x] Dual CTAs (Learn More / Get Started)
- [x] Services section with tabbed interface
- [x] Pricing tiers (3 of 4 shown)
- [x] Testimonial section
- [x] Stats/Counter section
- [x] FAQ accordion
- [x] Footer with social links
- [x] Portfolio/Projects routing system
- [x] MDX content support

### Integration Points Ready
- [x] Typeform contact form integration
- [x] App URLs configured (login, register, checkout, dashboard)
- [x] API endpoints defined (leads, health, analytics)
- [x] Data tracking attributes on all CTAs
- [x] Feature flags for lead capture and direct checkout

---

## Bugs & Issues (High Priority)

### 1. Duplicate Import in index.astro
**File:** `src/pages/index.astro:8`
```javascript
import { ..., Avatar, AvatarGroup, ..., Avatar } from 'accessible-astro-components';
```
**Issue:** `Avatar` is imported twice, which can cause build warnings.
**Fix:** Remove duplicate import.

---

### 2. Missing #services Anchor Target
**File:** `src/components/Hero.astro:22`
```javascript
const learnMoreUrl = '#services'; // Scroll to services section
```
**Issue:** The "Learn More" button links to `#services`, but no element in `index.astro` has `id="services"`.
**Fix:** Add `id="services"` to the services section in `index.astro`.

---

### 3. Non-Existent Image References
**File:** `src/pages/index.astro:41-65`
```html
<Media class="rounded-lg" src="garden-2-small.jpg" />
```
**Issue:** `garden-2-small.jpg` doesn't exist. Only `garden-1-small.jpg` exists in `/src/assets/images/landscape/`.
**Fix:** Either add the missing images or update references to existing ones.

---

### 4. Broken Footer Navigation Links
**File:** `src/components/Footer.astro:24-34`
```html
<li><a href="/about">About</a></li>       <!-- Page doesn't exist -->
<li><a href="/projects">Projects</a></li>  <!-- Page doesn't exist -->
```
**Issue:** Links to `/about` and `/projects` don't have corresponding pages.

**Projects section links:**
```html
<li><a href="/accessibility-statement">Commercial</a></li>  <!-- Wrong link -->
<li><a href="/accessible-components">Residential</a></li>   <!-- Wrong link -->
<li><a href="/color-contrast-checker">Civic</a></li>        <!-- Wrong link -->
```
**Issue:** Project category links point to accessibility pages, not actual project categories.
**Fix:** Create proper pages or update links to portfolio.

---

### 5. Mobile Responsive Issue - Services Section
**File:** `src/pages/index.astro:30`
```html
<div class="px-32 pt-12">
```
**Issue:** `px-32` (128px padding) is excessive on mobile devices.
**Fix:** Use responsive padding: `px-4 md:px-16 lg:px-32`

---

## Content Issues (Medium Priority)

### 6. Placeholder Stats Need Real Data
**File:** `src/pages/index.astro:77-80`
```html
<Counter count="900+" title="Projects" sub="Completed" />
<Counter count="25K+" title="Landscapes" sub="Designed" />
<Counter count="4M+" title="Plans" sub="Planted" />
<Counter count="5K+" title="Persons" sub="Happy" />
```
**Issue:** Stats appear to be placeholder data that should be replaced with real KAA metrics.

---

### 7. Stock Photo Testimonial
**File:** `src/pages/index.astro:117-119`
```html
<Avatar
    title="Jack Smith"
    img="https://plus.unsplash.com/premium_photo-1672239496290-5061cfee7ebb..."
/>
```
**Issue:** Uses generic name "Jack Smith" and stock photo. Should use real client testimonial with permission.

---

### 8. Missing 4th Pricing Tier (Custom/Enterprise)
**File:** `src/config.ts:117-131` defines 4 pricing tiers, but `index.astro:89-111` only displays 3.
**Issue:** The Custom/Enterprise tier is configured but not shown on the page.
**Fix:** Add 4th card or explicitly decide to exclude it.

---

### 9. Repeated Placeholder Images in Tabs
**Files:** All three service tabs use the same `garden-2-small.jpg` repeatedly.
**Issue:** No visual differentiation between Design Ideation, Conceptual Visualization, and Nature Realization examples.
**Fix:** Add real portfolio examples for each service tier.

---

### 10. Typo in Services Tab Description
**File:** `src/pages/index.astro:46`
```html
<p>Ideal for communication intial ideas without technical requirements.
```
**Issue:** "intial" should be "initial"

---

## Enhancement Opportunities (Lower Priority)

### 11. Add Dark Mode Toggle
The Navigation component has dark mode toggle code commented out. Consider enabling it for better UX.

### 12. Add Loading States for CTAs
Consider adding loading indicators when users click CTAs that navigate to external forms.

### 13. Implement Analytics Events
Data tracking attributes exist (`data-track="..."`) but no visible analytics implementation (GA4/Plausible scripts). Verify analytics is actually capturing events.

### 14. Add Scroll-to-Top Button
For the long single-page layout, a scroll-to-top button would improve navigation.

### 15. Add Contact Page
Currently all contact CTAs go to Typeform. Consider adding a dedicated `/contact` page.

### 16. SEO Improvements
- Add structured data (JSON-LD) for local business
- Add sitemap.xml generation
- Verify OpenGraph images are correct

---

## Image Assets Audit

### Current Inventory
| Directory | Files | Status |
|-----------|-------|--------|
| `/src/assets/images/landscape/` | 1 file (garden-1-small.jpg) | **Insufficient** - need more variety |
| `/src/assets/images/posts/` | 6 files | Stock images |
| `/src/assets/images/projects/` | 6 files | Stock images |
| `/src/assets/img/` | 3 files | KAA logos (good) |

### Recommendation
Replace stock images with actual KAA portfolio work. At minimum, need:
- 3-4 landscape hero images
- 4+ images per service tier (Design Ideation, Conceptual Viz, Nature Realization)
- Real client testimonial photos (with permission)
- Project-specific images for portfolio pages

---

## Priority Action Items

### P0 - Critical (Fix Before Launch)
1. [ ] Fix duplicate Avatar import (causes build warnings)
2. [ ] Add `id="services"` anchor for hero button
3. [ ] Fix non-existent image references (garden-2-small.jpg)
4. [ ] Fix broken footer links

### P1 - High (Fix Soon)
5. [ ] Fix mobile responsive padding on services section
6. [ ] Fix "intial" typo
7. [ ] Add real images for service tabs
8. [ ] Update placeholder stats with real data

### P2 - Medium (Before Marketing Push)
9. [ ] Replace stock testimonial with real client
10. [ ] Add 4th pricing tier or update config
11. [ ] Create /about and /projects pages (or update footer links)
12. [ ] Verify analytics is working

### P3 - Nice to Have
13. [ ] Enable dark mode toggle
14. [ ] Add scroll-to-top button
15. [ ] Add dedicated contact page
16. [ ] Implement structured data

---

## Files Requiring Changes

| File | Changes Needed |
|------|----------------|
| `src/pages/index.astro` | Fix imports, add #services id, fix padding, fix typo, add images |
| `src/components/Footer.astro` | Fix broken links |
| `src/components/Hero.astro` | No changes (anchor target issue is in index.astro) |
| `src/assets/images/landscape/` | Add more images |

---

## Next Steps Recommendations

1. **Immediate Fixes**: Address P0 bugs (30 min effort)
2. **Content Sprint**: Work with KAA to gather real images and testimonials
3. **Page Creation**: Decide on /about and /projects pages structure
4. **Analytics Verification**: Confirm events are being tracked
5. **Pre-Launch Checklist**: Complete P1 items before any marketing

---

*Review conducted: January 12, 2026*
*Next review recommended: After P0 and P1 items completed*
