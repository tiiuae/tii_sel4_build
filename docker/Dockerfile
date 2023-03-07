

FROM debian:bullseye


# All the args
ARG USERNAME
ARG GROUPNAME=${USERNAME}
ARG HOMEDIR=/home/${USERNAME}
ARG USERSHELL=/bin/bash
ARG UID
ARG GID
ARG DEBIAN_FRONTEND=noninteractive
ARG WORKDIR=/workspace


# All the envs
ENV TZ=Europe/Helsinki
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en:C
ENV WORKSPACE=${WORKDIR}
ENV SHELL=${USERSHELL}


# Update package lists
RUN apt-get -y update

# Configure timezone
RUN \
    ln -snf /usr/share/zoneinfo/\${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && LC_ALL=C dpkg-reconfigure tzdata

# Configure locale
RUN \
    LC_ALL=C apt-get -y install locales \
    && sed -i -e "s/#\s*\(${LANG}.*\)$/\1/g" /etc/locale.gen \
    && echo "LANG=${LANG}" > /etc/default/locale \
    && echo "LANGUAGE=${LANGUAGE}" >> /etc/default/locale \
    && locale-gen \
    && dpkg-reconfigure locales \
    && update-locale "LANG=${LANG}"

# Configure keyboard layout just in case
RUN apt-get -y install keyboard-configuration \
  && echo $'# KEYBOARD CONFIGURATION FILE\n\
\n\
# Consult the keyboard(5) manual page.\n\
\n\
XKBMODEL="pc105"\n\
XKBLAYOUT="fi"\n\
XKBVARIANT=""\n\
XKBOPTIONS=""\n\
\n\
BACKSPACE="guess"' \
    && dpkg-reconfigure keyboard-configuration

# Update everything and install tools
RUN \
    apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install \
        bc \
        bison \
        build-essential \
        cmake \
        cpio \
        curl \
        device-tree-compiler \
        dpkg-dev \
        emacs \
        fakeroot \
        file \
        flex \
        git \
        haskell-stack \
        iproute2 \
        iputils-ping \
        libelf-dev \
        libncurses-dev \
        libssl-dev \
        libxml2-utils \
        locales \
        nano \
        ninja-build \
        protobuf-compiler \
        python-is-python3 \
        python3-dev \
        python3-pip \
        python3-protobuf \
        qemu \
        qemu-system-arm \
        qemu-system-common \
        qemu-system-misc \
        qemu-system-x86 \
        qemu-utils \
        rsync \
        strace \
        sudo \
        unzip \
        vim \
        wget

# Yocto build dependencies, probably some of these 
# are unnecessary for our use case (like 'xterm').
# screen is required by linux menuconfig
RUN \
    apt-get -y install \
        build-essential \
        chrpath \
        diffstat \
        gawk \
        gcc-multilib \
        git-core \
        liblz4-tool \
        libsdl1.2-dev \
        screen \
        socat \
        texinfo \
        unzip \
        wget \
        xterm \
        zstd

# Yocto build dependencies will uninstall these cross-compilers,
# so install them after everything else.
RUN apt-get -y install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Make sure we are using python3
#RUN ln -s /usr/bin/python3 /usr/bin/python

# Setup user, and remove user password
RUN \
  groupadd -g ${GID} -o ${GROUPNAME} \
  && useradd -m -d ${HOMEDIR} -s ${USERSHELL} -G sudo -o -u ${UID} -g ${GID} ${USERNAME} \
  && passwd -d ${USERNAME}

# Setup aliases and misc stuff
RUN \
  printf "alias l='ls -lah'\n" >> ${HOMEDIR}/.bashrc \
  && printf "alias la='ls -lAh'\n" >> ${HOMEDIR}/.bashrc \
  && printf "alias ll='ls -lh'\n" >> ${HOMEDIR}/.bashrc \
  && printf "alias ls='ls --color=auto'\n" >> ${HOMEDIR}/.bashrc \
  && printf "alias llh='ls -lhA'\n" >> ${HOMEDIR}/.bashrc \
  && chown ${USERNAME}:${GID} ${HOMEDIR}/.bashrc \
  && printf "add-auto-load-safe-path ${WORKDIR}/.gdbinit\n" >> ${HOMEDIR}/.gdbinit \
  && chown ${USERNAME}:${GID} ${HOMEDIR}/.gdbinit

USER ${USERNAME}

# seL4 Python deps
# https://github.com/seL4/seL4/blob/master/tools/python-deps/setup.py
#
# seL4 Tutorials don't seem to work with 'sh'
# versions later than 1.14.3 currently
#
RUN pip3 install --user \
    autopep8==1.4.3 \
    bs4 \
    cmake-format==0.4.5 \
    future \
    guardonce \ 
    jinja2 \
    jsonschema \
    libarchive-c \
    lxml \
    pexpect \
    ply \
    psutil \
    pyelftools \
    pyfdt \
    pyyaml==6.0 \
    sh==1.14.3 \
    six


# CAmkES Python deps
# https://github.com/seL4/camkes-tool/blob/master/tools/python-deps/setup.py
#
RUN pip3 install --user \
    aenum \
    concurrencytest \
    hypothesis \
    jinja2==3.1.2 \
    ordered-set \
    orderedset \
    plyplus \
    pycparser \
    pyelftools \
    pyfdt \
    sortedcontainers

# Other Python deps
# seL4 Tutorials needs 'pyaml'
#
RUN pip3 install --user \
    simpleeval \
    pyaml

# Let's build all the capdl's dependencies. Downloading, compiling and
# installing the correct GHC version and all of the dependencies takes
# lots of time and we don't want to redo that everytime we restart the
# container.

RUN \
    git clone https://github.com/seL4/capdl.git ${HOMEDIR}/capdl \
    && cd ${HOMEDIR}/capdl/capDL-tool \
    && stack build --only-dependencies \
    && cd ${HOMEDIR} \
    && rm -rf ${HOMEDIR}/capdl

WORKDIR ${WORKDIR}