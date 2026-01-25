#!/bin/bash

# --- INIZIO PROTEZIONE AUTOMATICA (TMUX) ---
if [ -z "$TMUX" ]; then
  echo "Attivazione scudo automatico (Tmux)..."
  tmux attach -t SalisSession || tmux new -s SalisSession ./salisbughunter.sh
  exit
fi
# --- FINE PROTEZIONE AUTOMATICA ---

# ==========================================
# SALISBUGHUNTER v2.5 - MODULAR EDITION
# ==========================================

# Colori NEON
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Percorsi e Config
GO_BIN="$HOME/go/bin"
CONFIG_FILE="$HOME/.settings"
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Funzione Header
show_header() {
    clear
    echo -e "${RED}======================================================${NC}"
    echo -e "${RED}   SALISBUGHUNTER v2.5 - MODULAR & SAFE              ${NC}"
    echo -e "${RED}======================================================${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}[*] Credenziali HackerOne configurate.${NC}"
    else
        echo -e "${YELLOW}[!] Credenziali NON configurate.${NC}"
    fi

    echo -e "${BLUE}Target (Aziende):${NC}    $(wc -l < targets.txt 2>/dev/null || echo 0)"
    echo -e "${BLUE}Siti Vivi (Clean):${NC}   $(wc -l < subs_live_cleaned.txt 2>/dev/null || echo 0)"
    
    # Contatori Bug Trovati
    crit=$(wc -l < BUGS_CRITICAL.txt 2>/dev/null || echo 0)
    high=$(wc -l < BUGS_HIGH.txt 2>/dev/null || echo 0)
    med=$(wc -l < BUGS_MEDIUM.txt 2>/dev/null || echo 0)
    
    echo -e "${RED}CRITICAL Found:${NC}      $crit"
    echo -e "${RED}HIGH Found:${NC}          $high"
    echo -e "${YELLOW}MEDIUM Found:${NC}        $med"
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

    echo -e "${BLUE}[*] Avvio Subfinder...${NC}"
    $GO_BIN/subfinder -dL targets.txt -silent -o subs_all.txt
    
    count=$(wc -l < subs_all.txt)
    echo -e "${GREEN}[V] Finito! Trovati $count sottodomini.${NC}"
    read -p "Premi Invio..."
}

# 5. Httpx (Safe + Cleaning)
run_httpx() {
    if [ ! -f subs_all.txt ]; then
        echo -e "${RED}[!] Errore: Manca subs_all.txt.${NC}"
        read -p "Premi Invio..."
        return
    fi

    echo -e "${BLUE}[*] Avvio Httpx (Hetzner Safe Mode)...${NC}"
    
    # 1. Scansione Verbose
    $GO_BIN/httpx -l subs_all.txt -silent \
    -threads 10 -rate-limit 5 \
    -exclude-private-ips \
    -title -tech-detect -status-code -o subs_live.txt
    
    # 2. Pulizia
    echo -e "${BLUE}[*] Pulizia output per Nuclei...${NC}"
    if [ -f subs_live.txt ]; then
        awk '{print $1}' subs_live.txt > subs_live_cleaned.txt
        live_count=$(wc -l < subs_live.txt)
        echo -e "${GREEN}[V] Httpx finito! $live_count siti vivi.${NC}"
        echo -e "${GREEN}[V] File pulito creato: subs_live_cleaned.txt${NC}"
    else
        echo -e "${RED}[!] Nessun risultato vivo trovato.${NC}"
    fi
    read -p "Premi Invio..."
}

# --- FUNZIONI NUCLEI SEPARATE ---

check_list() {
    if [ ! -f subs_live_cleaned.txt ]; then
        echo -e "${RED}[!] Errore: Manca subs_live_cleaned.txt (Esegui step 5).${NC}"
        read -p "Premi Invio..."
        return 1
    fi
    return 0
}

run_critical() {
    check_list || return
    echo -e "${RED}[!!!] AVVIO NUCLEI - CRITICAL ONLY [!!!]${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s critical \
    -rate-limit 5 -bulk-size 2 -concurrency 10 \
    -o BUGS_CRITICAL.txt
    echo -e "${GREEN}[V] Scan Critical terminato.${NC}"
    read -p "Premi Invio..."
}

