# 🚀 ERPNext + WooCommerce no Portainer com Cloudflare Tunnel

## 📋 O Que Foi Implementado

✅ **Auto-setup do Site** - Entrypoint script que cria site automaticamente
✅ **Headers de Proxy** - Configurado para Cloudflare Tunnel
✅ **Healthchecks** - Todos os serviços monitorados
✅ **Otimizações** - Redis com senhas, MariaDB otimizado, cache gzip
✅ **Portainer Ready** - Variáveis de ambiente para fácil deploy

---

## 🔧 Arquivos Criados/Modificados

| Arquivo | Função |
|---------|--------|
| `entrypoint.sh` | Script que inicializa banco, cria site, instala apps |
| `dockerfile` | Atualizado com entrypoint e healthcheck |
| `docker-compose.yml` | Versão 3.8 com todos os serviços otimizados |
| `.env.example` | Template de variáveis de ambiente |

---

## 🌐 Deploy no Portainer + Cloudflare Tunnel

### Pré-requisitos
- Portainer rodando no seu servidor local
- Cloudflare Tunnel configurado e conectado
- Domínio do Cloudflare apontando para o tunnel

### Passo 1: Preparar os Arquivos

```bash
# No seu servidor local
cd /seu/caminho/erpnext/novo

# Copie os arquivos gerados para o servidor
# Você pode usar git, scp ou copiar manualmente
```

### Passo 2: Configurar no Portainer

