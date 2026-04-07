# Guia Definitivo: ERPNext 15 + WooCommerce Connector no Docker

Este guia garante que o ambiente suba limpo, já com o woocommerceconnector instalado, e com senhas de força média.

---

## 1. Dockerfile

```
# Usa a imagem oficial do ERPNext v15 como base
FROM frappe/erpnext:v15.10.0

USER frappe

# Atualiza pip e instala dependências de build
RUN ./env/bin/python -m pip install --upgrade pip \
    && ./env/bin/python -m pip install flit_core setuptools wheel

# Baixa o WooCommerce Connector
RUN bench get-app --skip-assets https://github.com/drzewkopl/woocommerceconnector.git

# Instala o app forçando o modo legacy do pip
RUN PIP_USE_PEP517=0 ./env/bin/python -m pip install --no-build-isolation -e apps/woocommerceconnector

# Garante que os apps estão registrados
RUN echo "frappe" > sites/apps.txt \
    && echo "erpnext" >> sites/apps.txt \
    && echo "woocommerceconnector" >> sites/apps.txt
```

---

## 2. docker-compose.yml

```
version: '3'

services:
  db:
    image: mariadb:10.6
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --skip-character-set-client-handshake
    environment:
      - MYSQL_ROOT_PASSWORD=ErpN3xt#2026
    volumes:
      - db-data:/var/lib/mysql

  redis-cache:
    image: redis:6.2-alpine

  backend:
    build:
      context: .
      dockerfile: Dockerfile
    image: erpnext-custom-woo:latest
    environment:
      - DB_HOST=db
      - REDIS_CACHE=redis-cache:6379
    volumes:
      - sites-data:/home/frappe/frappe-bench/sites
    depends_on:
      - db
      - redis-cache

volumes:
  db-data:
  sites-data:
```

---

## 3. Subindo o ambiente

1. Suba os containers:
   ```bash
   docker-compose up -d
   ```

2. Crie o site (ajuste o nome se quiser):
   ```bash
   docker exec -u frappe -it [ID_BACKEND] bench new-site erpnext.local --admin-password ErpAdm#2026 --mariadb-root-password ErpN3xt#2026 --no-mariadb-socket
   ```

3. Instale os apps:
   ```bash
   docker exec -u frappe -it [ID_BACKEND] bench --site erpnext.local install-app erpnext
   docker exec -u frappe -it [ID_BACKEND] bench --site erpnext.local install-app woocommerceconnector
   ```

---

## 4. Senhas de força média usadas
- MariaDB root: `ErpN3xt#2026`
- Admin do site: `ErpAdm#2026`

---

## 5. Dicas finais
- Se precisar resetar tudo, rode: `docker-compose down -v && docker-compose up --build -d`
- Para logs de erro: `sites/erpnext.local/logs/web.error.log`
- Sempre rode `bench migrate` e `bench build` após atualizações de apps.

---

Pronto! Ambiente pronto para uso e reinstalação sem surpresas.
