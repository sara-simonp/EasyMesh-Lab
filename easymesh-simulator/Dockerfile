FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

ARG PRPLMESH_REPO=https://gitlab.com/prpl-foundation/prplmesh/prplMesh.git
ARG PRPLMESH_REF=stable/v1.7

ENV LD_LIBRARY_PATH=/opt/prplmesh/build/install/lib:/opt/prplmesh/build/out/lib:/usr/local/lib:/usr/lib
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig

# ------------------------------------------------------------
# 1. Dependencias base para prplMesh stable/v1.7
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    binutils \
    gcc \
    g++ \
    build-essential \
    make \
    cmake \
    ninja-build \
    pkg-config \
    python \
    python-yaml \
    python3 \
    python3-yaml \
    bison \
    flex \
    libjson-c-dev \
    libncurses-dev \
    libnl-3-dev \
    libnl-genl-3-dev \
    libnl-route-3-dev \
    libreadline-dev \
    libssl-dev \
    libevent-dev \
    libyajl-dev \
    lua5.1 \
    liblua5.1-0-dev \
    autoconf \
    autogen \
    automake \
    libtool \
    bridge-utils \
    ebtables \
    iproute2 \
    iputils-ping \
    net-tools \
    psmisc \
    uuid-runtime \
    tcpdump \
    vim \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 2. Clonar prplMesh desde GitLab
# ------------------------------------------------------------
RUN git clone --depth 1 --branch ${PRPLMESH_REF} ${PRPLMESH_REPO} /opt/prplmesh

WORKDIR /opt/prplmesh

# Mostrar repo/rama usados durante la build
RUN echo "Repositorio prplMesh usado:" && \
    git remote -v && \
    echo "Rama/commit usado:" && \
    git rev-parse --abbrev-ref HEAD || true && \
    git log -1 --oneline

# ------------------------------------------------------------
# 3. Compilar prplMesh
# ------------------------------------------------------------
RUN rm -rf build && mkdir -p build

RUN cd build && \
    cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=/opt/prplmesh/build/install \
    ..

RUN cd build && ninja -v -j1 install

# ------------------------------------------------------------
# 4. Comprobar que existen los binarios
# ------------------------------------------------------------
RUN echo "Buscando binarios generados por prplMesh..." && \
    find /opt/prplmesh -type f -executable \( \
    -name 'beerocks_controller' -o \
    -name 'beerocks_agent' -o \
    -name 'beerocks_cli' -o \
    -name 'beerocks_fronthaul' -o \
    -name 'ieee1905_transport' \
    \) -print | tee /tmp/prplmesh_bins.txt && \
    test -s /tmp/prplmesh_bins.txt

# ------------------------------------------------------------
# 5. Crear estructura de trabajo y copiar recursos si existen
# ------------------------------------------------------------
RUN mkdir -p \
    /opt/prplmesh/build/install/bin \
    /opt/prplmesh/build/install/lib \
    /opt/prplmesh/build/install/config \
    /opt/prplmesh/build/install/scripts \
    /opt/prplmesh/build/install/share \
    /tmp/beerocks/logs \
    /tmp/beerocks/pid \
    /tmp/captures && \
    if [ -d /opt/prplmesh/build/out/bin ]; then cp -a /opt/prplmesh/build/out/bin/* /opt/prplmesh/build/install/bin/ 2>/dev/null || true; fi && \
    if [ -d /opt/prplmesh/build/out/lib ]; then cp -a /opt/prplmesh/build/out/lib/* /opt/prplmesh/build/install/lib/ 2>/dev/null || true; fi && \
    if [ -d /opt/prplmesh/build/out/config ]; then cp -a /opt/prplmesh/build/out/config/* /opt/prplmesh/build/install/config/ 2>/dev/null || true; fi && \
    if [ -d /opt/prplmesh/build/out/scripts ]; then cp -a /opt/prplmesh/build/out/scripts/* /opt/prplmesh/build/install/scripts/ 2>/dev/null || true; fi && \
    if [ -d /opt/prplmesh/build/out/share ]; then cp -a /opt/prplmesh/build/out/share/* /opt/prplmesh/build/install/share/ 2>/dev/null || true; fi && \
    if [ -f /opt/prplmesh/build/framework/platform/bpl/platform_db/prplmesh_platform_db ]; then cp -a /opt/prplmesh/build/framework/platform/bpl/platform_db/prplmesh_platform_db /opt/prplmesh/build/install/share/prplmesh_platform_db; fi && \
    ldconfig

# ------------------------------------------------------------
# 6. Copiar script de arranque
# ------------------------------------------------------------
COPY start-prplmesh.sh /usr/local/bin/start-prplmesh.sh
RUN chmod +x /usr/local/bin/start-prplmesh.sh

WORKDIR /app

EXPOSE 6510 7590 8002

CMD ["/usr/local/bin/start-prplmesh.sh"]