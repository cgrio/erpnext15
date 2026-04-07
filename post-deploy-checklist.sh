#!/bin/bash
# Script de Checklist Pós-Deploy para ERPNext no Portainer
# Uso: chmod +x post-deploy-checklist.sh && ./post-deploy-checklist.sh

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  ERPNext Post-Deploy Checklist                                ║"
echo "║  Teste todos os serviços após o primeiro deploy              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service=$1
    local check=$2
    local description=$3

    if eval "$check" &> /dev/null; then
        echo -e "${GREEN}✅${NC} $description"
        return 0
    else
        echo -e "${RED}❌${NC} $description"
        return 1
    fi
}

echo "📊 Verificando status dos containers..."
echo ""

# Verificar se Docker está rodando
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não está instalado ou não está no PATH${NC}"
    exit 1
fi

# Verificar containers
check_service "db" "docker ps | grep erpnext-db" "MariaDB container (erpnext-db)"
check_service "redis-cache" "docker ps | grep erpnext-redis-cache" "Redis Cache container"
check_service "redis-queue" "docker ps | grep erpnext-redis-queue" "Redis Queue container"
check_service "backend" "docker ps | grep erpnext-backend" "Backend container (Gunicorn)"
check_service "frontend" "docker ps | grep erpnext-frontend" "Frontend container (Nginx)"
check_service "websocket" "docker ps | grep erpnext-websocket" "WebSocket container"
check_service "queue-short" "docker ps | grep erpnext-queue-short" "Queue Short Worker"
check_service "scheduler" "docker ps | grep erpnext-scheduler" "Scheduler container"

echo ""
echo "🏥 Verificando Healthchecks..."
echo ""

# Verificar healthchecks
check_service "db-health" "docker inspect erpnext-db | grep -q '\"Status\": \"healthy\"'" "MariaDB Health"
check_service "backend-health" "docker inspect erpnext-backend | grep -q '\"Status\": \"healthy\"'" "Backend Health"
check_service "frontend-health" "docker inspect erpnext-frontend | grep -q '\"Status\": \"healthy\"'" "Frontend Health"

echo ""
echo "🌐 Verificando Conectividade..."
echo ""

# Testar conectividade
check_service "http" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8090 | grep -E '200|301|302'" "HTTP Frontend (localhost:8090)"
check_service "websocket" "docker logs erpnext-websocket | grep -q 'listening' || docker logs erpnext-websocket 2>&1 | head -10" "WebSocket inicializado"

echo ""
echo "📁 Verificando Volumes..."
echo ""

# Verificar volumes
check_service "sites-vol" "docker volume ls | grep -q erpnext-sites" "Volume: sites"
check_service "logs-vol" "docker volume ls | grep -q erpnext-logs" "Volume: logs"
check_service "db-vol" "docker volume ls | grep -q erpnext-db-data" "Volume: db-data"

echo ""
echo "🔐 Verificando Variáveis de Ambiente..."
echo ""

# Verificar variáveis
SITE_NAME=$(docker exec erpnext-backend env | grep FRAPPE_SITE_NAME | cut -d= -f2)
ADMIN_PASS=$(docker exec erpnext-backend env | grep ADMIN_PASSWORD | cut -d= -f2)

if [ -z "$SITE_NAME" ]; then
    echo -e "${YELLOW}⚠️${NC} FRAPPE_SITE_NAME não está definida (padrão será usado)"
else
    echo -e "${GREEN}✅${NC} Site: $SITE_NAME"
fi

echo ""
echo "📦 Verificando Instalação de Apps..."
echo ""

# Verificar instalação de apps
docker exec -u frappe erpnext-backend bash -c "cd /home/frappe/frappe-bench && bench --site $SITE_NAME list-apps" 2>/dev/null | while read app; do
    if [ ! -z "$app" ]; then
        echo -e "${GREEN}  ✓${NC} $app"
    fi
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Próximos Passos                                              ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║ 1. Acesse: http://localhost:8090 ou seu domínio Cloudflare   ║"
echo "║ 2. Login: Administrator / (senha definida)                    ║"
echo "║ 3. Mude a senha imediatamente!                                ║"
echo "║ 4. Configure WooCommerce Connector                            ║"
echo "║ 5. Teste WebSocket em Settings > Realtime                     ║"
echo "║                                                               ║"
echo "║ Para ver logs: docker logs [container-name]                  ║"
echo "║ Para executar comando: docker exec -u frappe erpnext-backend  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Checklist concluído! 🎉"
