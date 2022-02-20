FROM ubuntu:21.04

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic tools and U-Boot deps
# https://u-boot.readthedocs.io/en/latest/build/gcc.html#dependencies
# https://linux-sunxi.org/U-Boot
#
RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        bc \
        bison \
        build-essential \
        chrpath \
        coccinelle \
        cpio \
        debianutils \
        device-tree-compiler \
        dfu-util \
        diffstat \
        efitools \
        emacs \
        file \
        flex \
        g++-aarch64-linux-gnu \
        gawk \
        gcc-aarch64-linux-gnu \
        gdisk \
        git \
        iputils-ping \
        libguestfs-tools \
        liblz4-tool \
        libncurses5 \
        libncurses5-dev \
        libpython3-dev \
        libsdl2-dev \
        libssl-dev \
        locales \
        lz4 \
        lzma \
        lzma-alone \
        nano \
        openssl \
        pkg-config \
        python3 \
        python3-coverage \
        python3-pkg-resources \
        python3-pycryptodome \
        python3-pyelftools \
        python3-pytest \
        python3-sphinx-rtd-theme \
        python3-sphinxcontrib.apidoc \
        python3-virtualenv \
        rsync \
        socat \
        sudo \
        swig \
        texinfo \
        unzip \
        unzip \
        vim \
        wget \
        xz-utils

RUN locale-gen en_US.UTF-8

RUN useradd -m -d /home/build -s /bin/bash -G sudo -u 1000 build
RUN echo 'build:build' | chpasswd
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN printf '\n\n\
eval $(ssh-agent -s &> /dev/null)\n\
find /home/build/.ssh/ -type f -exec grep -l "PRIVATE" {} \; | xargs ssh-add &> /dev/null'\
>> /home/build/.bashrc
USER build

ENV WORKSPACE=/workspace

WORKDIR /workspace
