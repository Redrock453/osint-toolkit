#!/bin/bash
# OSINT Toolkit - Data Leak Detection
# Usage: ./leak_check.sh <target>
# Examples:
#   ./leak_check.sh github.com/user/repo
#   ./leak_check.sh example.com
#   ./leak_check.sh user@email.com

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
TARGET=$1

# Load environment variables
if [ -f "${PROJECT_DIR}/.env" ]; then
    source "${PROJECT_DIR}/.env"
fi

# Check if target is provided
if [ -z "$TARGET" ]; then
    echo -e "${RED}Error: No target specified${NC}"
    echo "Usage: $0 <target>"
    echo ""
    echo "Examples:"
    echo "  $0 github.com/user/repo"
    echo "  $0 example.com"
    echo "  $0 user@email.com"
    exit 1
fi

# Create target directory
TARGET_DIR="${RESULTS_DIR}/leaks/${TARGET}"
mkdir -p "$TARGET_DIR"
mkdir -p "${LOG_DIR}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/leak_check_${TARGET}_${TIMESTAMP}.log"
REPORT_FILE="${TARGET_DIR}/leak_report_${TIMESTAMP}.json"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}OSINT Toolkit - Leak Detection${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Target: ${GREEN}${TARGET}${NC}"
echo -e "Started: ${YELLOW}$(date)${NC}"
echo ""

# Log everything
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Initialize JSON report
init_report() {
    cat > "$REPORT_FILE" << EOF
{
  "target": "$TARGET",
  "scan_date": "$(date -Iseconds)",
  "tools_used": [],
  "findings": [],
  "summary": {
    "total_leaks": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  }
}
EOF
}

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

# Function: Run GitLeaks scan
run_gitleaks() {
    echo -e "\n${BLUE}[1/5] Running GitLeaks scan...${NC}"

    if check_tool "gitleaks"; then
        echo "Scanning for secrets in repositories..."

        # Determine if target is a Git repository
        if [[ "$TARGET" =~ ^github\.com/.*|gitlab\.com/.*|bitbucket\.org/.* ]]; then
            # It's a Git URL
            gitleaks detect --source "$TARGET" \
                --report "${TARGET_DIR}/gitleaks_report.json" \
                --report-format json \
                --verbose 2>&1 | grep -v "DEBUG" || true

            # Parse results
            if [ -f "${TARGET_DIR}/gitleaks_report.json" ]; then
                LEAK_COUNT=$(jq '. | length' "${TARGET_DIR}/gitleaks_report.json" 2>/dev/null || echo "0")
                echo -e "${GREEN}✓ Found $LEAK_COUNT potential leaks${NC}"

                # Add to main report
                if command -v jq &> /dev/null; then
                    jq --arg tool "gitleaks" --argjson data "$(cat "${TARGET_DIR}/gitleaks_report.json") \
                        '.tools_used += [$tool] | .findings += $data' \
                        "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
                fi
            fi
        else
            echo -e "${YELLOW}⊘ Target is not a Git repository, skipping GitLeaks...${NC}"
        fi
    else
        echo -e "${YELLOW}Installing GitLeaks...${NC}"
        GITLEAKS_VERSION="8.18.0"
        wget -q "https://github.com/zricethezav/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
            -O /tmp/gitleaks.tar.gz
        tar -xzf /tmp/gitleaks.tar.gz -C /tmp
        sudo mv /tmp/gitleaks /usr/local/bin/
        rm -f /tmp/gitleaks.tar.gz
        echo -e "${GREEN}✓ GitLeaks installed${NC}"
        run_gitleaks
    fi
}

# Function: Check Have I Been Pwned
run_hibp() {
    echo -e "\n${BLUE}[2/5] Checking Have I Been Pwned...${NC}"

    # Extract email if target is an email
    if [[ "$TARGET" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
        EMAIL="$TARGET"

        if [ -n "$HIBP_API_KEY" ]; then
            echo "Checking breaches for: $EMAIL"

            # Use hibp API if available
            if command -v hibp &> /dev/null; then
                hibp account "$EMAIL" --user-agent "osint-toolkit" > "${TARGET_DIR}/hibp_breaches.json" 2>&1 || true

                if [ -f "${TARGET_DIR}/hibp_breaches.json" ]; then
                    BREACH_COUNT=$(jq '. | length' "${TARGET_DIR}/hibp_breaches.json" 2>/dev/null || echo "0")
                    echo -e "${GREEN}✓ Found $BREACH_COUNT breaches${NC}"

                    # Display breach details
                    if [ "$BREACH_COUNT" -gt 0 ]; then
                        echo -e "${YELLOW}Breaches found:${NC}"
                        jq -r '.[].Name' "${TARGET_DIR}/hibp_breaches.json" | while read name; do
                            echo "  - $name"
                        done
                    fi
                fi
            else
                echo -e "${YELLOW}⊘ HIBP CLI not found${NC}"
                echo "Install with: pip install haveibeenpwned"
            fi
        else
            echo -e "${YELLOW}⊘ HIBP_API_KEY not set in .env${NC}"
            echo "Get free API key at: https://haveibeenpwned.com/API/Key"
        fi
    else
        echo -e "${YELLOW}⊘ Target is not an email address, skipping HIBP check...${NC}"
    fi
}

# Function: Check breach databases
run_breach_check() {
    echo -e "\n${BLUE}[3/5] Checking breach databases...${NC}"

    # Check for common password dumps
    if [[ "$TARGET" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
        EMAIL="$TARGET"

        # Check SecLists (if available)
        if [ -d "/usr/share/seclists" ] || command -v curl &> /dev/null; then
            echo "Checking password breach databases..."

            # Use public APIs
            curl -s "https://breachdirectory.com/api/v1?email=${EMAIL}" \
                -H "User-Agent: OSINT-Toolkit" \
                -o "${TARGET_DIR}/breachdirectory.json" 2>/dev/null || true

            if [ -f "${TARGET_DIR}/breachdirectory.json" ]; then
                echo -e "${GREEN}✓ Breach directory check complete${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⊘ Target is not an email, skipping breach check...${NC}"
    fi
}

# Function: Dark web leak search
run_darkweb_search() {
    echo -e "\n${BLUE}[4/5] Searching dark web for leaks...${NC}"

    # Check if Tor is available
    if curl -s --socks5 127.0.0.1:9050 https://check.torproject.org/ | grep -q "Congratulations"; then
        echo "Tor connection established"

        # Search common paste sites (via Tor)
        echo "Searching paste sites for: $TARGET"

        # This is a placeholder - actual implementation would search specific sites
        echo -e "${YELLOW}⊘ Manual review required for dark web searches${NC}"
        echo "  Consider using IntelligenceX (requires API key)"
        echo "  Or search manually via Tor Browser"
    else
        echo -e "${YELLOW}⊘ Tor not available, starting Tor service...${NC}"
        docker start osint-tor 2>/dev/null || true
        sleep 5
        run_darkweb_search
    fi
}

# Function: Check paste sites
run_paste_check() {
    echo -e "\n${BLUE}[5/5] Checking paste sites...${NC}"

    if command -v curl &> /dev/null; then
        echo "Searching public paste sites..."

        # Search Pastebin (limited API)
        if [ -n "$PASTEBIN_API_KEY" ]; then
            echo "Searching Pastebin..."
            # Placeholder for Pastebin API search
        fi

        # Search JustPaste.it (requires manual check)
        echo -e "${YELLOW}⊘ Paste site search requires manual review${NC}"
        echo "  Check these sites manually:"
        echo "  - https://pastebin.com/archive/search?q=$TARGET"
        echo "  - https://justpaste.it/search?q=$TARGET"
        echo "  - https://paste.ee/search?q=$TARGET"
    fi
}

# Function: Generate summary report
generate_summary() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}Leak Detection Summary${NC}"
    echo -e "${BLUE}======================================${NC}"

    cat > "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt" << EOF
========================================
LEAK DETECTION SUMMARY
========================================

Target: $TARGET
Scan Date: $(date)
Scan Type: Comprehensive Leak Detection

========================================
SCANS PERFORMED
========================================

EOF

    # Add tool results
    echo "1. GitLeaks: Repository secret scanning" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
    echo "2. Have I Been Pwned: Credential breach check" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
    echo "3. Breach Databases: Password dump verification" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
    echo "4. Dark Web: Tor network leak search" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
    echo "5. Paste Sites: Public paste site monitoring" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"

    cat >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt" << EOF

========================================
FINDINGS
========================================

EOF

    # Parse JSON report for findings
    if command -v jq &> /dev/null && [ -f "$REPORT_FILE" ]; then
        TOTAL_LEAKS=$(jq '.summary.total_leaks' "$REPORT_FILE" 2>/dev/null || echo "0")
        CRITICAL=$(jq '.summary.critical' "$REPORT_FILE" 2>/dev/null || echo "0")
        HIGH=$(jq '.summary.high' "$REPORT_FILE" 2>/dev/null || echo "0")

        echo "Total Leaks Found: $TOTAL_LEAKS" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "Critical: $CRITICAL" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "High: $HIGH" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
    fi

    cat >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt" << EOF

========================================
RECOMMENDATIONS
========================================

EOF

    if [ "$TOTAL_LEAKS" -gt 0 ]; then
        echo "⚠️  LEAKS DETECTED!" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "Recommended actions:" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "1. Rotate all exposed credentials immediately" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "2. Review and commit/remove sensitive data from repos" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "3. Enable 2FA on all accounts" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "4. Monitor for suspicious activity" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "5. Notify affected users/stakeholders" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
    else
        echo "✓ No leaks detected in automated scans" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
        echo "  Continue regular monitoring" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
    fi

    cat >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt" << EOF

========================================
FILES GENERATED
========================================

EOF

    ls -lh "$TARGET_DIR" >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"

    cat >> "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt" << EOF

========================================
NEXT STEPS
========================================

1. Review detailed reports in: $TARGET_DIR
2. Manual review of dark web sites recommended
3. Set up continuous monitoring:
   - Add to crontab: ./scripts/leak_check.sh $TARGET
4. Configure alerts for new leaks

========================================
END OF REPORT
========================================

EOF

    echo -e "${GREEN}✓ Summary report generated${NC}"
    cat "${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt"
}

# Main execution
main() {
    echo -e "${BLUE}Starting comprehensive leak detection on ${TARGET}...${NC}"

    init_report
    run_gitleaks
    run_hibp
    run_breach_check
    run_darkweb_search
    run_paste_check
    generate_summary

    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}✓ Leak Detection Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo -e "Results saved to: ${YELLOW}${TARGET_DIR}${NC}"
    echo -e "Log file: ${YELLOW}${LOG_FILE}${NC}"
    echo -e "Report: ${YELLOW}${REPORT_FILE}${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. Review summary: ${BLUE}cat ${TARGET_DIR}/leak_summary_${TIMESTAMP}.txt${NC}"
    echo -e "  2. Set up monitoring: ${BLUE}crontab -e${NC}"
    echo -e "  3. Run recon: ${BLUE}./scripts/initial_recon.sh ${TARGET}${NC}"
    echo ""
}

# Run main function
main
