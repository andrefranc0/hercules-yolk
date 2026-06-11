#!/bin/bash

echo "===== DEBUG ====="
echo "PWD:"
pwd

echo ""
echo "USER:"
whoami

echo ""
echo "ROOT:"
ls -la /

echo ""
echo "/home:"
ls -la /home

echo ""
echo "/home/container:"
ls -la /home/container

echo ""
echo "/opt:"
ls -la /opt

echo ""
echo "/opt/hercules:"
ls -la /opt/hercules

echo ""
echo "MYSQL VARIABLES:"
env | grep -i mysql

echo "================="

cd /opt/hercules

echo "===================================="
echo "Hercules Pterodactyl Startup"
echo "===================================="

mkdir -p conf/import

echo "Gerando arquivos de configuração..."

cat > conf/import/login-server.conf << EOF
login_port: ${LOGIN_PORT}
account.engine: auto
account.sql.db_hostname: ${MYSQL_HOST}
account.sql.db_port: ${MYSQL_PORT}
account.sql.db_username: ${MYSQL_USER}
account.sql.db_password: ${MYSQL_PASSWORD}
account.sql.db_database: ${MYSQL_DATABASE}
EOF

cat > conf/import/char-server.conf << EOF
userid: ${SERVER_USERID}
passwd: ${SERVER_PASSWORD}
server_name: ${SERVER_NAME}
login_port: ${LOGIN_PORT}
char_ip: ${SERVER_IP}
char_port: ${CHAR_PORT}
EOF

cat > conf/import/map-server.conf << EOF
userid: ${SERVER_USERID}
passwd: ${SERVER_PASSWORD}
char_ip: ${SERVER_IP}
char_port: ${CHAR_PORT}
map_ip: ${SERVER_IP}
map_port: ${MAP_PORT}
EOF

cat > conf/import/inter-server.conf << EOF
sql.db_hostname: ${MYSQL_HOST}
sql.db_port: ${MYSQL_PORT}
sql.db_username: ${MYSQL_USER}
sql.db_password: ${MYSQL_PASSWORD}
sql.db_database: ${MYSQL_DATABASE}

char_server_ip: ${MYSQL_HOST}
char_server_port: ${MYSQL_PORT}
char_server_id: ${MYSQL_USER}
char_server_pw: ${MYSQL_PASSWORD}
char_server_db: ${MYSQL_DATABASE}

map_server_ip: ${MYSQL_HOST}
map_server_port: ${MYSQL_PORT}
map_server_id: ${MYSQL_USER}
map_server_pw: ${MYSQL_PASSWORD}
map_server_db: ${MYSQL_DATABASE}

log_db_ip: ${MYSQL_HOST}
log_db_port: ${MYSQL_PORT}
log_db_id: ${MYSQL_USER}
log_db_pw: ${MYSQL_PASSWORD}
log_db_db: ${MYSQL_DATABASE}
EOF

echo ""
echo "===== GENERATED LOGIN CONFIG ====="
cat conf/import/login-server.conf

echo ""
echo "===== GENERATED INTER CONFIG ====="
cat conf/import/inter-server.conf

if [ ! -f /home/container/.database_initialized ]; then
    echo "===================================="
    echo "Importando banco de dados..."
    echo "===================================="

    mysql -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < sql-files/main.sql

    mysql -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < sql-files/item_db.sql

    mysql -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < sql-files/mob_db.sql

    mysql -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < sql-files/logs.sql

    touch /home/container/.database_initialized

    echo "Banco importado com sucesso."
fi

echo "===================================="
echo "Iniciando Login Server..."
echo "===================================="

./login-server &
sleep 5

echo "===================================="
echo "Iniciando Char Server..."
echo "===================================="

./char-server &
sleep 5

echo "===================================="
echo "Iniciando Map Server..."
echo "===================================="

exec ./map-server
