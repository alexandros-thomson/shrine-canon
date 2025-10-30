/**
 * Unified OAuth Callback Handler
 * Single endpoint for Facebook login → Messenger connection
 */

const config = require('./config');
const { setUserContext } = require('./redis-context');

exports.handler = async (event, context) => {
  // Only allow GET requests
  if (event.httpMethod !== 'GET') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  const { code, state, error, error_description } = event.queryStringParameters || {};

  // Handle OAuth errors
  if (error) {
    console.error('OAuth error:', error, error_description);
    return {
      statusCode: 302,
      headers: {
        Location: `${config.baseUrl}?error=${error}`
      }
    };
  }

  // Exchange code for access token
  if (!code) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'No authorization code provided' })
    };
  }

  try {
    // Step 1: Exchange authorization code for access token
    const tokenResponse = await fetch(
      `https://graph.facebook.com/v18.0/oauth/access_token?` +
      `client_id=${config.appId}&` +
      `redirect_uri=${encodeURIComponent(config.redirectUri)}&` +
      `client_secret=${config.appSecret}&` +
      `code=${code}`
    );

    if (!tokenResponse.ok) {
      throw new Error('Failed to exchange code for token');
    }

    const tokenData = await tokenResponse.json();
    const { access_token, expires_in } = tokenData;

    console.log('✅ Access token obtained');

    // Step 2: Get user profile information
    const profileResponse = await fetch(
      `https://graph.facebook.com/v18.0/me?` +
      `fields=id,name,email,picture&` +
      `access_token=${access_token}`
    );

    if (!profileResponse.ok) {
      throw new Error('Failed to fetch user profile');
    }

    const userProfile = await profileResponse.json();
    console.log('✅ User profile retrieved:', userProfile.name);

    // Step 3: Get Page-Scoped User ID (PSID) for Messenger
    // This is the ID we'll use for Messenger communication
    const psidResponse = await fetch(
      `https://graph.facebook.com/v18.0/${userProfile.id}/ids_for_pages?` +
      `page=${config.pageId}&` +
      `access_token=${access_token}`
    );

    let psid = null;
    if (psidResponse.ok) {
      const psidData = await psidResponse.json();
      if (psidData.data && psidData.data.length > 0) {
        psid = psidData.data[0].id;
        console.log('✅ PSID obtained:', psid);
      }
    }

    // Step 4: Initialize user context in Redis
    const userContext = {
      userId: userProfile.id,
      psid: psid,
      name: userProfile.name,
      email: userProfile.email,
      picture: userProfile.picture?.data?.url,
      accessToken: access_token,
      tokenExpiry: Date.now() + (expires_in * 1000),
      deity: state || null, // State can carry deity selection
      tier: 'public',
      createdAt: Date.now(),
      lastLogin: Date.now()
    };

    // Store in Redis (using PSID as key if available, otherwise userId)
    const contextKey = psid || userProfile.id;
    await setUserContext(contextKey, userContext);

    console.log('✅ User context stored');

    // Step 5: Redirect to dashboard with success
    const redirectUrl = `${config.baseUrl}/dashboard?` +
      `connected=true&` +
      `name=${encodeURIComponent(userProfile.name)}&` +
      `psid=${psid || ''}`;

    return {
      statusCode: 302,
      headers: {
        Location: redirectUrl,
        'Set-Cookie': [
          `divine_user_id=${userProfile.id}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${expires_in}`,
          `divine_psid=${psid || ''}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${expires_in}`
        ].join(', ')
      }
    };

  } catch (error) {
    console.error('❌ OAuth callback error:', error);
    
    return {
      statusCode: 302,
      headers: {
        Location: `${config.baseUrl}?error=auth_failed&message=${encodeURIComponent(error.message)}`
      }
    };
  }
};