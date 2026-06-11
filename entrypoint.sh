#!/bin/bash

set -e

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup"
echo "===================================="

# 1. Copia a estrutura base da imagem para o diretório de trabalho do painel
echo "Verificando e sincronizando arquivos base do Hercules..."
for dir in conf db npc plugins sql-files; do
    if [ ! -d "$dir" ]; then
        echo "Copiando pasta $dir para /home/container..."
        cp -r /opt/hercules/$dir ./
    fi
done

# Copia os binários atualizados compilados na imagem para a raiz de execução
cp /opt/hercules/*-server ./ 2>/dev/null || true

echo "Configurando arquivos de import..."
mkdir -p conf/import

# Mapeamento dinâmico: Prioriza o banco nativo do Pterodactyl (DB_*), senão usa o seu do Egg (MYSQL_*)
TARGET_HOST=${DB_HOST:-$MYSQL_HOST}
TARGET_PORT=${DB_PORT:-$MYSQL_PORT}
TARGET_USER=${DB_USERNAME:-$MYSQL_USER}
TARGET_PASS=${DB_PASSWORD:-$MYSQL_PASSWORD}
TARGET_DB=${DB_DATABASE:-$MYSQL_DATABASE}

# Se o SERVER_IP nativo do Pterodactyl falhar, escuta em todas as interfaces do container
BIND_IP=${SERVER_IP:-"0.0.0.0"}

cat > conf/import/login-server.conf <<EOF
login_port: ${LOGIN_PORT}
account.engine: auto
account.sql.db_hostname: ${TARGET_HOST}
account.sql.db_port: ${TARGET_PORT}
account.sql.db_username: ${TARGET_USER}
account.sql.db_password: ${TARGET_PASS}
account.sql.db_database: ${TARGET_DB}
EOF

cat > conf/import/char-server.conf <<EOF
userid: ${SERVER_USERID}
passwd: ${SERVER_PASSWORD}
server_name: ${SERVER_NAME}
login_port: ${LOGIN_PORT}
char_ip: ${BIND_IP}
char_port: ${CHAR_PORT}
EOF

cat > conf/import/map-server.conf <<EOF
userid: ${SERVER_USERID}
passwd: ${SERVER_PASSWORD}
char_ip: ${BIND_IP}
char_port: ${CHAR_PORT}
map_ip: ${BIND_IP}
map_port: ${MAP_PORT}
EOF

cat > conf/import/inter-server.conf <<EOF
sql.db_hostname: ${TARGET_HOST}
sql.db_port: ${TARGET_PORT}
sql.db_username: ${TARGET_USER}
sql.db_password: ${TARGET_PASS}
sql.db_database: ${TARGET_DB}
EOF

echo "===================================="
echo "Iniciando servidores localmente..."
echo "===================================="

# Executa os binários locais que agora enxergam as pastas conf/db/npc clonadas na raiz
./login-server &
sleep 3

./char-server &
sleep 3

exec ./map-server
