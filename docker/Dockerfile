FROM ubuntu:21.04

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        nano \
        vim \
        emacs \
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
        device-tree-compiler

# Yocto build dependencies, probably some of these are unnecessarry for
# our use case (like 'xterm').
RUN apt-get -y install \
        gawk \
        wget \
        git-core \
        diffstat \
        unzip \
        texinfo \
        gcc-multilib \
        build-essential \
        chrpath \
        socat \
        libsdl1.2-dev \
        xterm \
        liblz4-tool \
        zstd

# screen is required by linux menuconfig
RUN apt-get -y install \
        screen

# Yocto build dependencies will uninstall these cross-compilers,
# so install them after everything else.
RUN apt-get -y install \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu

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

RUN pip3 install \
    aenum \
    orderedset \
    plyplus \
    pyfdt \
    pyyaml

# Let's build all the capdl's dependencies. Downloading, compiling and
# installing the correct GHC version and all of the dependencies takes
# lots of time and we don't want to redo that everytime we restart the
# container.

RUN \
    git clone https://github.com/seL4/capdl.git /home/build/capdl && \
    cd /home/build/capdl/capDL-tool && \
    stack build --only-dependencies && \
    cd /home/build && \
    rm -rf /home/build/capdl

ENV WORKSPACE=/workspace

WORKDIR /workspace
