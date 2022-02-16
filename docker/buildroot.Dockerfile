FROM ubuntu:21.04

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic tools and Buildroot deps
# https://buildroot.org/downloads/manual/manual.html#requirement
#

RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        nano \
        vim \
        emacs \
        debianutils \
        sed \
        make \
        binutils \
        build-essential \
        gcc \
        g++ \
        bash \
        patch \
        gzip \
        bzip2 \
        perl \
        tar \
        cpio \
        unzip \
        file \
        bc \
        python3 \
        libncurses5 \
        libncurses5-dev \
        wget \
        git \
        rsync \
        locales \
        unzip \
        cpio \
        sudo \
        device-tree-compiler

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
USER build

# Clone the buildroot repo
# RUN git clone --branch 2021.11.1 https://git.buildroot.net/buildroot.git \
#         /home/build/buildroot.git

ENV WORKSPACE=/workspace

WORKDIR /workspace
