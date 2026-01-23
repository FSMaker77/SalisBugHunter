#!/bin/bash

# --- INIZIO PROTEZIONE AUTOMATICA ---
if [ -z "$TMUX" ]; then                                   # <-- Se non sono in Tmux
  echo "Attivazione scudo automatico (Tmux)..."           # <-- Avvisa l'utente
  tmux attach -t SalisSession || tmux new -s SalisSession ./salisbughunter.sh  # <-- Crea o aggancia sessione
  exit                                                    # <-- Chiudi la sessione non protetta
fi
# --- FINE PROTEZIONE AUTOMATICA ---

# ==========================================
# SALISBUGHUNTER v2.0 - AUTOMATION TOOL
# ==========================================

# Colori per il testo
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Percorsi e Config
GO_BIN="$HOME/go/bin"
CONFIG_FILE="$HOME/.salis_config"
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Funzione Header
show_header() {
    clear
    echo -e "${RED}======================================================${NC}"
    echo -e "${RED}      SALISBUGHUNTER v2.0 - BUG BOUNTY AUTOMATION        ${NC}"
    echo -e "${RED}======================================================${NC}"
    
    # Check rapido credenziali
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}[*] Credenziali HackerOne configurate.${NC}"
    else
        echo -e "${YELLOW}[!] Credenziali NON configurate.${NC}"
    fi

    echo -e "${BLUE}Target attivi:${NC} $(wc -l < targets.txt 2>/dev/null || echo 0)"
    echo -e "${BLUE}Siti vivi:${NC}     $(wc -l < subs_live.txt 2>/dev/null || echo 0)"
    echo ""
}

# 0. Gestione Credenziali (La novità)
check_creds() {
    # Se il file config esiste, carichiamo le variabili
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        # Se non esiste, chiediamo le credenziali e le salviamo
        echo -e "${YELLOW}[*] Prima configurazione: Inserisci le tue API HackerOne${NC}"
        echo -e "Le credenziali verranno salvate in $CONFIG_FILE e non dovrai più inserirle."
        echo ""
        read -p "Inserisci H1 Username: " H1_USER_INPUT
        read -p "Inserisci H1 API Key: " H1_KEY_INPUT
        
        # Salviamo nel file
        echo "export H1_USER=\"$H1_USER_INPUT\"" > "$CONFIG_FILE"
        echo "export H1_KEY=\"$H1_KEY_INPUT\"" >> "$CONFIG_FILE"
        
        # Carichiamo
        source "$CONFIG_FILE"
        echo -e "${GREEN}[V] Credenziali salvate!${NC}"
        sleep 1
    fi
}

