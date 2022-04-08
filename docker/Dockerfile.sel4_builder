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
        u-boot-tools \
        unzip \
        vim \
        wget

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
    git clone https://github.com/seL4/capdl.git ${HOMEDIR}/capdl && \
    cd ${HOMEDIR}/capdl/capDL-tool && \
    make sandbox && \
    cd ${HOMEDIR} && \
    rm -rf ${HOMEDIR}/capdl

ENV WORKSPACE=/workspace
WORKDIR /workspace