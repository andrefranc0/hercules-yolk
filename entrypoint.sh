#!/bin/bash

set -e

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup"
echo "===================================="

# 1. Sincroniza a estrutura base da imagem para o diretório de trabalho do painel se não existir
echo "Verificando e sincronizando arquivos base do Hercules..."
for dir in conf db npc plugins sql-files; do
    if [ ! -d "$dir" ]; then
        echo "Copiando pasta $dir para /home/container..."
        cp -r /opt/hercules/$dir ./
    fi
done

# Copia os binários atualizados para o diretório de execução
cp /opt/hercules/*-server ./ 2>/dev/null || true

echo "Configurando arquivos de import com as árvores de blocos corretas..."
mkdir -p conf/import

# Mapeamento dinâmico das variáveis de banco de dados do Pterodactyl
TARGET_HOST=${DB_HOST:-$MYSQL_HOST}
TARGET_PORT=${DB_PORT:-$MYSQL_PORT}
TARGET_USER=${DB_USERNAME:-$MYSQL_USER}
TARGET_PASS=${DB_PASSWORD:-$MYSQL_PASSWORD}
TARGET_DB=${DB_DATABASE:-$MYSQL_DATABASE}

# Fallback para o IP de alocação caso a variável venha em branco
BIND_IP=${SERVER_IP:-"0.0.0.0"}

# ===== LOGIN SERVER CONFIG =====
# Conforme o login-server.conf original, as variáveis soltas de conexão entram 
# em account: { ... }, pois ele herda o sql_connection direto ali dentro.
cat > conf/import/login-server.conf <<EOF
login_configuration: {
	login_port: ${LOGIN_PORT}
	account: {
		engine: "auto"
		db_hostname: "${TARGET_HOST}"
		db_port: ${TARGET_PORT}
		db_username: "${TARGET_USER}"
		db_password: "${TARGET_PASS}"
		db_database: "${TARGET_DB}"
	}
}
EOF

# ===== CHAR SERVER CONFIG =====
# No Char-Server, o include do sql_connection entra na RAIZ do bloco char_configuration.
# Portanto, as variáveis de banco precisam ficar soltas direto na raiz do bloco, junto com o bloco 'inter'.
cat > conf/import/char-server.conf <<EOF
char_configuration: {
	server_name: "${SERVER_NAME}"
	
	db_hostname: "${TARGET_HOST}"
	db_port: ${TARGET_PORT}
	db_username: "${TARGET_USER}"
	db_password: "${TARGET_PASS}"
	db_database: "${TARGET_DB}"
	
	inter: {
		userid: "${SERVER_USERID}"
		passwd: "${SERVER_PASSWORD}"
		login_port: ${LOGIN_PORT}
		char_port: ${CHAR_PORT}
	}
}
EOF

# ===== MAP SERVER CONFIG =====
# No Map-Server, as propriedades de inter-conexão ficam em map_configuration -> inter.
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
