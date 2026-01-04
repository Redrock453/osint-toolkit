# 🕵️ OSINT Toolkit - Comprehensive Open Source Intelligence Framework

## 📋 Overview

Professional OSINT toolkit for cybersecurity researchers, CTF players, and threat intelligence analysts. Integrates best-in-class open-source tools for internet reconnaissance, leak detection, and forum monitoring.

**🎯 Primary Use Cases:**
- Cybersecurity threat intelligence
- Data breach detection
- Forum monitoring (surface & dark web)
- CTF competitions
- Security research
- Incident response

---

## 🛠️ Tool Selection

### Core Frameworks

#### 1. **SpiderFoot** 🕷️
- **Purpose**: Automated OSINT aggregation framework
- **Capabilities**:
  - 200+ data sources
  - Web UI & REST API
  - Automated scans
  - Dark web monitoring
  - Correlation analysis
- **Installation**: `pip install spiderfoot`
- **Web UI**: http://localhost:5001
- **Docs**: https://www.spiderfoot.net/documentation/

#### 2. **Recon-ng** 🔍
- **Purpose**: Modular reconnaissance framework
- **Capabilities**:
  - Modular architecture
  - API integrations
  - Database-driven
  - Reporting workflows
  - Custom modules
- **Installation**: `pip install recon-ng`
- **Wiki**: https://github.com/lanmaster53/recon-ng/wiki

#### 3. **theHarvester** 🌾
- **Purpose**: Email, subdomain, and people harvesting
- **Capabilities**:
  - Search engine scraping
  - Subdomain enumeration
  - Email gathering
  - LinkedIn harvesting
  - Shodan integration
- **Installation**: `pip install theHarvester`
- **GitHub**: https://github.com/laramies/theHarvester

### Leak Detection Tools

#### 4. **GitLeaks** 🔐
- **Purpose**: Secret detection in Git repositories
- **Capabilities**:
  - Scan repos for secrets
  - 600+ secret patterns
  - Configurable rules
  - CI/CD integration
  - JSON/CSV reports
- **Installation**: Download binary or `pip install gitleaks`
- **GitHub**: https://github.com/zricethezav/gitleaks

#### 5. **Oblivion** 🕳️
- **Purpose**: Real-time data leak monitoring
- **Capabilities**:
  - Continuous monitoring
  - Credential exposure alerts
  - Dark web scanning
  - Database breach checks
- **GitHub**: https://github.com/loseys/Oblivion

#### 6. **BreachHunter** 🎯
- **Purpose**: Data breach analysis
- **Capabilities**:
  - Breach database search
  - Credential verification
  - Historical breach data
  - Web UI interface
- **GitHub**: https://github.com/4m3rr0r/BreachHunter

### Forum & Dark Web Monitoring

#### 7. **OnionScan** 🧅
- **Purpose**: Dark web/Tor site scanner
- **Capabilities**:
  - Onion link discovery
  - Hidden service scanning
  - Metadata extraction
  - Security analysis
- **GitHub**: https://github.com/s-rah/onionscan

#### 8. **Custom Forum Scrapers** 💬
- **Reddit API**: Monitor subreddits
- **4chan/8chan**: Thread monitoring
- **Paste sites**: Pastebin, JustPaste.it
- **Dark web forums**: Tor-based monitoring

---

## 📦 Installation

### Quick Start (Docker)

```bash
# Clone/create project
cd ~/projects/osint-toolkit

# Build and start services
docker-compose up -d

# Access SpiderFoot web UI
open http://localhost:5001
```

### Manual Installation

```bash
# Install Python dependencies
pip install -r requirements.txt

# Install GitLeaks (binary)
wget https://github.com/zricethezav/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/

# Configure API keys
cp .env.example .env
nano .env  # Add your API keys
```

---

## 🚀 Quick Usage

### 1. Initial Target Reconnaissance

```bash
./scripts/initial_recon.sh example.com
```

**What it does:**
- Subdomain enumeration (theHarvester)
- Comprehensive OSINT scan (SpiderFoot)
- Deep reconnaissance (Recon-ng)
- Results saved to `data/results/example.com/`

### 2. Leak Detection

```bash
./scripts/leak_check.sh github.com/user/repo
```

**What it does:**
- Scan Git repository for secrets (GitLeaks)
- Check breach databases
- Search paste sites
- Dark web lookup

### 3. Forum Monitoring

```bash
./scripts/forum_monitor.sh "target keyword"
```

**What it does:**
- Monitor Reddit for mentions
- Scan 4chan threads
- Check paste sites
- Alert on new findings

### 4. SpiderFoot Web UI

```bash
# Start SpiderFoot
spiderfoot -l 127.0.0.1:5001

# Open browser
open http://127.0.0.1:5001
```

### 5. Recon-ng Interactive

```bash
# Start Recon-ng
recon-ng

# Create workspace
workspaces create target

# Add domains
db insert domains target.com

# Run modules
markets run
```

---

## 📅 Automation

