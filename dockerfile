# Usa a imagem oficial do ERPNext v15 como base
FROM frappe/erpnext:v15.102.0

USER root

# Instala nginx e toolchain de build para assets do Frappe/ERPNext
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx gettext-base nodejs npm \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

# 1. Preparar o ambiente virtual com as dependências de build que faltam
RUN ./env/bin/python -m pip install --upgrade pip \
    && ./env/bin/python -m pip install flit_core setuptools wheel

# 2. Baixar os apps (WooCommerce Connector)
# Evita bench get-app aqui porque ele usa uv com build isolado e falha nesse app
RUN git clone --depth 1 https://github.com/drzewkopl/woocommerceconnector.git apps/woocommerceconnector

# 3. Instalação FORÇADA para evitar o erro de build backend/pip not found
# Usamos as flags que descobrimos para ignorar o isolamento de build
RUN PIP_USE_PEP517=0 ./env/bin/python -m pip install --no-build-isolation -e apps/woocommerceconnector

# 4. Garantir que os apps estejam registrados no arquivo de sistema
RUN echo "frappe" > sites/apps.txt \
    && echo "erpnext" >> sites/apps.txt \
    && echo "woocommerceconnector" >> sites/apps.txt

# 5. Copiar entrypoint script
USER root
COPY entrypoint.sh /home/frappe/entrypoint.sh
RUN chmod +x /home/frappe/entrypoint.sh

# 6. Copiar nginx frontend
USER root
COPY resources/core/nginx/nginx-template.conf /templates/nginx/frappe.conf.template
COPY resources/core/nginx/nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint.sh
RUN chmod 755 /usr/local/bin/nginx-entrypoint.sh

# Voltar para o usuário frappe para o runtime
USER frappe

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/api/resource/User || exit 1

ENTRYPOINT ["/home/frappe/entrypoint.sh"]
CMD ["/home/frappe/frappe-bench/env/bin/gunicorn", "--chdir=/home/frappe/frappe-bench/sites", "--bind=0.0.0.0:8000", "--threads=4", "--workers=2", "--worker-class=gthread", "--worker-tmp-dir=/dev/shm", "--timeout=120", "--preload", "frappe.app:application"]








