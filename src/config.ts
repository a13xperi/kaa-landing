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
    name: 'Cozy Corner Magic',
    shortName: 'The First Spark',
    description: 'Transform one special spot—a peaceful patio retreat, a poolside paradise, or a secret garden nook where your family gathers.',
    price: 1000,
    priceDisplay: '$1,000 USD',
    features: [
      'One cherished space transformed',
      'One dream revision included',
      'Magic delivered in 5-7 days',
    ],
  },
  {
    id: 2,
    name: 'Complete Family Haven',
    shortName: 'The Full Vision',
    description: 'Your entire outdoor space reimagined—every corner designed for connection, play, and those quiet moments that become treasured memories.',
    price: 2000,
    priceDisplay: '$2,000 USD',
    features: [
      'Your whole outdoor sanctuary',
      'Two dream revisions included',
      'Vision revealed in 7-10 days',
    ],
  },
  {
    id: 3,
    name: 'Estate of Wonder',
    shortName: 'The Grand Dream',
    description: 'For larger properties and ambitious dreams—a comprehensive sanctuary where generations of your family will gather, celebrate, and belong.',
    price: 3000,
    priceDisplay: '$3,000 USD',
    features: [
      'Grand estates and challenging terrain',
      'Three dream revisions included',
      'Masterpiece unveiled in 10-14 days',
      'Priority Sage guidance',
    ],
  },
  {
    id: 4,
    name: 'Bespoke Dreamscape',
    shortName: 'Extraordinary',
    description: 'For visionaries with grand dreams—commercial spaces, community projects, or estates that will become landmarks of joy.',
    price: null,
    priceDisplay: 'Custom',
    features: [
      'Unlimited dream refinements',
      'Dedicated Sage wizard',
      'Timeline tailored to your story',
      'Personal site visits',
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
