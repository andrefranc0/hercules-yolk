#!/bin/bash

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup (Native ARM)"
echo "===================================="

# Mapeamento dinâmico para a conexão do BANCO DE DADOS (VPS/Host)
TARGET_HOST=${MYSQL_HOST:-"172.18.0.1"}
TARGET_PORT=${DB_PORT:-"3306"}
TARGET_USER=${DB_USERNAME:-$MYSQL_USER}
TARGET_PASS="${DB_PASSWORD:-$MYSQL_PASSWORD}"
TARGET_DB=${DB_DATABASE:-$MYSQL_DATABASE}

# Credenciais da DB de Logs
LOG_USER="u36_kTNtc6wNA0"
LOG_PASS='Yhhc!pyXeILv226w^f.!@33v'
LOG_DB="s36_log"

# VARIÁVEL CENTRAL ATUALIZADA PARA INTERCONEXÃO LOCAL
# Se não estiver configurada no painel, adota o localhost por padrão
SERVER_IP_CONFIG=${IP_SERVER:-"127.0.0.1"}

# Ativa o encerramento automático caso algo falhe daqui para frente
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
		// Usa a nova variável IP_SERVER para se conectar ao Char localmente
		char_ip: "${SERVER_IP_CONFIG}"
		char_port: ${CHAR_PORT}
		// Escuta em todas as interfaces internas para permitir o redirecionamento do painel
		map_ip: "0.0.0.0"
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
