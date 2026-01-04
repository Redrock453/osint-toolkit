#!/bin/bash
# OSINT Toolkit - Initial Target Reconnaissance
# Usage: ./initial_recon.sh <target_domain>
# Example: ./initial_recon.sh example.com

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

# Check if target is provided
if [ -z "$TARGET" ]; then
    echo -e "${RED}Error: No target specified${NC}"
    echo "Usage: $0 <target_domain>"
    echo "Example: $0 example.com"
    exit 1
fi

# Create target directory
TARGET_DIR="${RESULTS_DIR}/${TARGET}"
mkdir -p "$TARGET_DIR"
mkdir -p "${LOG_DIR}"

LOG_FILE="${LOG_DIR}/recon_${TARGET}_$(date +%Y%m%d_%H%M%S).log"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}OSINT Toolkit - Initial Reconnaissance${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Target: ${GREEN}${TARGET}${NC}"
echo -e "Started: ${YELLOW}$(date)${NC}"
echo ""

# Log everything
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Function: Check if tool is installed
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}✗ $1 not found. Installing...${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 found${NC}"
        return 0
    fi
}

# Function: Run theHarvester
run_theharvester() {
    echo -e "\n${BLUE}[1/4] Running theHarvester...${NC}"
    echo "Harvesting emails, subdomains, and hosts..."

    if check_tool "theHarvester"; then
        theHarvester -d "$TARGET" -l 500 -b all \
            -f "${TARGET_DIR}/theharvester_output.html" \
            -h "${TARGET_DIR}/theharvester_hosts.txt" \
            -e "${TARGET_DIR}/theharvester_emails.txt" \
            2>&1 | grep -v "DEBUG" || true

        # Parse results
        if [ -f "${TARGET_DIR}/theharvester_hosts.txt" ]; then
            HOST_COUNT=$(wc -l < "${TARGET_DIR}/theharvester_hosts.txt")
            echo -e "${GREEN}✓ Found $HOST_COUNT hosts${NC}"
        fi

        if [ -f "${TARGET_DIR}/theharvester_emails.txt" ]; then
            EMAIL_COUNT=$(wc -l < "${TARGET_DIR}/theharvester_emails.txt")
            echo -e "${GREEN}✓ Found $EMAIL_COUNT emails${NC}"
        fi
    else
        echo -e "${YELLOW}⊘ theHarvester not available, skipping...${NC}"
    fi
}

# Function: Run SpiderFoot
run_spiderfoot() {
    echo -e "\n${BLUE}[2/4] Running SpiderFoot scan...${NC}"
    echo "Starting comprehensive OSINT scan..."

    # Check if SpiderFoot is running
    if ! curl -s http://127.0.0.1:5001 > /dev/null; then
        echo -e "${YELLOW}Starting SpiderFoot server...${NC}"
        docker start osint-spiderfoot 2>/dev/null || true
        sleep 5
    fi

    # Use SpiderFoot CLI if available
    if command -v sfcli &> /dev/null; then
        echo "Scanning with SpiderFoot CLI..."
        sfcli -s "$TARGET" -m all \
            -o "${TARGET_DIR}/spiderfoot_report.json" \
            --report html \
            --output-file "${TARGET_DIR}/spiderfoot_report.html" \
            2>&1 | grep -v "DEBUG" || true

        echo -e "${GREEN}✓ SpiderFoot scan complete${NC}"
    else
        echo -e "${YELLOW}⊘ SpiderFoot CLI not found, use web UI at http://localhost:5001${NC}"
        echo "Or install with: pip install spiderfoot"
    fi
}

# Function: Run Recon-ng
run_recon_ng() {
    echo -e "\n${BLUE}[3/4] Running Recon-ng...${NC}"
    echo "Performing deep reconnaissance..."

    if check_tool "recon-ng"; then
        # Create Recon-ng script
        cat > /tmp/recon_script.rc << EOF
workspaces create ${TARGET}
db insert domains ${TARGET}
markets run
recon/companies-domains
recon/contacts-credentials
recon/hosts-hosts
recon/locations-gps
db dump ${TARGET_DIR}/reconng_dump.json
workspaces select ${TARGET}
report generate ${TARGET_DIR}/reconng_report.html
EOF

        recon-ng -r /tmp/recon_script.rc 2>&1 | grep -v "DEBUG" || true
        rm -f /tmp/recon_script.rc

        echo -e "${GREEN}✓ Recon-ng scan complete${NC}"
    else
        echo -e "${YELLOW}⊘ Recon-ng not available, skipping...${NC}"
    fi
}

