# 🚀 ERPNext + WooCommerce Connector - Setup Completo

## ✅ O Que Foi Implementado

Todos os arquivos estão prontos para deploy no Portainer com Cloudflare Tunnel. Aqui está o que foi feito:

### 📁 Arquivos Criados/Modificados

| Arquivo | Status | Descrição |
|---------|--------|-----------|
| `entrypoint.sh` | ✨ **NOVO** | Script que cria site + instala apps automaticamente |
| `dockerfile` | ✏️ Atualizado | Agora usa entrypoint + healthcheck |
| `docker-compose.yml` | ✏️ Renovado | Versão 3.8 com 8 serviços completos |
| `.env.example` | ✨ NOVO | Template de variáveis para Portainer |
| `PORTAINER_SETUP.md` | ✨ NOVO | Guia passo-a-passo para deploy |
| `CLOUDFLARE_PROXY_SETUP.md` | ✨ NOVO | Configuração detalhada de headers |
| `USEFUL_COMMANDS.md` | ✨ NOVO | Comandos para troubleshooting |
| `post-deploy-checklist.sh` | ✨ NOVO | Script para testar após deploy |
| `cloudflare-tunnel-config.yml.example` | ✨ NOVO | Exemplo de config do Cloudflare |

### 🎯 Funcionalidades Implementadas

#### ✅ Auto-Setup do Site
```bash
# entrypoint.sh executa automaticamente:
1. Aguarda MariaDB estar pronto (até 60s)
2. Cria novo site se não existir
3. Instala ERPNext
4. Instala WooCommerce Connector
5. Executa migrations
6. Compila assets
7. Inicia o servidor
```

#### ✅ Configuração Cloudflare Tunnel
```yaml
# Headers de Proxy Configurados:
- UPSTREAM_REAL_IP_ADDRESS=0.0.0.0/0
- UPSTREAM_REAL_IP_HEADER=CF-Connecting-IP
- UPSTREAM_REAL_IP_RECURSIVE=on

# Resultado: IP real do cliente é capturado
```

#### ✅ Healthchecks Completos
```yaml
Serviços monitorados:
✓ MariaDB (mysqladmin ping)
✓ Redis Cache (redis-cli ping)
✓ Redis Queue (redis-cli ping)
✓ Backend (curl /api/resource/User)
✓ Frontend (curl / com HTTP 200)
✓ WebSocket (curl /socket.io/)
```

#### ✅ Otimizações de Performance
```yaml
- Redis com senhas seguras
- MariaDB com max_connections=500
- Nginx com gzip habilitado
- 8 serviços (backend, frontend, websocket, workers, scheduler)
- 4 workers & 4 threads configuráveis
```

#### ✅ Pronto para Portainer
```yaml
- Variáveis de ambiente externalizadas
- Containers nomeados para fácil identificação
- Volumes persistentes
- Health checks contínuos
- Suporte a .env file
```

---

## 🚀 Como Usar

### Passo 1: Preparar os Arquivos

```bash
# No seu servidor local, certifique-se que tem:
c:\dev\erpnext\novo\
├── entrypoint.sh          # ✨ Novo
├── dockerfile             # ✏️ Atualizado
├── docker-compose.yml     # ✏️ Renovado
├── .env.example           # ✨ Novo
├── PORTAINER_SETUP.md     # ✨ Novo
├── CLOUDFLARE_PROXY_SETUP.md
├── USEFUL_COMMANDS.md
└── post-deploy-checklist.sh
```

### Passo 2: Deploy no Portainer

1. **Abra o Portainer** → http://seu-portainer:9000
2. **Vá em Stacks** → **Add Stack**
3. **Cole o arquivo `docker-compose.yml`**
4. **Adicione as variáveis de ambiente:**

```
MYSQL_ROOT_PASSWORD=ErpN3xt#2026
REDIS_PASSWORD=redis#2026
FRAPPE_SITE_NAME=erpnext.local
ADMIN_PASSWORD=seu-admin-password
HTTP_HOST=seu-dominio.com.br
HTTP_PORT=8090
```

5. **Clique Deploy** e aguarde 2-3 minutos

### Passo 3: Acessar

```
http://localhost:8090        # Acesso local (teste)
https://seu-dominio.com.br   # Via Cloudflare Tunnel
```

**Login padrão:**
```
Usuário: Administrator
Senha: (valor de ADMIN_PASSWORD)
```

---

## 📊 Estrutura de Serviços

```
┌──────────────────────────────────┐
│  Cloudflare Tunnel (HTTPS)       │
│  seu-dominio.com.br              │
└────────────────┬─────────────────┘
                 │
        ┌────────▼─────────┐
        │ Nginx Frontend   │ Port 8090
        │ - Cache gzip     │
        │ - Proxy headers  │
        └────────┬─────────┘
                 │
        ┌────────▼─────────┐
        │ Gunicorn Backend │ :8000
        │ 4 workers        │
        └────────┬─────────┘
                 │
    ┌────────┬──┼──┬────────┬──────────┐
    │        │     │        │          │
┌────▼──┐┌────▼─┐┌───▼──┐┌─▼──┐┌──────▼──┐
│MariaDB││Redis ││NodeJS││Work││Schedule│
│ DB    ││Cache ││Socket││ers ││  Task  │
│       ││Queue ││ :9000││    ││        │
└───────┘└──────┘└──────┘└────┘└────────┘
```

---

## 📖 Documentação Incluída

| Documento | Para Quem | Leia Quando |
|-----------|-----------|------------|
| `PORTAINER_SETUP.md` | DevOps/Admin | Antes do primeiro deploy |
| `CLOUDFLARE_PROXY_SETUP.md` | DevOps | Se tiver problemas de headers |
| `USEFUL_COMMANDS.md` | Técnico | Durante troubleshooting |
| `post-deploy-checklist.sh` | QA/Tester | Após o deploy |

---

## 🔐 Segurança

### Senhas Padrão (MUDE APÓS DEPLOY!)

```
MariaDB Root: ErpN3xt#2026
Redis: redis#2026
Admin: admin@123
```

### Recomendações

1. ✅ Mude a senha do Admin logo após login
2. ✅ Configure duas-autenticação
3. ✅ Ative HTTPS (Cloudflare já faz isso)
4. ✅ Proteja o acesso ao Portainer
5. ✅ Mantenha backups regulares

---

## 🐛 Se Algo Não Funcionar

### Checklist Rápido

```bash
# 1. Ver status dos containers
docker ps -a | grep erpnext

# 2. Ver logs do backend
docker logs erpnext-backend | tail -20

# 3. Verificar healthchecks
docker inspect erpnext-backend | grep -A 5 "Health"

# 4. Testar conectividade
docker exec -it erpnext-backend curl http://redis-cache:6379
```

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Site não é criado | Veja logs: `docker logs erpnext-backend` |
| 502 Bad Gateway | Reinicie backend: `docker restart erpnext-backend` |
| WebSocket não funciona | Verifique: `docker logs erpnext-websocket` |
| Erro de conexão DB | Aguarde 30s, depois: `docker restart erpnext-db` |

---

## 📈 Performance Tips

```yaml
# Para aumentar performance, no Portainer:

# 1. Aumentar workers
WORKERS=8
THREADS=8

# 2. Aumentar timeout para uploads
PROXY_READ_TIMEOUT=180

# 3. Aumentar tamanho máximo de upload
CLIENT_MAX_BODY_SIZE=100m

# 4. Aumentar RAM do Redis (se necessário)
# Edite docker-compose.yml:
redis-cache:
  command: redis-server --maxmemory 2gb --maxmemory-policy allkeys-lru
```

---

## ✨ Próximos Passos

Após o deploy funcionar:

1. ✅ Mude as senhas padrão
2. ✅ Configure WooCommerce Connector
3. ✅ Configure backups automáticos
4. ✅ Configure SSL (Cloudflare já faz)
5. ✅ Crie usuários de acesso
6. ✅ Faça testes de carga

---

## 📞 Suporte

Se encontrar problemas:

1. Leia `PORTAINER_SETUP.md` - Seção Troubleshooting
2. Veja `USEFUL_COMMANDS.md` - Comandos para debug
3. Verifique logs em tempo real

---

## 📝 Versões

- **ERPNext**: v15.102.0
- **MariaDB**: 10.6
- **Redis**: 6.2-alpine
- **Docker Compose**: 3.8

---

**Status**: ✅ Pronto para produção
**Data**: 7 de abril de 2026
**Autor**: GitHub Copilot

🎉 Tudo pronto! Deploy com confiança no Portainer.
