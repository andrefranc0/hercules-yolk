#!/bin/bash

set -e

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup"
echo "===================================="

echo "Configurando arquivos..."

mkdir -p conf/import

cat > conf/import/login-server.conf <<EOF
login_port: ${LOGIN_PORT}
account.engine: auto
account.sql.db_hostname: ${MYSQL_HOST}
account.sql.db_port: ${MYSQL_PORT}
account.sql.db_username: ${MYSQL_USER}
account.sql.db_password: ${MYSQL_PASSWORD}
account.sql.db_database: ${MYSQL_DATABASE}
EOF

cat > conf/import/char-server.conf <<EOF
userid: ${SERVER_USERID}
passwd: ${SERVER_PASSWORD}
server_name: ${SERVER_NAME}
login_port: ${LOGIN_PORT}
char_ip: ${SERVER_IP}
char_port: ${CHAR_PORT}
EOF

cat > conf/import/map-server.conf <<EOF
userid: ${SERVER_USERID}
passwd: ${SERVER_PASSWORD}
char_ip: ${SERVER_IP}
char_port: ${CHAR_PORT}
map_ip: ${SERVER_IP}
map_port: ${MAP_PORT}
EOF

cat > conf/import/inter-server.conf <<EOF
sql.db_hostname: ${MYSQL_HOST}
sql.db_port: ${MYSQL_PORT}
sql.db_username: ${MYSQL_USER}
sql.db_password: ${MYSQL_PASSWORD}
sql.db_database: ${MYSQL_DATABASE}
EOF

echo "===================================="
echo "Iniciando servidores..."
echo "===================================="

# executa direto da imagem
/opt/hercules/login-server &
sleep 3

/opt/hercules/char-server &
sleep 3

exec /opt/hercules/map-server
