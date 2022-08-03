# Copyright 2022, Technology Innovation Institute
FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/Helsinki

# seL4 deps
RUN apt-get update && apt-get -y install \
    file \
    locales \
    build-essential \
    fakeroot \
    dpkg-dev \
    cmake \
    ninja-build \
    haskell-stack \
    git \
    cpio \
    sudo \
    rsync \
    wget \
    unzip \
    strace \
    bc \
    flex \
    bison \
    libelf-dev \
    libssl-dev \
    libncurses-dev \
    libxml2-utils \
    protobuf-compiler \
    python3-pip \
    python3-pyelftools \
    python3-future \
    python3-jinja2 \
    python3-jsonschema \
    python3-libarchive-c \
    python3-ply \
    python3-protobuf \
    python3-simpleeval \
    python3-sortedcontainers \
    device-tree-compiler \
 # ... timezones
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 # ... locales
 && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
 && locale-gen

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# FIXME: check this
# Yocto build dependencies will uninstall these cross-compilers,
# so install them after everything else.
RUN apt-get update && apt-get -y install \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu

# FIXME: Move these to either of RUN statements?
RUN pip3 install \
    aenum \
    ordered_set \
    plyplus \
    pyfdt \
    pyyaml \
    sh \
    pexpect

# Define stack root here in case HOME variable is set to something else
ENV STACK_ROOT=/root/.stack

RUN git clone https://github.com/seL4/capdl.git \
 && cd capdl/capDL-tool \
 && stack build --only-dependencies \
 && cd - \
 && rm -rf capdl

COPY ./build.sh /
ENTRYPOINT ["/build.sh"]
