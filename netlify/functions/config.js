/**
 * Divine Trinity Portal - Single App Configuration
 * One app for OAuth login, Messenger bot, and payment processing
 */

const config = {
  // Facebook App Credentials
  appId: '371124213732093',
  appSecret: process.env.FB_APP_SECRET,
  
  // Page Configuration
  pageId: process.env.FB_PAGE_ID,
  pageAccessToken: process.env.PAGE_ACCESS_TOKEN,
  
  // Webhook Security
  webhookVerifyToken: 'divine_trinity_webhook_2025',
  
  // OAuth Redirect
  redirectUri: 'https://kypriatechnologies.org/auth/callback',
  
  // Stripe Configuration
  stripeSecretKey: process.env.STRIPE_SECRET_KEY,
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
  
  // OpenAI Configuration
  openaiApiKey: process.env.OPENAI_API_KEY,
  
  // Redis Configuration
  redisUrl: process.env.REDIS_URL,
  
  // App URLs
  baseUrl: 'https://kypriatechnologies.org',
  messengerUrl: 'https://m.me/705565335971937',
  
  // Feature Flags
  features: {
    facebookLogin: true,
    messengerBot: true,
    premiumOracle: true,
    subscriptions: true,
    sealGeneration: true,
    analytics: true
  }
};

module.exports = config;