run_high() {
    check_list || return
    echo -e "${RED}[!!!] AVVIO NUCLEI - HIGH ONLY [!!!]${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s high \
    -rate-limit 5 -bulk-size 2 -concurrency 10 \
    -o BUGS_HIGH.txt
    echo -e "${GREEN}[V] Scan High terminato.${NC}"
    read -p "Premi Invio..."
}

run_medium() {
    check_list || return
    echo -e "${YELLOW}[!!!] AVVIO NUCLEI - MEDIUM ONLY [!!!]${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s medium \
    -rate-limit 5 -bulk-size 2 -concurrency 10 \
    -o BUGS_MEDIUM.txt
    echo -e "${GREEN}[V] Scan Medium terminato.${NC}"
    read -p "Premi Invio..."
}

run_low() {
    check_list || return
    echo -e "${BLUE}[!!!] AVVIO NUCLEI - LOW & INFO ONLY [!!!]${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s low,info \
    -rate-limit 5 -bulk-size 2 -concurrency 10 \
    -o BUGS_LOW_INFO.txt
    echo -e "${GREEN}[V] Scan Low/Info terminato.${NC}"
    read -p "Premi Invio..."
}

# 10. Auto-Pilota (Sequenziale)
run_full() {
    check_creds
    echo -e "${YELLOW}AUTO-PILOTA: Esegue TUTTO in sequenza (Safe Mode)${NC}"
    read -p "Premi Invio per partire..."
    
    # Download & Recon
    $GO_BIN/bbscope h1 -u "$H1_USER" -t "$H1_KEY" > scope_raw.txt
    grep -o '\*\.[a-zA-Z0-9._-]*' scope_raw.txt | sed 's/^\*\.//' | sort -u > targets.txt
    $GO_BIN/subfinder -dL targets.txt -silent -o subs_all.txt
    
    # Httpx Clean
    $GO_BIN/httpx -l subs_all.txt -silent -threads 10 -rate-limit 5 -exclude-private-ips \
    -title -tech-detect -status-code -o subs_live.txt
    awk '{print $1}' subs_live.txt > subs_live_cleaned.txt
    
    # Nuclei Sequenziale (Senza pause)
    echo -e "${RED}[+] Scan Critical...${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s critical -rate-limit 5 -bulk-size 2 -concurrency 10 -o BUGS_CRITICAL.txt
    
    echo -e "${RED}[+] Scan High...${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s high -rate-limit 5 -bulk-size 2 -concurrency 10 -o BUGS_HIGH.txt
    
    echo -e "${YELLOW}[+] Scan Medium...${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s medium -rate-limit 5 -bulk-size 2 -concurrency 10 -o BUGS_MEDIUM.txt
    
    echo -e "${BLUE}[+] Scan Low/Info...${NC}"
    $GO_BIN/nuclei -l subs_live_cleaned.txt -s low,info -rate-limit 5 -bulk-size 2 -concurrency 10 -o BUGS_LOW_INFO.txt
    
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
    echo "4. Subfinder (Crea lista domini)"
    echo "5. Httpx (Crea file PULITO per scan)"
    echo "------------------------------------"
    echo -e "6. Scan ${RED}CRITICAL${NC}"
    echo -e "7. Scan ${RED}HIGH${NC}"
    echo -e "8. Scan ${YELLOW}MEDIUM${NC}"
    echo -e "9. Scan ${BLUE}LOW & INFO${NC}"
    echo "------------------------------------"
    echo "10. AUTO-PILOTA (Tutto insieme)"
    echo "11. Reset Credenziali"
    echo "12. Esci"
    echo ""
    read -p "SalisBugHunter > Scegli: " choice

    case $choice in
        1) install_tools ;;
        2) get_scope_raw ;;
        3) filter_wildcards ;;
        4) run_subfinder ;;
        5) run_httpx ;;
        6) run_critical ;;
        7) run_high ;;
        8) run_medium ;;
        9) run_low ;;
        10) run_full ;;
        11) reset_creds ;;
        12) exit 0 ;;
        *) echo -e "${RED}Opzione non valida${NC}"; sleep 1 ;;
    esac
done

