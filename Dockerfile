FROM debian:12

RUN apt update && apt install -y \
    git \
    gcc \
    g++ \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    pkg-config \
    re2c \
    zlib1g-dev \
    libpcre3-dev \
    default-libmysqlclient-dev \
    default-mysql-client \
    curl \
    wget \
    unzip \
    nano \
    ca-certificates \
    dos2unix \
 && apt clean

RUN useradd -m -d /home/container container

WORKDIR /tmp

RUN git clone --depth 1 https://github.com/HerculesWS/Hercules.git

WORKDIR /tmp/Hercules

# evita problemas de template antigo
RUN mv conf/import-tmpl conf/import || true

# build otimizado e estável para ARM
RUN chmod +x configure && \
    CFLAGS="-O2" ./configure --disable-manager && \
    make clean && \
    make -j$(nproc) sql

# ===== INSTALL DIRETO NO HOME (IMPORTANTE PARA PTERODACTYL) =====
RUN mkdir -p /home/container

RUN cp -r \
    conf \
    db \
    npc \
    plugins \
    sql-files \
    /home/container/

RUN cp login-server /home/container/
RUN cp char-server /home/container/
RUN cp map-server /home/container/

RUN chown -R container:container /home/container

# ===== ENTRYPOINT =====
COPY entrypoint.sh /entrypoint.sh

RUN dos2unix /entrypoint.sh
RUN sed -i '1s/^\xEF\xBB\xBF//' /entrypoint.sh
RUN chmod +x /entrypoint.sh

# troca para usuário do Pterodactyl
USER container

ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
