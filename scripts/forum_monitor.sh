#!/bin/bash
# OSINT Toolkit - Forum & Social Media Monitoring
# Usage: ./forum_monitor.sh "keyword" [hours_back]
# Example: ./forum_monitor.sh "target company" 24

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_DIR}/data/results"
LOG_DIR="${PROJECT_DIR}/data/logs"
KEYWORD="$1"
HOURS_BACK="${2:-24}"

# Load environment variables
if [ -f "${PROJECT_DIR}/.env" ]; then
    source "${PROJECT_DIR}/.env"
fi

# Check if keyword is provided
if [ -z "$KEYWORD" ]; then
    echo -e "${RED}Error: No keyword specified${NC}"
    echo "Usage: $0 <keyword> [hours_back]"
    echo ""
    echo "Examples:"
    echo "  $0 \"target company\" 24"
    echo "  $0 \"username\" 168"
    echo "  $0 \"vulnerability\" 6"
    exit 1
fi

# Create target directory
KEYWORD_SAFE=$(echo "$KEYWORD" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
TARGET_DIR="${RESULTS_DIR}/forums/${KEYWORD_SAFE}"
mkdir -p "$TARGET_DIR"
mkdir -p "${LOG_DIR}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/forum_monitor_${KEYWORD_SAFE}_${TIMESTAMP}.log"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}OSINT Toolkit - Forum Monitoring${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Keyword: ${GREEN}${KEYWORD}${NC}"
echo -e "Time range: ${YELLOW}last ${HOURS_BACK} hours${NC}"
echo -e "Started: ${YELLOW}$(date)${NC}"
echo ""

# Log everything
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Function: Check if tool is installed
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}✗ $1 not found${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 found${NC}"
        return 0
    fi
}

# Function: Monitor Reddit
monitor_reddit() {
    echo -e "\n${BLUE}[1/4] Monitoring Reddit...${NC}"

    if [ -n "$REDDIT_CLIENT_ID" ] && [ -n "$REDDIT_CLIENT_SECRET" ]; then
        echo "Searching Reddit for: $KEYWORD"

        # Use Reddit API if credentials available
        if command -v curl &> /dev/null; then
            # Get access token
            TOKEN=$(curl -s -X POST -u "${REDDIT_CLIENT_ID}:${REDDIT_CLIENT_SECRET}" \
                -d "grant_type=client_credentials" \
                https://www.reddit.com/api/v1/access_token | jq -r '.access_token')

            if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
                # Search Reddit
                curl -s -H "Authorization: bearer $TOKEN" \
                    -H "User-Agent: $REDDIT_USER_AGENT" \
                    "https://oauth.reddit.com/search?q=$(echo "$KEYWORD" | jq -sRr @uri)&t=${HOURS_BACK}h&limit=100" \
                    -o "${TARGET_DIR}/reddit_results.json" 2>&1 || true

                # Parse results
                if [ -f "${TARGET_DIR}/reddit_results.json" ]; then
                    POST_COUNT=$(jq '.data.children | length' "${TARGET_DIR}/reddit_results.json" 2>/dev/null || echo "0")
                    echo -e "${GREEN}✓ Found $POST_COUNT Reddit posts${NC}"

                    if [ "$POST_COUNT" -gt 0 ]; then
                        # Extract post titles and URLs
                        jq -r '.data.children[] | .data.title + " | " + .data.permalink' \
                            "${TARGET_DIR}/reddit_results.json" > "${TARGET_DIR}/reddit_posts.txt" 2>/dev/null || true

                        echo -e "${YELLOW}Top mentions:${NC}"
                        head -5 "${TARGET_DIR}/reddit_posts.txt" | while read line; do
                            echo "  - $line"
                        done
                    fi
                fi
            else
                echo -e "${YELLOW}⊘ Failed to get Reddit access token${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⊘ Reddit API credentials not set${NC}"
        echo "  Add REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET to .env"
        echo "  Create app at: https://www.reddit.com/prefs/apps"
    fi

    # Provide manual search link
    echo -e "\n${BLUE}Manual search:${NC}"
    echo "  https://www.reddit.com/search?q=$(echo "$KEYWORD" | jq -sRr @uri)&t=${HOURS_BACK}h"
}

# Function: Monitor 4chan (via archives)
monitor_4chan() {
    echo -e "\n${BLUE}[2/4] Monitoring 4chan archives...${NC}"

    if command -v curl &> /dev/null; then
        echo "Searching 4chan archives for: $KEYWORD"

        # Search archived.moe (4chan archive)
        curl -s "https://archived.moe/_/search/boards/*/text/$(echo "$KEYWORD" | jq -sRr @uri)/" \
            -H "User-Agent: OSINT-Toolkit" \
            -o "${TARGET_DIR}/4chan_archived.json" 2>&1 || true

        # Parse results
        if [ -f "${TARGET_DIR}/4chan_archived.json" ]; then
            POST_COUNT=$(jq '. | length' "${TARGET_DIR}/4chan_archived.json" 2>/dev/null || echo "0")
            echo -e "${GREEN}✓ Found $POST_COUNT 4chan posts${NC}"

            if [ "$POST_COUNT" -gt 0 ]; then
                echo -e "${YELLOW}Recent posts found${NC}"
            fi
        fi

        # Also search Fireden (another archive)
        curl -s "https://desuarchive.org/_/search/boards/*/text/$(echo "$KEYWORD" | jq -sRr @uri)/" \
            -H "User-Agent: OSINT-Toolkit" \
            -o "${TARGET_DIR}/4chan_desuarchive.json" 2>&1 || true
    fi

    # Manual search links
    echo -e "\n${BLUE}Manual search:${NC}"
    echo "  https://archived.moe/_/search/text/$(echo "$KEYWORD" | jq -sRr @uri)/"
    echo "  https://desuarchive.org/_/search/text/$(echo "$KEYWORD" | jq -sRr @uri)/"
}

# Function: Monitor paste sites
monitor_paste_sites() {
    echo -e "\n${BLUE}[3/4] Monitoring paste sites...${NC}"

    if command -v curl &> /dev/null; then
        echo "Searching paste sites for: $KEYWORD"

        # Search Pastebin (via Google dork - limited API)
        echo "  Pastebin: https://pastebin.com/archive/search?q=$(echo "$KEYWORD" | jq -sRr @uri)"

        # Search JustPaste.it
        curl -s "https://justpaste.it/api/search?q=$(echo "$KEYWORD" | jq -sRr @uri)" \
            -H "User-Agent: OSINT-Toolkit" \
            -o "${TARGET_DIR}/justpaste_results.json" 2>&1 || true

        # Search Pastebin.com manually (no API for search)
        echo "  JustPaste.it: https://justpaste.it/search?q=$(echo "$KEYWORD" | jq -sRr @uri)"
    fi

    echo -e "${YELLOW}⊘ Manual review required for most paste sites${NC}"
}

# Function: Monitor dark web forums (via Tor)
monitor_darkweb() {
    echo -e "\n${BLUE}[4/4] Monitoring dark web forums...${NC}"

    # Check Tor connection
    if curl -s --socks5 127.0.0.1:9050 --connect-timeout 5 https://check.torproject.org/ | grep -q "Congratulations"; then
        echo -e "${GREEN}✓ Tor connection established${NC}"

        echo -e "${YELLOW}Dark web forums (manual review required):${NC}"
        echo "  - Dread (Reddit clone): http://dreadxer7ccooer...onion"
        echo "  - Intel Exchange: http://xqzf3w5e...onion"
        echo "  - Other forums: See directories below"

        echo -e "\n${BLUE}Dark web directories:${NC}"
        echo "  - http://darkweblinks7izl...onion (hidden wiki)"
        echo "  - http://onionsnzajfnf6u...onion (another directory)"

    else
        echo -e "${YELLOW}⊘ Tor not available, starting Tor service...${NC}"
        docker start osint-tor 2>/dev/null || true
        sleep 5
        monitor_darkweb
    fi
}

# Function: Generate summary report
generate_summary() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}Forum Monitoring Summary${NC}"
    echo -e "${BLUE}======================================${NC}"

    cat > "${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt" << EOF
