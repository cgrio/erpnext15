#!/bin/bash
set -e

: "${BACKEND:=backend:8000}"
: "${SOCKETIO:=websocket:9000}"
: "${UPSTREAM_REAL_IP_ADDRESS:=127.0.0.1}"
: "${UPSTREAM_REAL_IP_HEADER:=X-Forwarded-For}"
: "${UPSTREAM_REAL_IP_RECURSIVE:=off}"
: "${FRAPPE_SITE_NAME_HEADER:=\$host}"
: "${PROXY_READ_TIMEOUT:=120}"
: "${CLIENT_MAX_BODY_SIZE:=50m}"
: "${FRAPPE_SITE_NAME:=erpnext.local}"

envsubst '
  ${BACKEND}
  ${SOCKETIO}
  ${UPSTREAM_REAL_IP_ADDRESS}
  ${UPSTREAM_REAL_IP_HEADER}
  ${UPSTREAM_REAL_IP_RECURSIVE}
  ${FRAPPE_SITE_NAME_HEADER}
  ${PROXY_READ_TIMEOUT}
  ${CLIENT_MAX_BODY_SIZE}
  ${FRAPPE_SITE_NAME}
' < /templates/nginx/frappe.conf.template > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
