#!/bin/bash
# OSINT Toolkit - Automated Setup Script
# This script installs and configures all required tools

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}OSINT Toolkit - Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}✗ Don't run as root! Use sudo for individual commands if needed.${NC}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Function: Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function: Install Python packages
install_python_tools() {
    echo -e "\n${BLUE}[1/6] Installing Python tools...${NC}"

    # Check Python version
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "Python version: $PYTHON_VERSION"

    # Install pip if needed
    if ! command_exists pip3; then
        echo "Installing pip..."
        sudo apt-get update -qq
        sudo apt-get install -y python3-pip
    fi

    # Install requirements
    echo "Installing Python packages from requirements.txt..."
    pip3 install --user -r requirements.txt || {
        echo -e "${YELLOW}Some packages failed to install, continuing...${NC}"
    }

    echo -e "${GREEN}✓ Python tools installed${NC}"
}

# Function: Install GitLeaks
install_gitleaks() {
    echo -e "\n${BLUE}[2/6] Installing GitLeaks...${NC}"

    if command_exists gitleaks; then
        echo -e "${GREEN}✓ GitLeaks already installed${NC}"
        gitleaks --version
    else
        echo "Downloading GitLeaks..."

        GITLEAKS_VERSION="8.18.0"
        wget -q --show-progress \
            "https://github.com/zricethezav/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
            -O /tmp/gitleaks.tar.gz

        echo "Extracting..."
        tar -xzf /tmp/gitleaks.tar.gz -C /tmp

        echo "Installing to /usr/local/bin/..."
        sudo mv /tmp/gitleaks /usr/local/bin/
        sudo chmod +x /usr/local/bin/gitleaks

        rm -f /tmp/gitleaks.tar.gz

        echo -e "${GREEN}✓ GitLeaks installed${NC}"
        gitleaks --version
    fi
}

# Function: Install additional tools
install_additional_tools() {
    echo -e "\n${BLUE}[3/6] Installing additional tools...${NC}"

    # Install system packages
    echo "Installing system packages..."

    sudo apt-get update -qq

    # Core tools
    sudo apt-get install -y \
        dnsutils \
        curl \
        wget \
        git \
        jq \
        tor \
        torsocks \
        docker.io \
        docker-compose \
        python3-dev \
        build-essential \
        libssl-dev \
        libffi-dev \
        python3-venv

    # Install dnsx (subdomain enumeration)
    if ! command_exists dnsx; then
        echo "Installing dnsx..."
        go install github.com/projectdiscovery/dnsx/v2/cmd/dnsx@latest 2>/dev/null || {
            echo -e "${YELLOW}⊘ dnsx not installed (Go not available)${NC}"
        }

        # Add Go bin to PATH if exists
        if [ -d "$HOME/go/bin" ]; then
            export PATH="$PATH:$HOME/go/bin"
            echo 'export PATH="$PATH:$HOME/go/bin"' >> ~/.bashrc
        fi
    fi

    echo -e "${GREEN}✓ Additional tools installed${NC}"
}

# Function: Setup environment
setup_environment() {
    echo -e "\n${BLUE}[4/6] Setting up environment...${NC}"

    # Copy .env.example to .env if it doesn't exist
    if [ ! -f ".env" ]; then
        echo "Creating .env from .env.example..."
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Edit .env and add your API keys!${NC}"
        echo "   nano .env"
    else
        echo -e "${GREEN}✓ .env file already exists${NC}"
    fi

    # Create directories
    echo "Creating data directories..."
    mkdir -p data/{results,logs}
    mkdir -p data/spiderfoot
    mkdir -p config/{grafana,nginx}

    echo -e "${GREEN}✓ Environment setup complete${NC}"
}

# Function: Setup Docker services
setup_docker() {
    echo -e "\n${BLUE}[5/6] Setting up Docker services...${NC}"

    # Check if Docker is installed
    if ! command_exists docker; then
        echo -e "${RED}✗ Docker not found${NC}"
        echo "Installing Docker..."

        # Install Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm -f get-docker.sh

        # Add user to docker group
        sudo usermod -aG docker $USER

        echo -e "${YELLOW}⚠️  Log out and back in for Docker group changes to take effect${NC}"
    else
        echo -e "${GREEN}✓ Docker already installed${NC}"
    fi

    # Pull images
    echo "Pulling Docker images..."
    docker-compose pull

    echo -e "${GREEN}✓ Docker setup complete${NC}"
}

# Function: Install Recon-ng modules
install_recon_modules() {
    echo -e "\n${BLUE}[6/6] Installing Recon-ng modules...${NC}"

    if command_exists recon-ng; then
        echo "Updating Recon-ng modules..."
        recon-ng --update || true
        echo -e "${GREEN}✓ Recon-ng modules updated${NC}"
    else
        echo -e "${YELLOW}⊘ Recon-ng not installed yet${NC}"
        echo "  Will be installed via pip with other Python tools"
    fi
}

# Function: Generate summary
print_summary() {
    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}✓ Setup Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo -e "1. ${YELLOW}Configure API keys${NC}"
    echo "   nano .env"
    echo ""
    echo -e "2. ${YELLOW}Start Docker services${NC}"
    echo "   docker-compose up -d"
    echo ""
    echo -e "3. ${YELLOW}Access SpiderFoot web UI${NC}"
    echo "   open http://localhost:5001"
    echo ""
    echo -e "4. ${YELLOW}Run your first scan${NC}"
    echo "   ./scripts/initial_recon.sh example.com"
    echo ""
    echo -e "5. ${YELLOW}Check for leaks${NC}"
    echo "   ./scripts/leak_check.sh github.com/user/repo"
    echo ""
    echo -e "6. ${YELLOW}Monitor forums${NC}"
    echo "   ./scripts/forum_monitor.sh \"keyword\""
    echo ""
    echo "Available scripts:"
    echo "  - scripts/initial_recon.sh    - Full target reconnaissance"
    echo "  - scripts/leak_check.sh      - Data leak detection"
    echo "  - scripts/forum_monitor.sh   - Forum & social media monitoring"
    echo "  - scripts/daily_scan.sh      - Automated daily scans (create this)"
    echo ""
    echo "Documentation:"
    echo "  - README.md                   - Full documentation"
    echo "  - docs/                       - Additional documentation (create this)"
    echo ""
    echo "For help:"
    echo "  - OSINT Framework: https://osintframework.com/"
    echo "  - SpiderFoot docs: https://www.spiderfoot.net/documentation/"
    echo "  - Recon-ng wiki: https://github.com/lanmaster53/recon-ng/wiki"
    echo ""
}

# Main execution
main() {
    # Check dependencies
    echo "Checking system dependencies..."
    if ! command_exists python3; then
        echo -e "${RED}✗ Python 3 not found. Install it first.${NC}"
        exit 1
    fi

    # Run installation steps
    install_python_tools
    install_gitleaks
    install_additional_tools
    setup_environment
    setup_docker
    install_recon_modules

    # Print summary
    print_summary

    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${GREEN}Installation successful!${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Run main function
main