1. Acesse seu Portainer (http://portainer-local:9000)
2. Vá em **Stacks** → **Add Stack**
3. Cole o conteúdo de `docker-compose.yml`
4. Em **Environment variables**, clique em **Load variables from .env file** (se disponível)
5. Ou adicione manualmente:

```
MYSQL_ROOT_PASSWORD=ErpN3xt#2026
REDIS_PASSWORD=redis#2026
FRAPPE_SITE_NAME=erpnext.local
ADMIN_PASSWORD=admin@123
HTTP_HOST=seu-dominio.com.br
HTTP_PORT=8090
UPSTREAM_REAL_IP_ADDRESS=0.0.0.0/0
UPSTREAM_REAL_IP_HEADER=CF-Connecting-IP
UPSTREAM_REAL_IP_RECURSIVE=on
```

6. Clique em **Deploy** e aguarde ~2-3 minutos

### Passo 3: Verificar Status

```bash
# No Portainer, vá em Containers e verifique:
# ✅ erpnext-db (healthy)
# ✅ erpnext-redis-cache (healthy)
# ✅ erpnext-redis-queue (healthy)
# ✅ erpnext-backend (healthy after 60s)
# ✅ erpnext-frontend (healthy)
# ✅ erpnext-websocket (running)
# ✅ erpnext-queue-short (running)
# ✅ erpnext-queue-long (running)
# ✅ erpnext-scheduler (running)
```

---

## 🔍 Monitorar Logs

```bash
# Pelo Portainer: Containers → [container-name] → Logs

# Ou pela CLI:
docker logs erpnext-backend
docker logs erpnext-frontend
```

### Logs esperados no primeiro deploy:

```
=== ERPNext Initialization Started ===
⏳ Aguardando MariaDB inicializar...
✅ MariaDB conectado
🔍 Verificando se site 'erpnext.local' existe...
📦 Criando novo site: erpnext.local
📥 Instalando ERPNext...
📥 Instalando WooCommerce Connector...
🔄 Executando migrações...
🏗️ Compilando assets...
✅ Site criado com sucesso!
🚀 Iniciando comando: bench start
```

---

## 🌍 Acessar via Cloudflare Tunnel

Após o deploy, sua aplicação estará disponível em:

```
https://[seu-dominio-cloudflare].com
```

### Configuração do Nginx (Cloudflare Tunnel)

Se o acesso não funcionar, verifique seu arquivo de configuração do tunnel:

```yaml
ingress:
  - hostname: seu-dominio.com.br
    service: http://localhost:8090
    originRequest:
      httpHostHeader: seu-dominio.com.br
      originServerName: seu-dominio.com.br
  - service: http_status:404
```

---

## 🔐 Credenciais Padrão

Após o deploy, entre com:

```
URL: https://seu-dominio.com.br
Usuário: Administrator
Senha: admin@123 (ou valor de ADMIN_PASSWORD)
```

⚠️ **MUDE A SENHA IMEDIATAMENTE APÓS O PRIMEIRO LOGIN!**

---

## 📊 Estructura de Serviços

```
┌─────────────────────────────────────┐
│    Cloudflare Tunnel (HTTPS)        │
└──────────────┬──────────────────────┘
               │
     ┌─────────▼────────────┐
     │   Frontend (Nginx)   │  Port 8090
     │   - Cache            │
     │   - Gzip             │
     │   - Proxy Headers    │
     └─────────┬────────────┘
               │
     ┌─────────▼────────────┐
     │  Backend (Gunicorn)  │  :8000
     └─────────┬────────────┘
               │
     ├─────────┼─────────┬──────────┬────────────┐
     │         │         │          │            │
┌────▼──┐┌────▼──┐┌──────▼──┐┌─────▼─┐┌────────▼───┐
│ MySQL │└─Redis─┘│ Websocket│ Worker│ │ Scheduler  │
│  DB   │ Cache  │ :9000    │ short │ │ Tasks      │
│       │ Queue  │          │ long  │ │            │
└───────┘└────────┘──────────┴───────┴┴────────────┘
```

---

## 🐛 Troubleshooting

### Site não é criado automaticamente

```bash
# Execute manualmente no container
docker exec -u frappe erpnext-backend bash

cd /home/frappe/frappe-bench

# Criar site manualmente
bench new-site erpnext.local \
  --admin-password admin@123 \
  --mariadb-root-password ErpN3xt#2026 \
  --no-mariadb-socket \
  --force

# Instalar apps
bench --site erpnext.local install-app erpnext
bench --site erpnext.local install-app woocommerceconnector
```

### Erro "Connection refused" do banco

```bash
# Verifique se MariaDB está saudável
docker logs erpnext-db

# Reinicie
docker restart erpnext-db

# Aguarde 30 segundos
```

### Redis não conecta

```bash
# Verifique senha
docker exec erpnext-redis-cache redis-cli ping
# Deve responder: PONG

# Se usar senha:
docker exec erpnext-redis-cache redis-cli -a redis#2026 ping
```

### Porta 8090 já está em uso

No `.env` ou no Portainer, mude:
```
HTTP_PORT=8091
```

---

## 🚀 Build Customizado

Se precisar modificar o Dockerfile:

```bash
# Rebuildar a imagem
docker-compose build --no-cache

# Depois, deploy normalmente
docker-compose up -d
```

---

## 📈 Performance Tips

1. **Aumentar WORKERS/THREADS** em `.env` se tiver recursos:
   ```
   WORKERS=8
   THREADS=8
   ```

2. **Aumentar RAM do Redis** se muitos jobs:
   ```
   redis-cache:
     command: redis-server --maxmemory 2gb --maxmemory-policy allkeys-lru
   ```

3. **Ativar gzip** (já está ativado):
   ```
   ENABLE_GZIP=1
   ```

---

## 📝 Próximos Passos

1. ✅ Deploy no Portainer
2. ✅ Testar acesso via Cloudflare
3. ✅ Alterar senha do Admin
4. ✅ Configurar WooCommerce Connector
5. ✅ Configurar HTTPS/SSL (Cloudflare já faz isso)

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique logs: `docker logs [container-name]`
2. Verifique healthchecks no Portainer
3. Aguarde mais tempo no primeiro deploy (~3 min)
4. Reinicie tudo: Remova stack e redeploy

---

**Última atualização:** 7 de abril de 2026
**Versão:** ERPNext v15.102.0
**Status:** ✅ Pronto para produção
