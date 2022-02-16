FROM ubuntu:21.04

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install basic tools and Yocto deps
# https://docs.yoctoproject.org/ref-manual/system-requirements.html#required-packages-for-the-build-host
# https://docs.yoctoproject.org/migration-guides/migration-3.4.html#new-host-dependencies
#
RUN apt-get -y install \
        nano \
        vim \
        emacs \
        file \
        locales \
        sudo \
        rsync \
        unzip \
        gawk \
        wget \
        git \
        diffstat \
        unzip \
        texinfo \
        gcc \
        build-essential \
        chrpath \
        socat \
        cpio \
        python3 \
        python3-pip \
        python3-pexpect \
        xz-utils \
        debianutils \
        iputils-ping \
        python3-git \
        python3-jinja2 \
        libegl1-mesa \
        libsdl1.2-dev \
        pylint3 \
        xterm \
        python3-subunit \
        mesa-common-dev \
        zstd \
        liblz4-tool \
        make \
        python3-pip

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
