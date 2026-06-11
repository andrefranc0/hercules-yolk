#!/bin/bash

set -e

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup"
echo "===================================="

# 1. Copia a estrutura base da imagem para o diretório de trabalho se não existirem
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

# Mapeamento dinâmico do banco do Pterodactyl
TARGET_HOST=${DB_HOST:-$MYSQL_HOST}
TARGET_PORT=${DB_PORT:-$MYSQL_PORT}
TARGET_USER=${DB_USERNAME:-$MYSQL_USER}
TARGET_PASS=${DB_PASSWORD:-$MYSQL_PASSWORD}
TARGET_DB=${DB_DATABASE:-$MYSQL_DATABASE}

BIND_IP=${SERVER_IP:-"0.0.0.0"}

# ===== LOGIN SERVER CONFIG =====
# Injeta os dados de conexão diretamente dentro do bloco correspondente do Login
cat > conf/import/login-server.conf <<EOF
login_configuration: {
	login_port: ${LOGIN_PORT}
	account: {
		engine: "auto"
		sql: {
			db_hostname: "${TARGET_HOST}"
			db_port: ${TARGET_PORT}
			db_username: "${TARGET_USER}"
			db_password: "${TARGET_PASS}"
			db_database: "${TARGET_DB}"
		}
	}
}
EOF

# ===== CHAR SERVER CONFIG =====
# Injeta os dados dentro do bloco correspondente do Character Server
cat > conf/import/char-server.conf <<EOF
char_configuration: {
	userid: "${SERVER_USERID}"
	passwd: "${SERVER_PASSWORD}"
	server_name: "${SERVER_NAME}"
	login_port: ${LOGIN_PORT}
	char_ip: "${BIND_IP}"
	char_port: ${CHAR_PORT}
}
EOF

# ===== MAP SERVER CONFIG =====
# Segue a árvore estrutural exata onde o bloco "inter" fica dentro de "map_configuration"
cat > conf/import/map-server.conf <<EOF
map_configuration: {
	inter: {
		userid: "${SERVER_USERID}"
		passwd: "${SERVER_PASSWORD}"
		char_ip: "${BIND_IP}"
		char_port: ${CHAR_PORT}
		map_ip: "${BIND_IP}"
		map_port: ${MAP_PORT}
	}
}
EOF

echo "===================================="
echo "Iniciando servidores localmente..."
echo "===================================="

./login-server &
sleep 3

./char-server &
sleep 3

exec ./map-server
