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

RUN mv conf/import-tmpl conf/import || true

RUN chmod +x configure && \
    ./configure && \
    make clean && \
    make -j$(nproc) sql

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

COPY entrypoint.sh /entrypoint.sh

RUN dos2unix /entrypoint.sh

# Remove possível BOM UTF-8
RUN sed -i '1s/^\xEF\xBB\xBF//' /entrypoint.sh

# Diagnóstico temporário
RUN ls -l /entrypoint.sh
RUN file /entrypoint.sh
RUN head -n 5 /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER container

ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
