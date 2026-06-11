FROM debian:12

RUN apt update && apt install -y \
    git gcc g++ make cmake automake autoconf libtool pkg-config \
    re2c zlib1g-dev libpcre3-dev default-libmysqlclient-dev \
    default-mysql-client curl wget unzip nano ca-certificates dos2unix \
 && apt clean

RUN useradd -m -d /home/container container

# ===== BUILD HERCULES =====
WORKDIR /tmp

RUN git clone --depth 1 https://github.com/HerculesWS/Hercules.git

WORKDIR /tmp/Hercules

RUN mv conf/import-tmpl conf/import || true

RUN chmod +x configure && \
    CFLAGS="-O2" ./configure --disable-manager && \
    make -j$(nproc) sql

# ===== INSTALL FIXO (IMAGEM) =====
RUN mkdir -p /opt/hercules

RUN cp -r \
    conf db npc plugins sql-files \
    /opt/hercules/

RUN cp login-server char-server map-server /opt/hercules/

RUN chown -R container:container /opt/hercules

# ===== ENTRYPOINT =====
COPY entrypoint.sh /entrypoint.sh

RUN dos2unix /entrypoint.sh && \
    sed -i '1s/^\xEF\xBB\xBF//' /entrypoint.sh && \
    chmod +x /entrypoint.sh

USER container

ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
