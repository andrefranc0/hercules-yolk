#!/bin/bash

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup"
echo "===================================="

echo "Copiando arquivos do build (opt -> container)..."

# binários
cp -f /opt/hercules/login-server .
cp -f /opt/hercules/char-server .
cp -f /opt/hercules/map-server .

# pastas necessárias
cp -r /opt/hercules/sql-files .
cp -r /opt/hercules/conf .

# garante import existe
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
EOF

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