### Scheduled Scans (Crontab)

```bash
# Daily full scan at 2 AM
0 2 * * * /home/adam/projects/osint-toolkit/scripts/daily_scan.sh

# Leak check every 6 hours
0 */6 * * * /home/adam/projects/osint-toolkit/scripts/leak_check.sh

# Forum monitoring hourly
0 * * * * /home/adam/projects/osint-toolkit/scripts/forum_monitor.sh
```

---

## 📊 Results & Reports

Results are stored in `data/results/`:
```
data/results/
├── example.com/
│   ├── theharvester.json
│   ├── spiderfoot_report.html
│   ├── recon-ng.db
│   └── gitleaks_report.json
└── logs/
    ├── scan_2025-01-03.log
    └── errors.log
```

---

## 🔒 Security Considerations

### ⚠️ Legal & Ethical Use

**ONLY use against:**
- ✅ Your own infrastructure
- ✅ Authorized targets (written permission)
- ✅ Public CTF challenges
- ✅ Educational purposes with proper authorization

**NEVER use against:**
- ❌ Targets without explicit permission
- ❌ Government/military systems
- ❌ Critical infrastructure
- ❌ For harassment or illegal activities

### API Key Protection

```bash
# Never commit .env file
echo ".env" >> .gitignore

# Use environment variables
export SHODAN_API_KEY="your-key-here"

# Or use Docker secrets
docker-compose config | grep secrets
```

### Data Isolation

- All tools run in Docker containers
- Database access restricted
- Logs rotated regularly
- Sensitive data encrypted

---

## 💰 Cost Analysis

### Free Tools (100% Free)
- SpiderFoot (open source)
- Recon-ng (free)
- theHarvester (free)
- GitLeaks (free)
- OnionScan (free)

### Freemium Services (Optional)

| Service | Free Tier | Paid Plans |
|---------|-----------|------------|
| Shodan | 50 queries/month | From $49/month |
| VirusTotal | 500 requests/day | From $500/month |
| IntelligenceX | Limited searches | From €29/month |
| HaveIBeenPwned | Free API | Commercial licenses |

**Estimated Cost**: $0-$100/month depending on premium services used

---

## 📚 Resources

### Learning
- [OSINT Framework](https://osintframework.com/) - Tool categorization
- [Awesome OSINT](https://github.com/jivoi/awesome-osint) - Curated tools list
- [Dark Web OSINT Tools](https://github.com/apurvsinghgautam/dark-web-osint-tools)

### Documentation
- [SpiderFoot Docs](https://www.spiderfoot.net/documentation/)
- [Recon-ng Wiki](https://github.com/lanmaster53/recon-ng/wiki)
- [GitLeaks Guide](https://github.com/zricethezav/gitleaks)

### Communities
- r/OSINT on Reddit
- r/netsec
- SpiderFoot Discord
- CyberIntel Slack communities

---

## 🎯 CTF Usage

### Common CTF Tasks

```bash
# 1. Subdomain enumeration
./scripts/ctf/subdomains.sh ctf.target.com

# 2. Email gathering
./scripts/ctf/harvest.sh ctf.target.com

# 3. Metadata extraction
./scripts/ctf/metadata.sh ctf_file.pdf

# 4. Social media investigation
./scripts/ctf/social.sh @ctf_user
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: SpiderFoot won't start
```bash
# Check port 5001
lsof -i :5001
# Kill existing process
kill -9 $(lsof -t -i:5001)
```

**Issue**: Recon-ng modules missing
```bash
# Update Recon-ng
recon-ng --update
```

**Issue**: GitLeaks false positives
```bash
# Create custom config
gitleaks config --source > .gitleaks.toml
# Edit config to exclude patterns
```

---

## 📝 Contributing

Contributions welcome! Areas for improvement:
- Additional forum scrapers
- Custom Recon-ng modules
- SpiderFoot plugins
- Integration scripts
- Documentation improvements

---

## 📄 License

This toolkit integrates open-source tools. Each tool has its own license:
- SpiderFoot: MIT
- Recon-ng: GPL-3.0
- GitLeaks: MIT
- theHarvester: GPL-2.0

---

## 🙏 Acknowledgments

- SpiderFoot by SpiderFoot Net Pty Ltd
- Recon-ng by Tim Tomes (@lanmaster53)
- GitLeaks by Zachary Rice
- theHarvester by Christian Martorella
- OnionScan by Sarah Jamie Lewis

---

## ⚡ Quick Reference

```bash
# SpiderFoot
spiderfoot -l 127.0.0.1:5001

# Recon-ng
recon-ng

# theHarvester
theHarvester -d target.com -l 500 -b all

# GitLeaks
gitleaks detect --source ./repo --report leak-report.json

# OnionScan
onionscan --webport 8080 <onion-address>.onion

# Full scan
./scripts/initial_recon.sh target.com
```

---

**🎉 Happy Hunting!** Remember: With great power comes great responsibility. Use OSINT tools ethically and legally.