reset_creds() {
    rm -f "$CONFIG_FILE"
    echo -e "${RED}[!] Credenziali rimosse. Le reinserirai al prossimo avvio.${NC}"
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

# 2. Scarica Scope HackerOne (RAW)
get_scope_raw() {
    check_creds # Controlla se abbiamo user/key prima di partire
    
    echo -e "${BLUE}[*] Download Scope da HackerOne in corso...${NC}"
    echo -e "Utente: $H1_USER"
    
    # Usa le variabili caricate dal file config
    $GO_BIN/bbscope h1 -u "$H1_USER" -t "$H1_KEY" > scope_raw.txt
    
    lines=$(wc -l < scope_raw.txt)
    echo -e "${GREEN}[V] Download finito. Scaricate $lines righe in scope_raw.txt${NC}"
    read -p "Premi Invio..."
}

# 3. Scrematura Wildcards
filter_wildcards() {
    if [ ! -f scope_raw.txt ]; then
        echo -e "${RED}[!] Errore: Manca scope_raw.txt. Esegui prima il punto 2.${NC}"
        read -p "Premi Invio..."
        return
    fi

    echo -e "${BLUE}[*] Estrazione delle Wildcards (*.domain.com)...${NC}"
    grep -o '\*\.[a-zA-Z0-9._-]*' scope_raw.txt | sed 's/^\*\.//' | sort -u > targets.txt
    
    count=$(wc -l < targets.txt)
    echo -e "${GREEN}[V] Scrematura completata!${NC}"
    echo -e "${GREEN}[V] Hai $count aziende/domini principali pronti in targets.txt${NC}"
    read -p "Premi Invio..."
}

# 4. Recon (Subfinder + Httpx)
run_recon() {
    if [ ! -f targets.txt ]; then
        echo -e "${RED}[!] Errore: Manca targets.txt. Esegui prima la scrematura (punto 3).${NC}"
        read -p "Premi Invio..."
        return
    fi

    echo -e "${BLUE}[*] 1. Subfinder (Cerca sottodomini)...${NC}"
    $GO_BIN/subfinder -dL targets.txt -silent -o subs_all.txt
    
    echo -e "${BLUE}[*] 2. Httpx (Filtra siti vivi)...${NC}"
    $GO_BIN/httpx -l subs_all.txt -silent -threads 100 -rate-limit 150 -title -tech-detect -status-code -o subs_live.txt
    
    live_count=$(wc -l < subs_live.txt)
    echo -e "${GREEN}[V] Recon finita! $live_count siti vivi salvati in subs_live.txt${NC}"
    read -p "Premi Invio..."
}

# 5. Scansione Vulnerabilità (Nuclei)
run_scan() {
    if [ ! -f subs_live.txt ]; then
        echo -e "${RED}[!] Errore: Manca subs_live.txt. Esegui prima la Recon (punto 4).${NC}"
        read -p "Premi Invio..."
        return
    fi

    echo -e "${RED}[!!!] AVVIO NUCLEI (CRITICAL & HIGH) [!!!]${NC}"
    $GO_BIN/nuclei -l subs_live.txt -s critical,high -o BUGS_SALIS.txt
    
    echo -e "${GREEN}[V] Scansione terminata. Controlla BUGS_SALIS.txt${NC}"
    read -p "Premi Invio..."
}

# 6. Pipeline Automatica (Tutto insieme)
run_full() {
    check_creds # Verifica credenziali all'inizio
    
    echo -e "${YELLOW}Questa opzione esegue: Download -> Scrematura -> Recon -> Scan${NC}"
    read -p "Premi Invio per partire (o CTRL+C per annullare)..."
    
    echo -e "${BLUE}[1/4] Download Scope...${NC}"
    $GO_BIN/bbscope h1 -u "$H1_USER" -t "$H1_KEY" > scope_raw.txt
    
    echo -e "${BLUE}[2/4] Scrematura...${NC}"
    grep -o '\*\.[a-zA-Z0-9._-]*' scope_raw.txt | sed 's/^\*\.//' | sort -u > targets.txt
    
    echo -e "${BLUE}[3/4] Recon (Subfinder + Httpx)...${NC}"
    $GO_BIN/subfinder -dL targets.txt -silent | \
    $GO_BIN/httpx -silent -threads 100 -rate-limit 150 -o subs_live.txt
    
    echo -e "${RED}[4/4] Scan Nuclei...${NC}"
    $GO_BIN/nuclei -l subs_live.txt -s critical,high -o BUGS_SALIS.txt
    
    echo -e "${GREEN}[V] TUTTO FINITO! Controlla BUGS_SALIS.txt${NC}"
    read -p "Premi Invio..."
}

# Loop del Menù
while true; do
    show_header
    echo "1. Installazione Completa (Go + Tools)"
    echo "2. Scarica Scope Grezzo (Bbscope)"
    echo "3. Scrematura Wildcards (Crea targets.txt)"
    echo "4. Reconnaissance (Subfinder -> Httpx)"
    echo "5. Vulnerability Scanning (Nuclei)"
    echo "6. AUTO-PILOTA (Download -> Scan)"
    echo "------------------------------------"
    echo "8. Configura/Resetta Credenziali H1"
    echo "9. Esci"
    echo ""
    read -p "SalisBugHunter > Scegli: " choice

    case $choice in
        1) install_tools ;;
        2) get_scope_raw ;;
        3) filter_wildcards ;;
        4) run_recon ;;
        5) run_scan ;;
        6) run_full ;;
        8) reset_creds ;;
        9) exit 0 ;;
        *) echo -e "${RED}Opzione non valida${NC}"; sleep 1 ;;
    esac

done
