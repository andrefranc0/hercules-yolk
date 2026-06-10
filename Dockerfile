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
    zlib1g-dev \
    libpcre3-dev \
    libmariadb-dev \
    mariadb-client \
    curl \
    wget \
    unzip \
    nano \
    ca-certificates \
 && apt clean

RUN useradd -m -d /home/container container

USER container

ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container
