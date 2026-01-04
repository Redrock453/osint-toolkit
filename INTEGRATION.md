# 🔄 OSINT Toolkit - Claude Code Integration

## ✅ Integration Complete

The OSINT Toolkit is now fully integrated into your Claude Code environment!

---

## 🚀 Quick Start

### In any new terminal:
```bash
source ~/.bashrc
```

### Available Commands:

```bash
# Main CLI (recommended)
osint status              # Check toolkit status
osint help                # Show all commands

# Reconnaissance
osint recon example.com              # Full recon on target
osint recon example.com --memory     # Save results to Claude memory
osint recon example.com --log-workflow  # Log to daily workflow

# Leak Detection
osint leaks github.com/user/repo     # Check for exposed secrets
osint leaks user@example.com         # Check email breaches
osint leaks example.com              # Check domain

# Forum Monitoring
osint monitor "target keyword"       # Monitor last 24h
osint monitor "keyword" 168          # Monitor last week
osint monitor "brand" --log-workflow # Auto-log results

# Setup & Management
osint setup                          # Install all tools
osint docker                         # Start Docker services
osint stop-docker                    # Stop Docker services
osint update                         # Update from GitHub
```

---

## 🔗 Integration Points

### 1. Daily Workflow Integration
```bash
osint recon target.com --log-workflow
# Automatically logs to: ~/projects/scripts_utils/daily_workflow.sh
```

### 2. Claude Memory Integration
```bash
osint monitor "keyword" --memory
# Automatically saves to: ~/claude_system/CLAUDE_MASTER_MEMORY.md
```

### 3. Quick Aliases
```bash
osint-cd              # cd to toolkit directory
osint-recon target    # Quick recon scan
osint-leaks target    # Quick leak check
osint-forums keyword  # Quick forum monitor
osint-setup           # Run setup script
```

---

## 📂 Project Structure

```
~/projects/osint-toolkit/
├── README.md                 # Full documentation
├── QUICKSTART.md             # 5-minute setup guide
├── INTEGRATION.md            # This file
├── osint-cli.sh             # Main CLI integration script
├── docker-compose.yml       # Docker services
├── .env.example             # API keys template
├── requirements.txt         # Python dependencies
├── scripts/
│   ├── setup.sh            # Automated setup
│   ├── initial_recon.sh    # Target reconnaissance
│   ├── leak_check.sh       # Data leak detection
│   └── forum_monitor.sh    # Forum monitoring
├── data/
│   ├── results/            # Scan results
│   └── logs/               # Operation logs
└── config/
    ├── grafana/            # Grafana config
    └── nginx/              # Nginx config
```

---

## 🎯 Common Workflows

### CTF Challenge Reconnaissance
```bash
osint recon ctf.target.com --log-workflow --memory
```

### Self-Monitoring
```bash
osint leaks github.com/Redrock453/osint-toolkit
osint monitor "Redrock453" 168
```

### Continuous Monitoring (Cron)
```bash
# Add to crontab
0 */6 * * * source ~/.bashrc && osint monitor "your brand" 6 --log-workflow
0 2 * * * source ~/.bashrc && osint recon target.com --log-workflow
```

---

## 🌐 Web Interfaces

After running `osint docker`:
- **SpiderFoot UI**: http://localhost:5001
- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Tor Proxy**: localhost:9050
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

---

## 📊 Results Location

All scan results saved to: `~/projects/osint-toolkit/data/results/`

```
data/results/
├── example.com/
│   ├── theharvester_hosts.txt
│   ├── spiderfoot_report.html
│   ├── recon-ng_data.db
│   └── summary.txt
├── leaks/
│   └── github.com_user_repo/
│       └── leak_summary.txt
└── forums/
    └── keyword/
        └── forum_summary.txt
```

---

## 🛠️ Tools Included

1. **SpiderFoot** 🕷️ - 200+ data sources automation
2. **Recon-ng** 🔍 - Modular reconnaissance framework
3. **theHarvester** 📧 - Email/subdomain harvesting
4. **GitLeaks** 🔑 - Secret detection in code
5. **HIBP Integration** 🚨 - Data breach checking
6. **OnionScan** 🌑 - Dark web monitoring
7. **Tor Proxy** 🔒 - Anonymous scanning
8. **Grafana** 📊 - Visualization dashboard
9. **PostgreSQL** 🗄️ - Data storage
10. **Redis** ⚡ - Task queue

---

## ⚙️ Configuration

### API Keys (Optional)
```bash
cd ~/projects/osint-toolkit
cp .env.example .env
nano .env
```

Add free API keys:
- **Shodan**: 50 queries/month free
- **VirusTotal**: 500 requests/day free
- **HIBP**: Free tier available

### GitHub Repository
https://github.com/Redrock453/osint-toolkit

```bash
# Update from GitHub
osint update

# Or manually
cd ~/projects/osint-toolkit
git pull origin main
```

---

## 📚 Documentation

- **Full Guide**: `~/projects/osint-toolkit/README.md`
- **Quick Start**: `~/projects/osint-toolkit/QUICKSTART.md`
- **Integration**: `~/projects/osint-toolkit/INTEGRATION.md` (this file)

---

## 🔒 Legal & Ethical Use

**✅ Authorized Use:**
- Your own infrastructure
- Written permission obtained
- Public CTF challenges
- Educational purposes

**❌ Unauthorized Use:**
- Targets without permission
- Government systems
- Illegal activities
- Harassment

---

## 🐛 Troubleshooting

### Command not found
```bash
source ~/.bashrc
```

### Docker services won't start
```bash
osint docker          # Start services
docker ps             # Check status
docker-compose logs   # View logs
```

### Permission denied
```bash
chmod +x ~/projects/osint-toolkit/scripts/*.sh
```

### Update tools
```bash
osint update
recon-ng --update
```

---

## 🎓 Learning Resources

- [OSINT Framework](https://osintframework.com/)
- [SpiderFoot Docs](https://www.spiderfoot.net/documentation/)
- [Recon-ng Wiki](https://github.com/lanmaster53/recon-ng/wiki)
- [Awesome OSINT](https://github.com/jivoi/awesome-osint)

---

## 📝 Session Tracking

All OSINT operations can be automatically tracked:

```bash
# Start tracking
~/projects/scripts_utils/daily_workflow.sh start "OSINT reconnaissance on target.com"

# Run scans with logging
osint recon target.com --log-workflow

# Add notes
~/projects/scripts_utils/daily_workflow.sh add "Found 15 subdomains, 3 exposed emails"

# Complete session
~/projects/scripts_utils/daily_workflow.sh end "Recon complete, 3 vulnerabilities found"
```

---

## 🚀 Next Steps

1. **Configure API keys** (optional but recommended)
   ```bash
   cd ~/projects/osint-toolkit
   nano .env
   ```

2. **Run first scan** (test on your own domain)
   ```bash
   osint recon example.com
   ```

3. **Check results**
   ```bash
   ls -la ~/projects/osint-toolkit/data/results/
   ```

4. **Start monitoring** (optional)
   ```bash
   osint monitor "your keyword" --log-workflow
   ```

---

**Status**: ✅ Fully Integrated
**GitHub**: https://github.com/Redrock453/osint-toolkit
**Location**: ~/projects/osint-toolkit/
**Version**: 1.0.0

Happy Hunting! 🎯
