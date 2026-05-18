FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CMAKE_BUILD_PARALLEL_LEVEL=1
ENV MAKEFLAGS="-j1"
ENV NINJAFLAGS="-j1"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    build-essential \
    cmake \
    ninja-build \
    autoconf \
    autogen \
    automake \
    libtool \
    pkg-config \
    libreadline-dev \
    libncurses-dev \
    libssl-dev \
    libjson-c-dev \
    libnl-3-dev \
    libnl-route-3-dev \
    libnl-genl-3-dev \
    python3 \
    python3-pip \
    python3-yaml \
    tcpdump \
    net-tools \
    iproute2 \
    iputils-ping \
    vim \
    bridge-utils \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 https://github.com/prplfoundation/prplMesh.git /opt/prplmesh

WORKDIR /opt/prplmesh

RUN mkdir -p build && \
    cd build && \
    cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    .. && \
    ninja -j1

WORKDIR /app

RUN mkdir -p /app/config /tmp/captures

EXPOSE 6510 7590

CMD ["/bin/bash", "-lc", "echo 'EasyMesh/prplMesh build ready'; tail -f /dev/null"]