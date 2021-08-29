FROM ubuntu:20.10

# tzdata noninteractive install
ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        build-essential \
        fakeroot \
        dpkg-dev \
        cmake \
        ninja-build \
        haskell-stack \
        git \
        cpio \
        sudo \
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
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        device-tree-compiler

RUN useradd -d /home/build -m -u 1000 build
RUN ln -s /usr/bin/python3 /usr/bin/python

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

WORKDIR /workspace