========================================
FORUM MONITORING SUMMARY
========================================

Keyword: $KEYWORD
Time Range: Last ${HOURS_BACK} hours
Scan Date: $(date)

========================================
SOURCES MONITORED
========================================

1. Reddit - Social discussions
2. 4chan Archives - Anonymous image boards
3. Paste Sites - Public paste bins
4. Dark Web - Tor hidden services

========================================
FINDINGS SUMMARY
========================================

EOF

    # Count findings from each source
    REDDIT_COUNT=$(jq '.data.children | length' "${TARGET_DIR}/reddit_results.json" 2>/dev/null || echo "0")
    FOURCHAN_COUNT=$(jq '. | length' "${TARGET_DIR}/4chan_archived.json" 2>/dev/null || echo "0")

    echo "Reddit mentions: $REDDIT_COUNT" >> "${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt"
    echo "4chan mentions: $FOURCHAN_COUNT" >> "${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt"
    echo "Paste sites: Manual review required" >> "${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt"
    echo "Dark web: Manual review required" >> "${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt"

    cat >> "${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt" << EOF

========================================
RECOMMENDATIONS
========================================

1. Review automated findings above
2. Manually check paste sites for new mentions
3. Use Tor Browser to access dark web forums
4. Set up continuous monitoring for critical keywords
5. Configure alerts for new mentions

========================================
CONTINUOUS MONITORING
========================================

To monitor this keyword continuously, add to crontab:

# Check every hour
0 * * * * ${SCRIPT_DIR}/forum_monitor.sh "${KEYWORD}" 1

# Check every 6 hours
0 */6 * * * ${SCRIPT_DIR}/forum_monitor.sh "${KEYWORD}" 6

# Check daily
0 2 * * * ${SCRIPT_DIR}/forum_monitor.sh "${KEYWORD}" 24

========================================
MANUAL SEARCH LINKS
========================================

Reddit:
https://www.reddit.com/search?q=${KEYWORD}

4chan Archives:
https://archived.moe/_/search/text/${KEYWORD}/

Paste Sites:
https://pastebin.com/archive/search?q=${KEYWORD}
https://justpaste.it/search?q=${KEYWORD}

Google Dorks:
site:reddit.com "${KEYWORD}"
site:4chan.org "${KEYWORD}"
site:pastebin.com "${KEYWORD}"

========================================
END OF REPORT
========================================

EOF

    echo -e "${GREEN}✓ Summary report generated${NC}"
    cat "${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt"
}

# Main execution
main() {
    echo -e "${BLUE}Starting forum monitoring for keyword: ${KEYWORD}${NC}"

    monitor_reddit
    monitor_4chan
    monitor_paste_sites
    monitor_darkweb
    generate_summary

    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}✓ Forum Monitoring Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo -e "Results saved to: ${YELLOW}${TARGET_DIR}${NC}"
    echo -e "Log file: ${YELLOW}${LOG_FILE}${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. Review findings: ${BLUE}cat ${TARGET_DIR}/forum_summary_${TIMESTAMP}.txt${NC}"
    echo -e "  2. Check JSON results: ${BLUE}ls -la ${TARGET_DIR}/*.json${NC}"
    echo -e "  3. Set up alerts: ${BLUE}crontab -e${NC}"
    echo ""
}

# Run main function
main
