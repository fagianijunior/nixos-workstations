#! /run/current-system/sw/bin/bash

# Script para gerar relatório diário de tarefas com IA
# Pode ser executado manualmente ou via cron/systemd timer

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_SCRIPT="$SCRIPT_DIR/ai-assistant.py"
REPORT_DIR="$HOME/.local/share/task-reports"
DATE=$(date +%Y-%m-%d)
REPORT_FILE="$REPORT_DIR/daily-report-$DATE.md"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verifica se o Ollama está rodando
check_ollama() {
    if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        error "Ollama não está rodando. Inicie com: systemctl start ollama"
        return 1
    fi
    
    # Verifica se o modelo está disponível
    if ! curl -s http://localhost:11434/api/tags | grep -q "llama3.2:3b"; then
        warning "Modelo llama3.2:3b não encontrado. Baixando..."
        ollama pull llama3.2:3b
    fi
}

# Cria diretório de relatórios
setup_directories() {
    mkdir -p "$REPORT_DIR"
}

# Gera relatório diário
generate_report() {
    log "Gerando relatório diário de tarefas..."
    
    cat > "$REPORT_FILE" << EOF
# Relatório Diário de Tarefas - $(date +'%d/%m/%Y')

Gerado automaticamente em $(date +'%d/%m/%Y às %H:%M:%S')

## 📊 Análise Geral

EOF
    
    # Executa análise da IA
    if python3 "$AI_SCRIPT" analyze >> "$REPORT_FILE" 2>/dev/null; then
        echo "" >> "$REPORT_FILE"
        echo "## 📅 Plano Diário Sugerido" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        # Executa plano diário
        python3 "$AI_SCRIPT" plan >> "$REPORT_FILE" 2>/dev/null
        
        log "Relatório salvo em: $REPORT_FILE"
    else
        error "Falha ao gerar análise da IA"
        return 1
    fi
}

# Mostra resumo no terminal
show_summary() {
    log "Resumo das tarefas:"
    
    # Estatísticas básicas
    local pending=$(task count status:pending 2>/dev/null || echo "0")
    local overdue=$(task count status:pending due.before:now 2>/dev/null || echo "0")
    local today=$(task count status:pending due:today 2>/dev/null || echo "0")
    local high_priority=$(task count status:pending priority:H 2>/dev/null || echo "0")
    
    echo -e "  📋 Tarefas pendentes: ${BLUE}$pending${NC}"
    echo -e "  ⚠️  Tarefas atrasadas: ${RED}$overdue${NC}"
    echo -e "  📅 Vencendo hoje: ${YELLOW}$today${NC}"
    echo -e "  🔥 Alta prioridade: ${RED}$high_priority${NC}"
    
    if [[ -f "$REPORT_FILE" ]]; then
        echo -e "\n📄 Relatório completo: ${BLUE}$REPORT_FILE${NC}"
    fi
}

# Envia notificação (se disponível)
send_notification() {
    if command -v notify-send >/dev/null 2>&1; then
        local pending=$(task count status:pending 2>/dev/null || echo "0")
        local overdue=$(task count status:pending due.before:now 2>/dev/null || echo "0")
        
        local message="$pending tarefas pendentes"
        if [[ "$overdue" -gt 0 ]]; then
            message="$message, $overdue atrasadas"
        fi
        
        notify-send "📋 Relatório de Tarefas" "$message" -t 5000
    fi
}

# Função principal
main() {
    log "Iniciando relatório diário de tarefas com IA"
    
    # Verifica dependências
    if ! command -v task >/dev/null 2>&1; then
        error "Taskwarrior não está instalado"
        exit 1
    fi
    
    if ! command -v python3 >/dev/null 2>&1; then
        error "Python3 não está instalado"
        exit 1
    fi
    
    # Setup
    setup_directories
    
    # Verifica Ollama
    if ! check_ollama; then
        warning "Ollama não disponível, gerando relatório básico..."
        show_summary
        exit 0
    fi
    
    # Gera relatório com IA
    if generate_report; then
        show_summary
        send_notification
        log "Relatório diário concluído com sucesso!"
    else
        error "Falha ao gerar relatório"
        exit 1
    fi
}

# Executa se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi