# 🔧 ERPNext + Cloudflare Tunnel - Configuração Detalhada

## O Problema: Headers de Proxy Não Funcionam

Quando você acessa seu ERPNext através de um tunnel Cloudflare, o servidor enxerga requisições vindo do IP do tunnel, não do cliente real. Isso pode causar:

❌ IP incorreto registrado nas sessões
❌ CORS errors
❌ Cloudflare headers sendo perdidos
❌ Rewrite de URLs incorreta

## A Solução: Headers de Proxy Configurados

Nessa configuração já está feito:

```yaml
# docker-compose.yml - Frontend (Nginx)
environment:
  - UPSTREAM_REAL_IP_ADDRESS=0.0.0.0/0
  - UPSTREAM_REAL_IP_HEADER=CF-Connecting-IP
  - UPSTREAM_REAL_IP_RECURSIVE=on
```

Isso significa:
- Aceita requisições de qualquer IP (0.0.0.0/0 = mundo)
- Lê o header `CF-Connecting-IP` (IP real do cliente enviado por Cloudflare)
- Recursivamente procura pelo IP real em múltiplos headers

## Configuração Cloudflare Tunnel

Seu arquivo `~/.cloudflared/config.yml` deve ter:

```yaml
ingress:
  - hostname: seu-dominio.com.br
    service: http://localhost:8090
    originRequest:
      httpHostHeader: seu-dominio.com.br
      # IMPORTANTE: Headers de Cloudflare
      headers:
        add:
          X-Forwarded-Proto: https
          X-Forwarded-For: ${CF_CONNECTING_IP}
          CF-Connecting-IP: ${CF_CONNECTING_IP}
      # Timeout para uploads grandes
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
```

## Headers Enviados por Cloudflare

Quando alguém acessa seu site através do Cloudflare Tunnel, estes headers são automaticamente adicionados:

| Header | Valor | Explicação |
|--------|-------|------------|
| `CF-Connecting-IP` | `203.0.113.195` | IP real do cliente |
| `X-Forwarded-For` | `203.0.113.195` | IP do cliente (compatibilidade) |
| `X-Forwarded-Proto` | `https` | Protocolo original (sempre HTTPS) |
| `CF-RAY` | `7f3a84c21d1234ef` | ID único da requisição |
| `CF-Request-ID` | `...` | ID interno Cloudflare |
| `CF-Visitor` | `{"scheme":"https"}` | Informações do visitante |

## ERPNext Configuração

Seu `docker-compose.yml` já tem:

```yaml
frontend:
  environment:
    # Isso faz o Nginx confiar nesses headers
    - UPSTREAM_REAL_IP_ADDRESS=0.0.0.0/0
    - UPSTREAM_REAL_IP_HEADER=CF-Connecting-IP
    - UPSTREAM_REAL_IP_RECURSIVE=on

    # Variáveis padrão
    - UPSTREAM_REAL_IP_RECURSIVE=off
    - PROXY_READ_TIMEOUT=120
    - CLIENT_MAX_BODY_SIZE=50m
    - ENABLE_GZIP=1
```

### O que cada uma faz:

- **UPSTREAM_REAL_IP_ADDRESS**: Aceita requisições desses IPs como "trusted"
- **UPSTREAM_REAL_IP_HEADER**: Qual header usar para pegar o IP real
- **UPSTREAM_REAL_IP_RECURSIVE**: Se deve procurar recursivamente em múltiplos IPs

## Testar a Configuração

### Test 1: Verificar se Headers estão sendo passados

```bash
# Substitua SEU_DOMINIO
curl -v https://seu-dominio.com.br/api/resource/System\ Settings

# Procure por estes headers na resposta:
# X-Forwarded-For: [seu-ip]
# X-Forwarded-Proto: https
# CF-Connecting-IP: [seu-ip]
```

### Test 2: IP Real no ERPNext

1. Vá em **Integrations > API**
2. Clique em **Make API Call**
3. Pegue seu IP real visitando https://ifconfig.me
4. No ERPNext, faça login e vá em **User > Last IP Address**
5. Deve mostrar seu IP real, não o do tunnel

### Test 3: WebSocket via Cloudflare

```bash
# Instale wscat
npm install -g wscat

# Teste conexão
wscat -c "wss://seu-dominio.com.br/socket.io/?EIO=4&transport=websocket"
# Deve conectar sem erro
```

## Problemas Comuns e Soluções

### ❌ Erro: "Invalid host header"

**Causa**: Host header não é válido
**Solução**:

```yaml
# cloudflare-tunnel config
originRequest:
  httpHostHeader: seu-dominio.com.br
```

### ❌ Erro: "Origin header check failed"

**Causa**: CORS está restritivo
**Solução**:

```yaml
# No docker-compose.yml
environment:
  - ENABLE_CORS=1
  - CORS_ALLOWED_ORIGINS=https://seu-dominio.com.br
```

### ❌ 502 Bad Gateway

**Causa**: Backend não responde rápido o suficiente
**Solução**:

```yaml
# Aumentar timeout
originRequest:
  connectTimeout: 60s
  tlsTimeout: 30s
```

### ❌ IP Real não aparece

**Causa**: Headers de proxy não estão sendo lidos
**Solução**:

```bash
# Verificar logs do frontend
docker logs erpnext-frontend

# Procure por linhas com "client_real_ip"
# Se não ver, o header não está sendo lido
```

## Segurança: Proteger contra Spoofing

⚠️ **IMPORTANTE**: Seu `UPSTREAM_REAL_IP_ADDRESS=0.0.0.0/0` significa confiar em qualquer IP. Isso é seguro APENAS se:

1. ✅ Você está usando Cloudflare Tunnel (IP é validado por Cloudflare)
2. ✅ Portas não estão expostas diretamente na internet
3. ✅ Firewall está fechado para acesso direto ao Docker

Se você expôr o Docker diretamente:

```yaml
# NÃO USE ISSO se expor para internet
UPSTREAM_REAL_IP_ADDRESS=0.0.0.0/0  # ❌ Inseguro

# USE ISTO em vez:
UPSTREAM_REAL_IP_ADDRESS=172.18.0.1  # ❌ Only Cloudflare tunnel gateway
```

Para Cloudflare Tunnel, é seguro deixar `0.0.0.0/0` porque Cloudflare valida os headers.

## Monitorar Headers em Tempo Real

```bash
# Aumentar log level do Nginx
docker exec erpnext-frontend sed -i 's/access_log \/dev\/stdout;/access_log \/dev\/stdout main;/g' /etc/nginx/conf.d/default.conf
docker restart erpnext-frontend

# Ver headers em tempo real
docker logs -f erpnext-frontend | grep -i "CF-Connecting\|X-Forwarded"
```

## Referências

- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Nginx Real IP Module](https://nginx.org/en/docs/http/ngx_http_realip_module.html)
- [ERPNext Reverse Proxy Setup](https://docs.erpnext.com/docs/user/manual/en/setup/tutorials/setup-wizard)
