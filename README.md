# 🕷️ Salis Bug Hunter v2.2 - Stealth & Modular Edition

**SalisBugHunter** is an advanced Bash automation script designed for Bug Bounty Hunters. It streamlines the reconnaissance pipeline by chaining industry-standard tools (**Subfinder**, **Httpx**, **Nuclei**) into a seamless workflow.

> **v2.2 Update:** Now features "Stealth Mode" (Rate-Limiting) to prevent VPS Abuse bans (Hetzner Safe) and a Modular Architecture for handling large datasets.

## 🚀 Key Features

- **🛡️ Stealth Mode:** Pre-configured low rate-limits (`5 req/s`) to stay under the radar of VPS firewalls (tested on Hetzner).
- **👻 Auto-Shield (Tmux):** Automatically detects if the script is running in a naked session and launches/attaches a `tmux` session to prevent data loss on disconnect.
- **🧩 Modular Recon:** Separated Subdomain Enumeration (Step 4) from Live Probing (Step 5) to handle massive files (60MB+) without restarting the whole process.
- **🎨 Neon UI:** High-visibility color scheme optimized for PowerShell and dark terminals.
- **⚡ HackerOne Integration:** Automates scope downloading via `bbscope`.
- **🎯 Smart Filtering:** Extracts wildcards and sanitizes target lists automatically.

## 🛠️ Installation

```bash
# Clone the repository
git clone https://github.com/FSMaker77/SalisBugHunter.git

# Enter the directory
cd SalisBugHunter

# Fix Windows/Linux formatting issues (Important if uploaded via FTP)
dos2unix salisbughunter.sh

# Install tmux
sudo apt update && sudo apt install tmux -y

# Make executable
chmod +x salisbughunter.sh

# Run
./salisbughunter.sh




