#!/bin/bash

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup (Native ARM)"
echo "===================================="

# Mapeamento estritamente dinâmico vindo das variáveis do painel do Pterodactyl (Database Principal)
TARGET_HOST=${MYSQL_HOST:-"172.17.0.1"}
TARGET_PORT=${DB_PORT:-"3306"}
TARGET_USER=${DB_USERNAME:-$MYSQL_USER}
TARGET_PASS="${DB_PASSWORD:-$MYSQL_PASSWORD}"
TARGET_DB=${DB_DATABASE:-$MYSQL_DATABASE}

# Credenciais novas da DB de Logs (Atualizadas do Painel)
LOG_USER="u36_kTNtc6wNA0"
LOG_PASS='Yhhc!pyXeILv226w^f.!@33v'
LOG_DB="s36_log"

BIND_IP=${SERVER_IP:-"0.0.0.0"}

# Ativa o encerramento automático do script caso os passos abaixo falhem de verdade
set -e

echo "Configurando arquivos de import..."
mkdir -p conf/import

# ===== LOGIN SERVER CONFIG =====
cat > conf/import/login-server.conf <<EOF
login_configuration: {
	login_port: ${LOGIN_PORT}
}

sql_connection: {
	db_hostname: "${TARGET_HOST}"
	db_port: ${TARGET_PORT}
	db_username: "${TARGET_USER}"
	db_password: "${TARGET_PASS}"
	db_database: "${TARGET_DB}"
}
EOF

# ===== CHAR SERVER CONFIG =====
cat > conf/import/char-server.conf <<EOF
char_configuration: {
	server_name: "${SERVER_NAME}"
	inter: {
		userid: "${SERVER_USERID}"
		passwd: "${SERVER_PASSWORD}"
		login_port: ${LOGIN_PORT}
		char_port: ${CHAR_PORT}
	}
}

sql_connection: {
	db_hostname: "${TARGET_HOST}"
	db_port: ${TARGET_PORT}
	db_username: "${TARGET_USER}"
	db_password: "${TARGET_PASS}"
	db_database: "${TARGET_DB}"
}
EOF

# ===== MAP SERVER CONFIG =====
cat > conf/import/map-server.conf <<EOF
map_configuration: {
	inter: {
		userid: "${SERVER_USERID}"
		passwd: "${SERVER_PASSWORD}"
		char_ip: "${TARGET_HOST}"
		char_port: ${CHAR_PORT}
		map_ip: "${TARGET_HOST}"
		map_port: ${MAP_PORT}
	}
}
EOF

# ===== INTER SERVER CONFIG =====
cat > conf/import/inter-server.conf <<EOF
inter_configuration: {
	database: {
		log_db: "${LOG_DB}"
	}
}
EOF

echo "===================================="
echo "Iniciando servidores locais..."
echo "===================================="

./login-server &
sleep 3

./char-server &
sleep 3

exec ./map-server
