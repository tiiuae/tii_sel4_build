FROM debian:bullseye

ARG UID=1000
ARG GID=1000
ARG USER=build
ARG GROUP=build
ARG HOME=/home/build

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
        python3-jsonschema \
        python3-libarchive-c \
        python3-ply \
        python3-protobuf \
        python3-simpleeval \
        python3-sortedcontainers \
        device-tree-compiler \
        qemu-system-arm

# Yocto build dependencies, probably some of these are unnecessarry for
# our use case (like 'xterm').
RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
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
RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        screen

# Yocto build dependencies will uninstall these cross-compilers,
# so install them after everything else.
RUN \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen
RUN groupadd -g $GID $GROUP
RUN useradd -m -d $HOME -s /bin/bash -G sudo -u $UID -g $GID $USER
RUN passwd -d $USER
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN printf '\n\n\
eval $(ssh-agent -s &> /dev/null)\n\
find '$HOME'/.ssh/ -type f -exec grep -l "PRIVATE" {} \; | xargs ssh-add &> /dev/null\n'\
>> $HOME/.bashrc
RUN printf 'add-auto-load-safe-path /workspace/.gdbinit' >> $HOME/.gdbinit
USER $USER

RUN pip3 install \
    aenum \
    jinja2 \
    ordered_set \
    plyplus \
    pyfdt \
    pyyaml
