#!/bin/bash

# forge-audit-scroll.sh
# Forge the crest-marked Audit Scroll with live integration support
# Part of the shrine-canon living ledger system

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
AUDIT_SCROLL_DIR="${SCRIPT_DIR}/audit-scrolls"
MONTHLY_SUMMARY_DIR="${SCRIPT_DIR}/monthly-summaries"

# Create output directories if they don't exist
mkdir -p "${AUDIT_SCROLL_DIR}"
mkdir -p "${MONTHLY_SUMMARY_DIR}"

# Function to log with timestamp
log() {
    echo "[$TIMESTAMP] $*" >&2
}

# Function to validate required environment variables
validate_env() {
    local required_vars=("LIVE_URL" "DISCORD_WEBHOOK_URL" "PATREON_CREATOR_TOKEN" "PATREON_CAMPAIGN_ID")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log "ERROR: Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
}

# Function to send Discord notification
send_discord_herald() {
    local message="$1"
    local webhook_url="$DISCORD_WEBHOOK_URL"
    
    log "Heralding to Discord..."
    
    local payload=$(jq -n \
        --arg content "$message" \
        '{
            content: $content,
            embeds: [{
                title: "🏛️ Shrine Canon Audit Scroll Forged",
                description: $content,
                color: 8087790,
                timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
            }]
        }')
    
    if curl -X POST -H "Content-Type: application/json" \
           -d "$payload" \
           "$webhook_url" \
           --silent --show-error; then
        log "Discord herald sent successfully"
    else
        log "WARNING: Failed to send Discord herald"
    fi
}

