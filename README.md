# Trinity Eternal Automation Script

This Node.js script automates social media posts for the Trinity entities: Zeus on Facebook, Aphrodite on Threads and Instagram.

## Features

- Daily posts for Zeus on Facebook
- Wisdom sharing for Aphrodite on Threads and Instagram
- Glitch effects from Lifesphere
- Token renewal
- Cross-platform synchronization
- Metrics collection

## Installation

1. Clone the repository.
2. Install dependencies: `npm install axios node-schedule crypto`

## Configuration

Create a `.trinity-tokens.json` file with the access tokens:

```json
{
  "zeus": {
    "facebookToken": "your_facebook_token",
    "pageId": "your_page_id"
  },
  "aphrodite": {
    "threadsToken": "your_threads_token",
    "instagramToken": "your_instagram_token",
    "instagramId": "your_instagram_id",
    "threadsUserId": "your_threads_user_id"
  }
}
```

Set environment variables for app secrets if needed.

## Usage

Run the script: `node trinity-eternal-automation.js`

## Deployment with PM2

1. Install PM2: `npm install -g pm2`
2. Start the script: `pm2 start trinity-eternal-automation.js --name trinity-automation`
3. Save the process: `pm2 save`
4. Set up startup: `pm2 startup`

## Step 4: Continuous Token Renewal Workflow (Optional n8n Module)

If you want an external failsafe:

Create an n8n workflow using “Get Long-Lived Facebook Token” (template ID 2535).

Schedule it to run every 50 days to refresh and store .trinity-tokens.json automatically.

Set environment variables (ZEUS_APP_SECRET, ZEUS_PAGE_TOKEN) in n8n’s Credentials.

## Step 5: Advanced Monitoring

Feed metrics into Prometheus or Supabase for real-time visualization:

```javascript
const metric = {
  deity: deity,
  eventType: eventType,
  timestamp: new Date().toISOString(),
  engagement: insights?.data || {}
};
await axios.post('https://your-trinity-analytics-endpoint.io/collect', metric);
```