FROM ubuntu:21.04

ARG USERNAME=build
ARG PASSWORD=build
ARG HOMEDIR=/home/build
ARG USERSHELL=/bin/bash
ARG UID=1000
ARG GID=1000

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic tools, Buildroot, Linux kernel and U-Boot deps
#
# https://buildroot.org/downloads/manual/manual.html#requirement
#
# screen is required by linux menuconfig
#
# https://u-boot.readthedocs.io/en/latest/build/gcc.html#dependencies
# https://linux-sunxi.org/U-Boot
#

RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        bash \
        bc \
        binutils \
        bison \
        build-essential \
        bzip2 \
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
        g++ \
        g++-aarch64-linux-gnu \
        gawk \
        gcc \
        gcc-aarch64-linux-gnu \
        gdisk \
        git \
        gzip \
        iputils-ping \
        libelf-dev \
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
        make \
        nano \
        openssl \
        patch \
        perl \
        pkg-config \
        python3 \
        python3-coverage \
        python3-pkg-resources \
        python3-pycryptodome \
        python3-pyelftools \
        python3-pytest \
        python3-sphinxcontrib.apidoc \
        python3-sphinx-rtd-theme \
        python3-virtualenv \
        rsync \
        screen \
        sed \
        socat \
        swig \
        tar \
        texinfo \
        unzip \
        vim \
        wget \
        xz-utils

RUN locale-gen en_US.UTF-8

RUN ln -s /usr/bin/python3 /usr/bin/python
RUN ln -sf /bin/bash /bin/sh
RUN groupadd -g ${GID} -o ${USERNAME}
RUN useradd -m -d ${HOMEDIR} -s ${USERSHELL} -o -u ${UID} -g ${GID} -p "$(openssl passwd -6 ${PASSWORD})" ${USERNAME}
RUN mkdir -p ${HOMEDIR}/.ssh -m 700 && chown ${UID}:${GID} ${HOMEDIR}/.ssh
RUN printf "\n\n\
eval \$(ssh-agent -s &> /dev/null)\n\
find ${HOMEDIR}/.ssh/ -type f -exec grep -l "PRIVATE" {} \; | xargs ssh-add &> /dev/null"\
>> ${HOMEDIR}/.bashrc

USER ${USERNAME}

ENV WORKSPACE=/workspace
WORKDIR /workspace

