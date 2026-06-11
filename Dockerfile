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
    CFLAGS="-O0" ./configure && \
    make clean && \
    make sql

RUN file login-server
RUN file char-server
RUN file map-server

RUN ldd login-server
RUN ldd char-server
RUN ldd map-server

RUN mkdir -p /opt/hercules

RUN cp -r \
    conf \
    db \
    npc \
    plugins \
    sql-files \
    /opt/hercules/

RUN cp login-server /opt/hercules/
RUN cp char-server /opt/hercules/
RUN cp map-server /opt/hercules/

RUN chown -R container:container /opt/hercules

COPY entrypoint.sh /entrypoint.sh

RUN dos2unix /entrypoint.sh
RUN sed -i '1s/^\xEF\xBB\xBF//' /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER container

ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