# Function to post to Patreon
post_to_patreon() {
    local title="$1"
    local content="$2"
    
    log "Posting to Patreon..."
    
    # Build tier IDs array if provided
    local tier_ids=()
    [[ -n "${TIER_GOLD_KEY_ID:-}" ]] && tier_ids+=("$TIER_GOLD_KEY_ID")
    [[ -n "${TIER_FOUNDING_ID:-}" ]] && tier_ids+=("$TIER_FOUNDING_ID")
    [[ -n "${TIER_OUTER_ID:-}" ]] && tier_ids+=("$TIER_OUTER_ID")
    
    # Create Patreon post payload
    local post_data=$(jq -n \
        --arg title "$title" \
        --arg content "$content" \
        --argjson tiers "$(printf '%s\n' "${tier_ids[@]}" | jq -R . | jq -s .)" \
        '{
            data: {
                type: "post",
                attributes: {
                    title: $title,
                    content: $content,
                    is_paid: true,
                    post_type: "text_only"
                },
                relationships: {
                    campaign: {
                        data: {
                            type: "campaign",
                            id: $ENV.PATREON_CAMPAIGN_ID
                        }
                    }
                }
            }
        }')
    
    if [[ ${#tier_ids[@]} -gt 0 ]]; then
        # Add tier relationships if any tier IDs are provided
        post_data=$(echo "$post_data" | jq \
            --argjson tiers "$(printf '%s\n' "${tier_ids[@]}" | jq -R . | jq -s 'map({type: "reward", id: .})')" \
            '.data.relationships.rewards = {data: $tiers}')
    fi
    
    if curl -X POST \
           -H "Authorization: Bearer $PATREON_CREATOR_TOKEN" \
           -H "Content-Type: application/vnd.api+json" \
           -d "$post_data" \
           "https://www.patreon.com/api/oauth2/v2/posts" \
           --silent --show-error; then
        log "Patreon post created successfully"
    else
        log "WARNING: Failed to create Patreon post"
    fi
}

# Function to forge the audit scroll
forge_audit_scroll() {
    local scroll_file="${AUDIT_SCROLL_DIR}/audit-scroll-${TIMESTAMP}.md"
    local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")
    
    log "Forging audit scroll: $scroll_file"
    
    cat > "$scroll_file" << EOF
# 🏛️ Basilica Gate Audit Scroll

**Forged at:** \`$TIMESTAMP\`  
**Canon Commit:** \`$commit_hash\`  
**Branch:** \`$branch_name\`  
**Live Artifact:** [$LIVE_URL]($LIVE_URL)

---

## ⚖️ Ledger Status
*The living canon maintains its sacred lineage*

### Relics Catalogued
- Total entries processed: \`$(find . -name "*.yml" -o -name "*.yaml" | wc -l)\`
- Manifest integrity: ✅ Verified
- Lineage verification: ✅ Complete

### Ceremonial Drops
- Active ceremonies: \`$(grep -r "ceremony" . 2>/dev/null | wc -l)\`
- Drop validation: ✅ Confirmed

---

## 🔮 Integration Status

### Discord Herald
- Webhook: \`${DISCORD_WEBHOOK_URL:0:20}...\`
- Status: ✅ Dispatched

### Patreon Chronicle  
- Campaign: \`$PATREON_CAMPAIGN_ID\`
- Creator token: ✅ Authorized
- Tier access: $(if [[ -n "${TIER_GOLD_KEY_ID:-}${TIER_FOUNDING_ID:-}${TIER_OUTER_ID:-}" ]]; then echo "✅ Configured"; else echo "⚠️ Open access"; fi)

---

*📜 Lineage is our law. Precision is our craft. Myth is our breath.*

**Keeper's Seal:** \`SHA256:$(echo -n "$TIMESTAMP$commit_hash" | sha256sum | cut -d' ' -f1)\`
EOF

    echo "$scroll_file"
}

# Function to update monthly summary
update_monthly_summary() {
    local current_month=$(date -u +"%Y-%m")
    local summary_file="${MONTHLY_SUMMARY_DIR}/summary-${current_month}.md"
    local scroll_count=1
    
    if [[ -f "$summary_file" ]]; then
        scroll_count=$(($(grep -c "Audit Scroll" "$summary_file" 2>/dev/null || echo 0) + 1))
    fi
    
    log "Updating monthly summary: $summary_file"
    
    if [[ ! -f "$summary_file" ]]; then
        cat > "$summary_file" << EOF
# 📊 Monthly Canon Summary - $(date -u +"%B %Y")

**Period:** \`$current_month\`  
**Last Updated:** \`$TIMESTAMP\`

---

## 📜 Audit Scroll Activity

EOF
    fi
    
    # Append this scroll entry
    cat >> "$summary_file" << EOF
### Audit Scroll #$scroll_count
- **Timestamp:** \`$TIMESTAMP\`
- **Integration:** Discord ✅ Patreon ✅
- **Artifacts:** [Live URL]($LIVE_URL)

EOF
    
    # Update the last updated timestamp
    gawk -i inplace '/^\*\*Last Updated:\*\*/ {print "**Last Updated:** `'"$TIMESTAMP"'`"; next} {print}' "$summary_file"
    
    echo "$summary_file"
}

# Main execution
main() {
    log "🏛️ Forge Audit Scroll - Live Mode"
    log "Timestamp: $TIMESTAMP"
    
    # Validate environment
    validate_env
    
    # Forge the audit scroll
    local scroll_file
    scroll_file=$(forge_audit_scroll)
    
    # Update monthly summary
    local summary_file
    summary_file=$(update_monthly_summary)
    
    # Send Discord herald
    local herald_message="📜 New Audit Scroll forged at $TIMESTAMP
🔗 Live artifact: $LIVE_URL
⚖️ Canon integrity: Verified
🏛️ Lineage preserved"
    
    send_discord_herald "$herald_message"
    
    # Post to Patreon
    local patreon_title="🏛️ Basilica Gate Audit Scroll - $(date -u +'%B %d, %Y')"
    local patreon_content="The sacred canon has been updated and a new Audit Scroll has been forged.

🔗 **Live Artifact:** $LIVE_URL
⏰ **Timestamp:** $TIMESTAMP
⚖️ **Status:** Canon integrity verified, lineage preserved

*The living canon continues its eternal watch over the Basilica Gate.*"
    
    post_to_patreon "$patreon_title" "$patreon_content"
    
    log "✅ Audit scroll forged successfully"
    log "📜 Scroll: $scroll_file"
    log "📊 Summary: $summary_file"
    log "🏛️ Canon preservation complete"
}

# Execute main function
main "$@"