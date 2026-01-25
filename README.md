# 🕷️ SalisBugHunter v2.5 - Modular & Safe Recon Framework

> **Automated, modular, and stealthy reconnaissance framework designed for Bug Bounty Hunters running on VPS providers with strict abuse policies (e.g., Hetzner).**

![Bash](https://img.shields.io/badge/Language-Bash-green)
![License](https://img.shields.io/badge/License-MIT-blue)
![Focus](https://img.shields.io/badge/Focus-Recon%20%26%20Vulnerability%20Scanning-red)

## 📖 Overview

**SalisBugHunter** is an all-in-one Bash script designed to automate the reconnaissance (Recon) and vulnerability scanning workflow.

Unlike other tools that focus solely on speed, SalisBugHunter is optimized for **stability** and **operational security (OPSEC)**. It utilizes "Safe" modes (controlled rate-limits) to prevent IP bans from sensitive VPS providers (like Hetzner) and includes a smart output cleaning system to optimize Nuclei results.

## ✨ Features

* **🛡️ Auto-Protection (Tmux):** Automatically detects if you are not in a Tmux session and starts one to ensure scans continue even if you disconnect.
* **🧩 Modular Workflow:** Execute each step individually (Subdomains, Httpx, Nuclei Critical/High/Medium) or use the Auto-Pilot.
* **☁️ Cloud Safe Mode:** Pre-configured with `rate-limit: 5` and `concurrency: 10` to avoid abuse flags from cloud providers.
* **🧹 Smart Output Cleaning:** Automatically generates clean files (`subs_live_cleaned.txt`) by removing status codes and titles to maximize Nuclei efficiency.
* **🎯 Segmented Scanning:** Scans divided by severity (Critical, High, Medium, Low) to allow for immediate triage.
* **🔑 HackerOne Integration:** Native integration with `bbscope` to automatically download targets from your private programs.


## 🚀 Usage
The tool offers an interactive menu with 12 options:

1. Setup & Config
Full Installation: Installs all necessary dependencies.

Reset Credentials: Configures your HackerOne API Keys.

2. Reconnaissance (Step-by-Step)
Download Scope: Fetches targets from your H1 programs.

Wildcard Filtering: Extracts wildcards and prepares targets.txt.

Subfinder: Enumerates subdomains.

Httpx (Clean): Verifies live domains, filters private IPs, and cleans the output to remove unnecessary "noise" for the scanner.

3. Vulnerability Scanning (Segmented)
Run targeted scans based on your available time:

🔴 Scan CRITICAL: Looks for critical vulnerabilities only (Fast).

🟠 Scan HIGH: Looks for high-impact vulnerabilities.

🟡 Scan MEDIUM: Standard scan.

🔵 Scan LOW/INFO: Information gathering and minor bugs.

4. ✈️ Auto-Pilot
Launch option 10 to execute the entire workflow (from scope download to full scanning) sequentially, without interruptions. Perfect for overnight scans.

📂 Output Structure
The script organizes files in the current directory for easy access:

targets.txt: List of root domains (wildcards).

subs_all.txt: All subdomains found.

subs_live_cleaned.txt: Key File. Clean list of live URLs only, ready for piping to other tools.

BUGS_CRITICAL.txt: Critical vulnerability report.

BUGS_HIGH.txt: High vulnerability report.

(etc...)

## ⚠️ Disclaimer
This tool is created for educational purposes and for authorized Bug Bounty activities. The author assumes no responsibility for the misuse of this software. Ensure you have explicit permission before scanning any target.

Happy Hunting! 🕵️‍♂️



## 🛠️ Installation

```bash
# 1. Clone the repository
git clone [https://github.com/FSMaker77/SalisBugHunter.git](https://github.com/FSMaker77/SalisBugHunter.git)

# 2. Enter the folder
cd SalisBugHunter

# 3. Make the script executable
chmod +x salisbughunter.sh

# 4. Run
./salisbughunter.sh


🚀 Usage
The tool offers an interactive menu with 12 options:

1. Setup & Config
Full Installation: Installs all necessary dependencies.

Reset Credentials: Configures your HackerOne API Keys.

2. Reconnaissance (Step-by-Step)
Download Scope: Fetches targets from your H1 programs.

Wildcard Filtering: Extracts wildcards and prepares targets.txt.

Subfinder: Enumerates subdomains.

Httpx (Clean): Verifies live domains, filters private IPs, and cleans the output to remove unnecessary "noise" for the scanner.

3. Vulnerability Scanning (Segmented)
Run targeted scans based on your available time:

🔴 Scan CRITICAL: Looks for critical vulnerabilities only (Fast).

🟠 Scan HIGH: Looks for high-impact vulnerabilities.

🟡 Scan MEDIUM: Standard scan.

🔵 Scan LOW/INFO: Information gathering and minor bugs.

4. ✈️ Auto-Pilot
Launch option 10 to execute the entire workflow (from scope download to full scanning) sequentially, without interruptions. Perfect for overnight scans.

📂 Output Structure
The script organizes files in the current directory for easy access:

targets.txt: List of root domains (wildcards).

subs_all.txt: All subdomains found.

subs_live_cleaned.txt: Key File. Clean list of live URLs only, ready for piping to other tools.

BUGS_CRITICAL.txt: Critical vulnerability report.

BUGS_HIGH.txt: High vulnerability report.

(etc...)

⚠️ Disclaimer
This tool is created for educational purposes and for authorized Bug Bounty activities. The author assumes no responsibility for the misuse of this software. Ensure you have explicit permission before scanning any target.

Happy Hunting! 🕵️‍♂️











