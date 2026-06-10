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
 && apt clean

RUN useradd -m -d /home/container container

WORKDIR /tmp

RUN git clone --depth 1 https://github.com/HerculesWS/Hercules.git

WORKDIR /tmp/Hercules

RUN chmod +x configure && \
    ./configure --enable-64bit && \
    make clean && \
    make server

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

USER container

ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container
