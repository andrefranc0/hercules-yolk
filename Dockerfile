FROM debian:12

# Instala apenas as dependências básicas do sistema e clientes de banco
RUN apt update && apt install -y \
    git gcc g++ make cmake automake autoconf libtool pkg-config \
    re2c zlib1g-dev libpcre3-dev default-libmysqlclient-dev \
    default-mysql-client curl wget unzip nano ca-certificates dos2unix \
 && apt clean

# Cria o usuário padrão do Pterodactyl
RUN useradd -m -d /home/container container

# Copia o script de inicialização para a raiz
COPY entrypoint.sh /entrypoint.sh

# Garante que o arquivo esteja em formato Linux (LF) e limpa caracteres invisíveis
RUN dos2unix /entrypoint.sh && \
    sed -i '1s/^\xEF\xBB\xBF//' /entrypoint.sh && \
    chmod +x /entrypoint.sh

RUN chown -R container:container /entrypoint.sh

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
