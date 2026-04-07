#!/bin/bash
set -e

cd /home/frappe/frappe-bench

echo "=== ERPNext Initialization Started ==="

# 1. Aguardar banco de dados estar pronto
echo "⏳ Aguardando MariaDB inicializar..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if mysqladmin ping -h "${DB_HOST}" -u root -p"${MYSQL_ROOT_PASSWORD}" &> /dev/null; then
        echo "✅ MariaDB conectado"
        break
    fi
    attempt=$((attempt + 1))
    echo "Tentativa $attempt/$max_attempts..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Erro: MariaDB não respondeu após ${max_attempts} tentativas"
    exit 1
fi

sleep 3

# 1.5 Garantir que a configuração global do bench aponte para os serviços do compose
echo "🔧 Gravando configuração global do bench..."
bench set-config -g db_host "${DB_HOST}" || true
bench set-config -g db_port "${DB_PORT:-3306}" || true
bench set-config -g redis_cache "redis://redis-cache:6379" || true
bench set-config -g redis_queue "redis://redis-queue:6379" || true
bench set-config -g redis_socketio "redis://redis-socketio:6379" || true

# 2. Verificar se site já existe
SITE_NAME="${FRAPPE_SITE_NAME:-erpnext.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin@123}"
DB_PASSWORD="${DB_PASSWORD:-${MYSQL_ROOT_PASSWORD}}"

echo "🔍 Verificando se site '$SITE_NAME' existe..."

if [ ! -f "sites/${SITE_NAME}/site_config.json" ]; then
    echo "📦 Criando novo site: $SITE_NAME"

    bench new-site "$SITE_NAME" \
        --admin-password "$ADMIN_PASSWORD" \
        --mariadb-root-password "$DB_PASSWORD" \
        --mariadb-user-host-login-scope='%' \
        --force \
        || echo "⚠️  Site criação falhou, pode já existir"

    sleep 3

    echo "📥 Instalando ERPNext..."
    bench --site "$SITE_NAME" install-app erpnext || true

    echo "📥 Instalando WooCommerce Connector..."
    bench --site "$SITE_NAME" install-app woocommerceconnector || true

    echo "🔄 Executando migrações..."
    bench --site "$SITE_NAME" migrate || true

    echo "🏗️ Compilando assets..."
    bench build --production || true

    echo "✅ Site criado com sucesso!"
else
    echo "✅ Site já existe: $SITE_NAME"
fi

# 3. Executar comando passado
echo ""
echo "🚀 Iniciando comando: $@"
exec "$@"
