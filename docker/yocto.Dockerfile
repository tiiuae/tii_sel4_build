FROM ubuntu:21.04

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic tools and Yocto deps
# https://docs.yoctoproject.org/ref-manual/system-requirements.html#required-packages-for-the-build-host
# https://docs.yoctoproject.org/migration-guides/migration-3.4.html#new-host-dependencies
#
RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        build-essential \
        chrpath \
        cpio \
        debianutils \
        diffstat \
        emacs \
        file \
        g++-aarch64-linux-gnu \
        gawk \
        gcc-aarch64-linux-gnu \
        git \
        iputils-ping \
        libegl1-mesa \
        liblz4-tool \
        libsdl1.2-dev \
        locales \
        make \
        mesa-common-dev \
        nano \
        pylint3 \
        python3 \
        python3-git \
        python3-jinja2 \
        python3-pexpect \
        python3-pip \
        python3-pip \
        python3-subunit \
        rsync \
        socat \
        sudo \
        texinfo \
        unzip \
        vim \
        wget \
        xterm \
        xz-utils \
        zstd

# screen is required by linux menuconfig
RUN apt-get -y install \
        screen

RUN locale-gen en_US.UTF-8

RUN useradd -m -d /home/build -s /bin/bash -G sudo -u 1000 build
RUN echo 'build:build' | chpasswd
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN printf '\n\n\
eval $(ssh-agent -s &> /dev/null)\n\
find /home/build/.ssh/ -type f -exec grep -l "PRIVATE" {} \; | xargs ssh-add &> /dev/null'\
>> /home/build/.bashrc
RUN printf 'add-auto-load-safe-path /workspace/.gdbinit' >> /home/build/.gdbinit
USER build

ENV WORKSPACE=/workspace

WORKDIR /workspace
