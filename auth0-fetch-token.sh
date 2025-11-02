#!/usr/bin/env bash
# auth0-fetch-token.sh
# Safely fetch an Auth0 client_credentials (M2M) access token.
# - Validates required env vars
# - Avoids echoing tokens to stdout
# - Optionally writes token to a restricted file (for short-lived use)
# Usage:
#   export AUTH0_DOMAIN=...
#   export AUTH0_CLIENT_ID=...
#   export AUTH0_CLIENT_SECRET=...
#   export AUTH0_AUDIENCE=...
#   ./auth0-fetch-token.sh          # prints only success/failure
#   TOKEN_FILE=.auth0_token ./auth0-fetch-token.sh   # writes token to file with 0600 perms

set -euo pipefail

: "${AUTH0_DOMAIN:?AUTH0_DOMAIN must be set (e.g. dev-xxx.us.auth0.com)}"
: "${AUTH0_CLIENT_ID:?AUTH0_CLIENT_ID must be set}"
: "${AUTH0_CLIENT_SECRET:?AUTH0_CLIENT_SECRET must be set}"
: "${AUTH0_AUDIENCE:?AUTH0_AUDIENCE must be set}"

TOKEN_FILE="${TOKEN_FILE:-}"

RESP=$(curl -sS -X POST "https://${AUTH0_DOMAIN}/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{\"client_id\":\"${AUTH0_CLIENT_ID}\",\"client_secret\":\"${AUTH0_CLIENT_SECRET}\",\"audience\":\"${AUTH0_AUDIENCE}\",\"grant_type\":\"client_credentials\"}")

if [ -z "$RESP" ]; then
  echo "ERROR: Empty response from Auth0" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not found. Install jq and retry." >&2
  exit 1
fi

ACCESS_TOKEN=$(echo "$RESP" | jq -r '.access_token // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  ERROR_MSG=$(echo "$RESP" | jq -r '.error_description // .error // empty')
  echo "ERROR: Failed to obtain access token from Auth0. ${ERROR_MSG}" >&2
  exit 1
fi

if [ -n "$TOKEN_FILE" ]; then
  umask 077
  printf "%s" "$ACCESS_TOKEN" > "${TOKEN_FILE}"
  chmod 600 "${TOKEN_FILE}"
  echo "Token saved to ${TOKEN_FILE} (0600). Ensure this file is in .gitignore and deleted after use."
else
  export AUTH0_ACCESS_TOKEN="${ACCESS_TOKEN}"
  printf "SUCCESS: Access token retrieved and exported into AUTH0_ACCESS_TOKEN for this process.\n"
fi

exit 0