# Function: DNS enumeration with additional tools
run_dns_enum() {
    echo -e "\n${BLUE}[4/4] DNS enumeration...${NC}"

    # Basic DNS lookup
    echo "A records:"
    dig +short "$TARGET" A | tee -a "${TARGET_DIR}/dns_a_records.txt"

    echo -e "\nMX records:"
    dig +short "$TARGET" MX | tee -a "${TARGET_DIR}/dns_mx_records.txt"

    echo -e "\nTXT records:"
    dig +short "$TARGET" TXT | tee -a "${TARGET_DIR}/dns_txt_records.txt"

    echo -e "\nNS records:"
    dig +short "$TARGET" NS | tee -a "${TARGET_DIR}/dns_ns_records.txt"

    # Subdomain enumeration with dnsx if available
    if command -v dnsx &> /dev/null; then
        echo -e "\nSubdomain enumeration:"
        echo "$TARGET" | dnsx -silent -responly -o "${TARGET_DIR}/dnsx_subdomains.txt" 2>&1 || true
        SUB_COUNT=$(wc -l < "${TARGET_DIR}/dnsx_subdomains.txt" 2>/dev/null || echo "0")
        echo -e "${GREEN}✓ Found $SUB_COUNT subdomains${NC}"
    fi

    echo -e "${GREEN}✓ DNS enumeration complete${NC}"
}

# Function: Generate summary report
generate_summary() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}Generating Summary Report${NC}"
    echo -e "${BLUE}======================================${NC}"

    cat > "${TARGET_DIR}/summary.txt" << EOF
========================================
OSINT RECONNAISSANCE SUMMARY
========================================

Target: $TARGET
Scan Date: $(date)
Scan Type: Initial Reconnaissance

========================================
RESULTS SUMMARY
========================================

EOF

    # Add counts from various files
    if [ -f "${TARGET_DIR}/theharvester_hosts.txt" ]; then
        echo "Hosts found: $(wc -l < "${TARGET_DIR}/theharvester_hosts.txt")" >> "${TARGET_DIR}/summary.txt"
    fi

    if [ -f "${TARGET_DIR}/theharvester_emails.txt" ]; then
        echo "Emails found: $(wc -l < "${TARGET_DIR}/theharvester_emails.txt")" >> "${TARGET_DIR}/summary.txt"
    fi

    if [ -f "${TARGET_DIR}/dnsx_subdomains.txt" ]; then
        echo "Subdomains found: $(wc -l < "${TARGET_DIR}/dnsx_subdomains.txt")" >> "${TARGET_DIR}/summary.txt"
    fi

    cat >> "${TARGET_DIR}/summary.txt" << EOF

========================================
GENERATED FILES
========================================

EOF

    ls -lh "$TARGET_DIR" >> "${TARGET_DIR}/summary.txt"

    cat >> "${TARGET_DIR}/summary.txt" << EOF

========================================
NEXT STEPS
========================================

1. Review theHarvester results:
   - theharvester_output.html
   - theharvester_hosts.txt
   - theharvester_emails.txt

2. Check SpiderFoot report:
   - spiderfoot_report.html

3. Analyze Recon-ng data:
   - reconng_report.html
   - reconng_dump.json

4. Review DNS records:
   - dns_*_records.txt

5. Run additional scans:
   - ./scripts/leak_check.sh $TARGET
   - ./scripts/forum_monitor.sh "$TARGET"

========================================
END OF REPORT
========================================

EOF

    echo -e "${GREEN}✓ Summary report generated${NC}"
    cat "${TARGET_DIR}/summary.txt"
}

# Main execution
main() {
    echo -e "${BLUE}Starting comprehensive reconnaissance on ${TARGET}...${NC}"

    run_theharvester
    run_spiderfoot
    run_recon_ng
    run_dns_enum
    generate_summary

    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}✓ Reconnaissance Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo -e "Results saved to: ${YELLOW}${TARGET_DIR}${NC}"
    echo -e "Log file: ${YELLOW}${LOG_FILE}${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. Review results: ${BLUE}cat ${TARGET_DIR}/summary.txt${NC}"
    echo -e "  2. Check for leaks: ${BLUE}./scripts/leak_check.sh ${TARGET}${NC}"
    echo -e "  3. Monitor forums: ${BLUE}./scripts/forum_monitor.sh \"${TARGET}\"${NC}"
    echo ""
}

# Run main function
main
