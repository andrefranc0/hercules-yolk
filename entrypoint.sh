#!/bin/bash

cd /home/container

echo "===================================="
echo "Hercules Pterodactyl Startup"
echo "===================================="

# Mapeamento estritamente dinâmico vindo das variáveis do painel do Pterodactyl
TARGET_HOST=${MYSQL_HOST:-"172.17.0.1"} # Agora com o fallback corrigido para a tua interface docker0
TARGET_PORT=${DB_PORT:-"3306"}
TARGET_USER=${DB_USERNAME:-$MYSQL_USER}
TARGET_PASS="${DB_PASSWORD:-$MYSQL_PASSWORD}"
TARGET_DB=${DB_DATABASE:-$MYSQL_DATABASE}

# Credenciais exclusivas da DB de Logs tratadas com aspas estritas
LOG_USER="u34_IHtiDl2NZ4"
LOG_PASS='a@^O@^I3ZIQ7uAmuHDLzED1z'
LOG_DB="s34_log"

BIND_IP=${SERVER_IP:-"0.0.0.0"}

echo "------------------------------------"
echo "TESTE DE CONEXÃO: DATABASE PRINCIPAL"
echo "Host: $TARGET_HOST:$TARGET_PORT"
echo "User: $TARGET_USER"
echo "Database: $TARGET_DB"
echo "------------------------------------"

if mysqladmin ping -h "$TARGET_HOST" -P "$TARGET_PORT" -u "$TARGET_USER" -p"$TARGET_PASS" --silent; then
    echo "[SUCESSO] Conexão com a Database Principal está OK!"
    if mysql -h "$TARGET_HOST" -P "$TARGET_PORT" -u "$TARGET_USER" -p"$TARGET_PASS" -D "$TARGET_DB" -e "SHOW TABLES LIKE 'login';" 2>/dev/null | grep -q "login"; then
        echo "[SUCESSO] Tabela 'login' encontrada na DB Principal!"
    else
        echo "[AVISO] Tabela 'login' NÃO encontrada na DB Principal. Certifique-se de importar o main.sql."
    fi
else
    echo "[ERRO] Falha ao conectar na DB Principal:"
    mysql -h "$TARGET_HOST" -P "$TARGET_PORT" -u "$TARGET_USER" -p"$TARGET_PASS" -e "SELECT 1;" 2>&1
fi

echo "------------------------------------"
echo "TESTE DE CONEXÃO: DATABASE DE LOGS"
echo "Host: $TARGET_HOST:$TARGET_PORT"
echo "User: $LOG_USER"
echo "Database: $LOG_DB"
echo "------------------------------------"

if mysqladmin ping -h "$TARGET_HOST" -P "$TARGET_PORT" -u "$LOG_USER" -p"$LOG_PASS" --silent; then
    echo "[SUCESSO] Conexão com a Database de Logs está OK!"
else
    echo "[ERRO] Falha ao conectar na DB de Logs ($LOG_DB):"
    mysql -h "$TARGET_HOST" -P "$TARGET_PORT" -u "$LOG_USER" -p"$LOG_PASS" -e "SELECT 1;" 2>&1
fi
echo "===================================="

set -e

# Sincronização dos arquivos base do Hercules
echo "Verificando e sincronizando arquivos base do Hercules..."
for dir in conf db npc plugins sql-files; do
    if [ ! -d "$dir" ]; then
        echo "Copiando pasta $dir para /home/container..."
        cp -r /opt/hercules/$dir ./
    fi
done

cp /opt/hercules/*-server ./ 2>/dev/null || true

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
		char_ip: "${BIND_IP}"
		char_port: ${CHAR_PORT}
		map_ip: "${BIND_IP}"
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
echo "Iniciando servidores localmente..."
echo "===================================="

./login-server &
sleep 3

./char-server &
sleep 3

exec ./map-server
