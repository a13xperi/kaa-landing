/**
 * Site Configuration
 *
 * Centralized configuration for app integration URLs and settings.
 * Uses environment variables with fallback defaults.
 */

// App URLs
export const APP_URL = import.meta.env.PUBLIC_APP_URL || 'https://app.karenaitkenassociates.com';
export const API_URL = import.meta.env.PUBLIC_API_URL || 'https://api.karenaitkenassociates.com';
export const SITE_URL = import.meta.env.PUBLIC_SITE_URL || 'https://kaa-landing.vercel.app';

// Feature flags
export const ENABLE_LEAD_CAPTURE = import.meta.env.PUBLIC_ENABLE_LEAD_CAPTURE !== 'false';
export const ENABLE_DIRECT_CHECKOUT = import.meta.env.PUBLIC_ENABLE_DIRECT_CHECKOUT !== 'false';

// Third-party integrations
export const TYPEFORM_ID = import.meta.env.PUBLIC_TYPEFORM_ID || 'Gqmo3i';
export const CALENDLY_URL = import.meta.env.PUBLIC_CALENDLY_URL || '';

// Analytics
export const GA_MEASUREMENT_ID = import.meta.env.PUBLIC_GA_MEASUREMENT_ID || '';
export const PLAUSIBLE_DOMAIN = import.meta.env.PUBLIC_PLAUSIBLE_DOMAIN || '';

/**
 * Generate URLs for app pages
 */
export const appUrls = {
  // Authentication
  login: `${APP_URL}/login`,
  register: `${APP_URL}/register`,
  forgotPassword: `${APP_URL}/forgot-password`,

  // Checkout (with tier parameter)
  checkout: (tier: number) => `${APP_URL}/checkout?tier=${tier}`,
  checkoutSuccess: `${APP_URL}/checkout/success`,
  checkoutCancel: `${APP_URL}/checkout/cancel`,

  // Contact/Lead capture
  contact: `${APP_URL}/contact`,
  contactWithTier: (tier: number) => `${APP_URL}/contact?tier=${tier}`,

  // Dashboard
  dashboard: `${APP_URL}/dashboard`,
  teamDashboard: `${APP_URL}/team`,
  adminDashboard: `${APP_URL}/admin`,

  // Client portal
  clientPortal: `${APP_URL}/portal`,
};

/**
 * Generate URLs for API endpoints
 */
export const apiUrls = {
  // Lead capture
  leads: `${API_URL}/api/leads`,

  // Health check
  health: `${API_URL}/api/health`,

  // Analytics events
  analyticsEvent: `${API_URL}/api/analytics/event`,
};

/**
 * Typeform URL helper
 */
export const typeformUrl = TYPEFORM_ID
  ? `https://form.typeform.com/to/${TYPEFORM_ID}`
  : '';

/**
 * Pricing tiers configuration
 */
export const pricingTiers = [
  {
    id: 1,
    name: 'Single Render',
    shortName: 'Phase I',
    description: 'Front or backyard specific area such as pool, solid roof, etc.',
    price: 1000,
    priceDisplay: '$1,000 USD',
    features: [
      'Single area focus',
      'One revision included',
      'Delivered in 5-7 days',
    ],
  },
  {
    id: 2,
    name: 'Standard Render',
    shortName: 'Phase II',
    description: 'Full residential and landscape model, covering all designed elements.',
    price: 2000,
    priceDisplay: '$2,000 USD',
    features: [
      'Full property coverage',
      'Two revisions included',
      'Delivered in 7-10 days',
    ],
  },
  {
    id: 3,
    name: 'Full Render',
    shortName: 'Phase III',
    description: 'Extensive square footage residence and landscape model with/or difficult terrain.',
    price: 3000,
    priceDisplay: '$3,000 USD',
    features: [
      'Complex terrain support',
      'Three revisions included',
      'Delivered in 10-14 days',
      'Priority support',
    ],
  },
  {
    id: 4,
    name: 'Custom',
    shortName: 'Enterprise',
    description: 'Custom pricing for large-scale commercial or specialized projects.',
    price: null,
    priceDisplay: 'Custom',
    features: [
      'Unlimited revisions',
      'Dedicated project manager',
      'Custom timeline',
      'On-site consultation',
    ],
    isCustom: true,
  },
];

export default {
  APP_URL,
  API_URL,
  SITE_URL,
  appUrls,
  apiUrls,
  pricingTiers,
  typeformUrl,
};
