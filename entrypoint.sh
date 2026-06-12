#!/bin/bash

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup (Native ARM)"
echo "===================================="

# Mapeamento dinâmico para a conexão do BANCO DE DADOS PRINCIPAL
TARGET_HOST=${MYSQL_HOST:-"172.18.0.1"}
TARGET_PORT=${DB_PORT:-"3306"}
TARGET_USER=${DB_USERNAME:-$MYSQL_USER}
TARGET_PASS="${DB_PASSWORD:-$MYSQL_PASSWORD}"
TARGET_DB=${DB_DATABASE:-$MYSQL_DATABASE}

# Mapeamento dinâmico para a conexão do BANCO DE DADOS DE LOGS
LOG_USER=${LOG_DBUSER}
LOG_PASS="${LOG_DBPASS}"
LOG_DB=${DB_LOG}

# Variável central para a interconexão local dos servidores
SERVER_IP_CONFIG=${IP_SERVER:-"127.0.0.1"}

# Ativa o encerramento automático caso algo falhe daqui para frente
set -e

echo "Configurando os arquivos mestres de conexão do Hercules..."

# 1. Sobrescreve o arquivo global de conexão SQL (Coração do Banco)
cat > conf/sql_connection.conf <<EOF
// Arquivo gerado dinamicamente pelo Pterodactyl
sql_connection: {
	db_hostname: "${TARGET_HOST}"
	db_port: ${TARGET_PORT}
	db_username: "${TARGET_USER}"
	db_password: "${TARGET_PASS}"
	db_database: "${TARGET_DB}"
}
EOF

# 2. Sobrescreve as configurações de Log globais (Inter-server)
cat > conf/inter_configuration.conf <<EOF
// Arquivo gerado dinamicamente pelo Pterodactyl
inter_configuration: {
	database: {
		log_db: "${LOG_DB}"
	}
}
EOF

echo "Configurando arquivos de import..."
mkdir -p conf/import

# ===== LOGIN SERVER CONFIG =====
cat > conf/import/login-server.conf <<EOF
login_configuration: {
	login_port: ${LOGIN_PORT}
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
EOF

# ===== MAP SERVER CONFIG =====
cat > conf/import/map-server.conf <<EOF
map_configuration: {
	inter: {
		userid: "${SERVER_USERID}"
		passwd: "${SERVER_PASSWORD}"
		char_ip: "${SERVER_IP_CONFIG}"
		char_port: ${CHAR_PORT}
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
