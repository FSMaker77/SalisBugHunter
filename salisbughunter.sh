#!/bin/bash

# --- INIZIO PROTEZIONE AUTOMATICA (TMUX) ---
if [ -z "$TMUX" ]; then
  echo "Attivazione scudo automatico (Tmux)..."
  tmux attach -t SalisSession || tmux new -s SalisSession ./salisbughunter.sh
  exit
fi
# --- FINE PROTEZIONE AUTOMATICA ---

# ==========================================
# SALISBUGHUNTER v2.3 - HETZNER SAFE EDITION
# ==========================================

# Colori NEON
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Percorsi e Config
GO_BIN="$HOME/go/bin"
CONFIG_FILE="$HOME/.salis_config"
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Funzione Header
show_header() {
    clear
    echo -e "${RED}======================================================${NC}"
    echo -e "${RED}      SALISBUGHUNTER v2.3 - HETZNER SAFE             ${NC}"
    echo -e "${RED}======================================================${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}[*] Credenziali HackerOne configurate.${NC}"
    else
        echo -e "${YELLOW}[!] Credenziali NON configurate.${NC}"
    fi

    echo -e "${BLUE}Target (Aziende):${NC}    $(wc -l < targets.txt 2>/dev/null || echo 0)"
    echo -e "${BLUE}Domini Totali (Raw):${NC} $(wc -l < subs_all.txt 2>/dev/null || echo 0)"
    echo -e "${BLUE}Siti Vivi (Live):${NC}    $(wc -l < subs_live.txt 2>/dev/null || echo 0)"
    echo ""
}

# 0. Gestione Credenziali
check_creds() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo -e "${YELLOW}[*] Prima configurazione: Inserisci le tue API HackerOne${NC}"
        read -p "Inserisci H1 Username: " H1_USER_INPUT
        read -p "Inserisci H1 API Key: " H1_KEY_INPUT
        echo "export H1_USER=\"$H1_USER_INPUT\"" > "$CONFIG_FILE"
        echo "export H1_KEY=\"$H1_KEY_INPUT\"" >> "$CONFIG_FILE"
        source "$CONFIG_FILE"
        echo -e "${GREEN}[V] Credenziali salvate!${NC}"
        sleep 1
    fi
}

reset_creds() {
    rm -f "$CONFIG_FILE"
    echo -e "${RED}[!] Credenziali rimosse.${NC}"
    sleep 1
    check_creds
}

# 1. Installazione Tools
install_tools() {
    echo -e "${BLUE}[*] Inizio installazione e aggiornamento tools...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git curl wget tmux build-essential unzip
    
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}[*] Installazione GO...${NC}"
        wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
        sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
    fi
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

    echo -e "${YELLOW}[*] Installazione Suite ProjectDiscovery & Bbscope...${NC}"
    go install github.com/sw33tLie/bbscope@latest
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    $GO_BIN/nuclei -update-templates
    
    echo -e "${GREEN}[V] Installazione completata!${NC}"
    read -p "Premi Invio..."
}

# 2. Scarica Scope
get_scope_raw() {
    check_creds 
    echo -e "${BLUE}[*] Download Scope da HackerOne in corso...${NC}"
    $GO_BIN/bbscope h1 -u "$H1_USER" -t "$H1_KEY" > scope_raw.txt
    lines=$(wc -l < scope_raw.txt)
    echo -e "${GREEN}[V] Download finito. $lines righe scaricate.${NC}"
    read -p "Premi Invio..."
}

# 3. Scrematura Wildcards
filter_wildcards() {
    if [ ! -f scope_raw.txt ]; then
        echo -e "${RED}[!] Errore: Manca scope_raw.txt.${NC}"
        read -p "Premi Invio..."
        return
    fi
    echo -e "${BLUE}[*] Estrazione Wildcards...${NC}"
    grep -o '\*\.[a-zA-Z0-9._-]*' scope_raw.txt | sed 's/^\*\.//' | sort -u > targets.txt
    count=$(wc -l < targets.txt)
    echo -e "${GREEN}[V] Scrematura completata! $count target pronti.${NC}"
    read -p "Premi Invio..."
}

# 4. Solo Subfinder
run_subfinder() {
    if [ ! -f targets.txt ]; then
        echo -e "${RED}[!] Errore: Manca targets.txt.${NC}"
        read -p "Premi Invio..."
        return
    fi

    if [ -f subs_all.txt ]; then
        echo -e "${YELLOW}[!] ATTENZIONE: 'subs_all.txt' esiste già.${NC}"
        read -p "Vuoi sovrascriverlo? (s/N): " resp
        if [[ "$resp" != "s" && "$resp" != "S" ]]; then
            return
        fi
    fi

    echo -e "${BLUE}[*] Avvio Subfinder (Solo ricerca domini)...${NC}"
    $GO_BIN/subfinder -dL targets.txt -silent -o subs_all.txt
    
    count=$(wc -l < subs_all.txt)
    echo -e "${GREEN}[V] Finito! Trovati $count sottodomini.${NC}"
    read -p "Premi Invio..."
}

