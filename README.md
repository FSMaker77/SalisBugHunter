# 🕷️ Salis Bug HungerHunter - Bug Bounty Automation

SalisBugHunter is a specialized Bash script designed to automate the initial phase of Bug Bounty Hunting. It leverages the "Unix Philosophy" by chaining powerful tools like **Subfinder**, **Httpx**, and **Nuclei** into a seamless pipeline.

Designed for efficiency on VPS environments.

## 🚀 Features
- **Auto-Install:** Automatically sets up Go, ProjectDiscovery tools, and dependencies.
- **HackerOne Integration:** Downloads program scopes using `bbscope`.
- **Smart Filtering:** Extracts wildcards and filters out noise.
- **Reconnaissance:** Finds subdomains and probes for live HTTP services.
- **Vulnerability Scanning:** Runs Nuclei scans specifically for High and Critical CVEs.
- **Tmux Ready:** Optimized to run in background sessions.

## 🛠️ Installation

```bash
git clone [https://github.com/YOUR_USERNAME/salisbughunter.git](https://github.com/IL_TUO_USERNAME/salisbughunter.git)
cd SalisBugHunter
chmod +x salisbughunter.sh

./salisbughunter.sh
