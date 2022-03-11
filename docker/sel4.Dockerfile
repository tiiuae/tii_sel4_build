FROM ubuntu:21.04

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        bc \
        bison \
        build-essential \
        cmake \
        cpio \
        device-tree-compiler \
        dpkg-dev \
        emacs \
        fakeroot \
        file \
        flex \
        g++-aarch64-linux-gnu \
        gcc-aarch64-linux-gnu \
        git \
        haskell-stack \
        libelf-dev \
        libncurses-dev \
        libssl-dev \
        libxml2-utils \
        locales \
        nano \
        ninja-build \
        protobuf-compiler \
        python3-future \
        python3-jinja2 \
        python3-jsonschema \
        python3-libarchive-c \
        python3-pip \
        python3-ply \
        python3-protobuf \
        python3-pyelftools \
        python3-simpleeval \
        python3-sortedcontainers \
        rsync \
        strace \
        sudo \
        unzip \
        vim \
        wget

RUN locale-gen en_US.UTF-8

RUN useradd -m -d /home/build -s /bin/bash -G sudo -u 1000 build
RUN echo 'build:build' | chpasswd
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN printf '\n\n\
eval $(ssh-agent -s &> /dev/null)\n\
find /home/build/.ssh/ -type f -exec grep -l "PRIVATE" {} \; | xargs ssh-add &> /dev/null'\
>> /home/build/.bashrc
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
    make sandbox && \
    cd /home/build && \
    rm -rf /home/build/capdl

ENV WORKSPACE=/workspace

WORKDIR /workspace