# 5. Solo Httpx (Con protezione IP Privati)
run_httpx() {
    if [ ! -f subs_all.txt ]; then
        echo -e "${RED}[!] Errore: Manca subs_all.txt.${NC}"
        read -p "Premi Invio..."
        return
    fi

    echo -e "${BLUE}[*] Avvio Httpx (Filtra vivi + Protezione IP Privati)...${NC}"
    
    # MODIFICA IMPORTANTE: -exclude-private-ips
    # Questo impedisce di scansionare reti locali/interne che fanno arrabbiare Hetzner
    $GO_BIN/httpx -l subs_all.txt -silent \
    -threads 10 -rate-limit 5 \
    -exclude-private-ips \
    -title -tech-detect -status-code -o subs_live.txt
    
    live_count=$(wc -l < subs_live.txt)
    echo -e "${GREEN}[V] Httpx finito! $live_count siti vivi (e pubblici) salvati.${NC}"
    read -p "Premi Invio..."
}

# 6. Scansione Nuclei
run_scan() {
    if [ ! -f subs_live.txt ]; then
        echo -e "${RED}[!] Errore: Manca subs_live.txt.${NC}"
        read -p "Premi Invio..."
        return
    fi

    echo -e "${RED}[!!!] AVVIO NUCLEI (CRITICAL & HIGH - STEALTH) [!!!]${NC}"
    
    # Nuclei lavora sui risultati puliti di Httpx, quindi è sicuro
    $GO_BIN/nuclei -l subs_live.txt -s critical,high \
    -rate-limit 5 -bulk-size 2 -concurrency 10 \
    -o BUGS_SALIS.txt
    
    echo -e "${GREEN}[V] Scansione terminata. Controlla BUGS_SALIS.txt${NC}"
    read -p "Premi Invio..."
}

# 7. Auto-Pilota
run_full() {
    check_creds
    echo -e "${YELLOW}AUTO-PILOTA: Download -> Scrematura -> Recon -> Scan (SAFE MODE)${NC}"
    read -p "Premi Invio per partire..."
    
    echo -e "${BLUE}[1/5] Download Scope...${NC}"
    $GO_BIN/bbscope h1 -u "$H1_USER" -t "$H1_KEY" > scope_raw.txt
    
    echo -e "${BLUE}[2/5] Scrematura...${NC}"
    grep -o '\*\.[a-zA-Z0-9._-]*' scope_raw.txt | sed 's/^\*\.//' | sort -u > targets.txt
    
    echo -e "${BLUE}[3/5] Subfinder...${NC}"
    $GO_BIN/subfinder -dL targets.txt -silent -o subs_all.txt

    echo -e "${BLUE}[4/5] Httpx (SAFE MODE)...${NC}"
    # Aggiunto -exclude-private-ips anche qui
    $GO_BIN/httpx -l subs_all.txt -silent -threads 10 -rate-limit 5 -exclude-private-ips \
    -title -tech-detect -status-code -o subs_live.txt
    
    echo -e "${RED}[5/5] Scan Nuclei...${NC}"
    $GO_BIN/nuclei -l subs_live.txt -s critical,high -rate-limit 5 -bulk-size 2 -concurrency 10 -o BUGS_SALIS.txt
    
    echo -e "${GREEN}[V] TUTTO FINITO!${NC}"
    read -p "Premi Invio..."
}

# Loop del Menù
while true; do
    show_header
    echo "1. Installazione Completa"
    echo "2. Scarica Scope (Bbscope)"
    echo "3. Scrematura Wildcards"
    echo "------------------------------------"
    echo "4. Subfinder (Crea lista enorme)"
    echo "5. Httpx (Filtra vivi + NO IP PRIVATI)"
    echo "------------------------------------"
    echo "6. Vulnerability Scanning (Nuclei)"
    echo "7. AUTO-PILOTA (Safe Mode)"
    echo "------------------------------------"
    echo "8. Reset Credenziali"
    echo "9. Esci"
    echo ""
    read -p "SalisBugHunter > Scegli: " choice

    case $choice in
        1) install_tools ;;
        2) get_scope_raw ;;
        3) filter_wildcards ;;
        4) run_subfinder ;;
        5) run_httpx ;;
        6) run_scan ;;
        7) run_full ;;
        8) reset_creds ;;
        9) exit 0 ;;
        *) echo -e "${RED}Opzione non valida${NC}"; sleep 1 ;;
    esac
done
