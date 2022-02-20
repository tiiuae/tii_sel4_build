FROM ubuntu:21.04

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic tools and Linux kernel deps
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
        debianutils \
        emacs \
        file \
        flex \
        g++ \
        g++-aarch64-linux-gnu \
        gcc \
        gcc-aarch64-linux-gnu \
        git \
        gzip \
        libncurses5 \
        libncurses5-dev \
        libssl-dev \
        libelf-dev \
        locales \
        make \
        nano \
        patch \
        perl \
        python3 \
        rsync \
        sed \
        sudo \
        tar \
        unzip \
        vim \
        wget

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

ENV WORKSPACE=/workspace

WORKDIR /workspace
