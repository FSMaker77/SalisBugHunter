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






