# 🚀 OSINT Toolkit - Quick Start Guide

## ⚡ 5-Minute Setup

### 1. Install Dependencies
```bash
cd ~/projects/osint-toolkit
./scripts/setup.sh
```

This will:
- Install Python tools (SpiderFoot, Recon-ng, theHarvester)
- Install GitLeaks
- Setup Docker environment
- Create necessary directories

### 2. Configure API Keys (Optional)
```bash
cp .env.example .env
nano .env
```

Add free API keys:
- **Shodan**: https://developer.shodan.io/api (50 queries/month free)
- **VirusTotal**: https://www.virustotal.com/ (500 requests/day free)
- **HIBP**: https://haveibeenpwned.com/API/Key (free tier)

**Note**: Tools work without API keys, just with limited functionality.

### 3. Start Docker Services (Optional)
```bash
docker-compose up -d
```

Services:
- SpiderFoot UI: http://localhost:5001
- Grafana: http://localhost:3000 (admin/admin)
- PostgreSQL: localhost:5432
- Redis: localhost:6379
- Tor proxy: localhost:9050

---

## 🎯 Common Tasks

### Initial Target Reconnaissance
```bash
./scripts/initial_recon.sh example.com
```

**What it does:**
- Subdomain enumeration
- Email harvesting
- DNS reconnaissance
- SpiderFoot scan
- Recon-ng analysis

**Results:** `data/results/example.com/`

---

### Data Leak Detection
```bash
# Scan Git repository for secrets
./scripts/leak_check.sh github.com/user/repo

# Check email for breaches
./scripts/leak_check.sh user@example.com

# Scan domain
./scripts/leak_check.sh example.com
```

**What it does:**
- GitLeaks secret scanning
- HaveIBeenPwned breach check
- Dark web leak search
- Paste site monitoring

**Results:** `data/results/leaks/`

---

### Forum Monitoring
```bash
# Monitor for mentions (last 24 hours)
./scripts/forum_monitor.sh "target company"

# Monitor last week
./scripts/forum_monitor.sh "keyword" 168

# Continuous monitoring
crontab -e
# Add: 0 */6 * * * /home/adam/projects/osint-toolkit/scripts/forum_monitor.sh "keyword" 6
```

**What it does:**
- Reddit search
- 4chan archive search
- Paste site monitoring
- Dark web forum links

**Results:** `data/results/forums/`

---

## 📊 Results Location

All scan results are saved to:
```
data/results/
├── example.com/              # Domain scans
│   ├── theharvester_hosts.txt
│   ├── spiderfoot_report.html
│   └── summary.txt
├── leaks/                    # Leak checks
│   └── github.com_user_repo/
│       └── leak_summary.txt
└── forums/                   # Forum monitoring
    └── keyword/
        └── forum_summary.txt
```

---

## 🔄 Automation

### Daily Automated Scans

Create `scripts/daily_scan.sh`:
```bash
#!/bin/bash
TARGETS=("example.com" "target2.com")
for target in "${TARGETS[@]}"; do
    /home/adam/projects/osint-toolkit/scripts/initial_recon.sh "$target"
    /home/adam/projects/osint-toolkit/scripts/leak_check.sh "$target"
done
```

Add to crontab:
```bash
# Run daily at 2 AM
0 2 * * * /home/adam/projects/osint-toolkit/scripts/daily_scan.sh
```

### Continuous Forum Monitoring

```bash
# Check every hour
0 * * * * /home/adam/projects/osint-toolkit/scripts/forum_monitor.sh "your brand" 1

# Check every 6 hours
0 */6 * * * /home/adam/projects/osint-toolkit/scripts/forum_monitor.sh "your product" 6
```

---

## 🎮 CTF Usage

```bash
# Quick recon for CTF target
./scripts/initial_recon.sh ctf.target.com

# Check for exposed Git repos
./scripts/leak_check.sh github.com/ctf-challenge

# Monitor for hints
./scripts/forum_monitor.sh "CTF name" 1
```

---

## 📱 Access Tools Directly

### SpiderFoot Web UI
```bash
docker-compose up -d spiderfoot
open http://localhost:5001
```

### Recon-ng Interactive
```bash
recon-ng
> workspaces create target
> db insert domains target.com
> markets run
```

### theHarvester CLI
```bash
theHarvester -d target.com -l 500 -b all
```

### GitLeaks
```bash
gitleaks detect --source ./repo --report report.json
```

---

## 📚 Next Steps

1. **Read the full docs**: `README.md`
2. **Explore OSINT Framework**: https://osintframework.com/
3. **Join communities**: r/OSINT, r/netsec
4. **Practice legally**:
   - Scan your own domains
   - Use CTF challenges
   - Get written permission for other targets

---

## ⚠️ Important Reminders

**Legal Use Only:**
- ✅ Your own infrastructure
- ✅ Authorized targets (written permission)
- ✅ Public CTF challenges
- ❌ Unauthorized targets
- ❌ Government systems
- ❌ Illegal activities

**API Key Protection:**
```bash
# Never commit .env
echo ".env" >> .gitignore

# Use environment variables
export SHODAN_API_KEY="your-key"
```

**Data Privacy:**
- Results may contain sensitive information
- Secure your results directory
- Clean up old scans regularly
- Follow GDPR/data protection laws

---

## 🐛 Troubleshooting

**SpiderFoot won't start:**
```bash
docker start osint-spiderfoot
# Or
spiderfoot -l 127.0.0.1:5001
```

**Recon-ng modules missing:**
```bash
recon-ng --update
```

**Permission denied:**
```bash
chmod +x scripts/*.sh
```

**Docker issues:**
```bash
docker-compose down
docker-compose up -d --build
```

**Port already in use:**
```bash
lsof -i :5001  # Find process
kill -9 <PID>  # Kill it
```

---

## 📖 Resources

**Learning:**
- [OSINT Framework](https://osintframework.com/)
- [Awesome OSINT](https://github.com/jivoi/awesome-osint)
- [SpiderFoot Documentation](https://www.spiderfoot.net/documentation/)
- [Recon-ng Wiki](https://github.com/lanmaster53/recon-ng/wiki)

**Communities:**
- r/OSINT
- r/netsec
- r/AskNetsec
- SpiderFoot Discord

**Practice Sites:**
- https://hackthissite.org/
- https://tryhackme.com/
- https://ctftime.org/

---

**Happy Hunting! 🎯**

Remember: With great power comes great responsibility. Use OSINT tools ethically and legally.
