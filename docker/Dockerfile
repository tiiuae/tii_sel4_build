

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
        iproute2 \
        iputils-ping \
        cpio \
        sudo \
        rsync \
        curl \
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
        device-tree-compiler \
        qemu \
        qemu-utils \
        qemu-system-common \
        qemu-system-misc \
        qemu-system-x86 \
        qemu-system-arm

# Yocto build dependencies, probably some of these 
# are unnecessary for our use case (like 'xterm').
# screen is required by linux menuconfig
RUN \
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
        zstd \
	      screen

# Yocto build dependencies will uninstall these cross-compilers,
# so install them after everything else.
RUN apt-get -y install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Make sure we are using python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# Setup user, and remove user password
RUN \
  groupadd -g ${GID} -o ${GROUPNAME} \
  && useradd -m -d ${HOMEDIR} -s ${USERSHELL} -G sudo -o -u ${UID} -g ${GID} ${USERNAME} \
  && passwd -d ${USERNAME}

# Setup aliases and misc stuff
RUN \
  printf "alias ll='ls -lA'\n" >> ${HOMEDIR}/.bashrc \
  && printf "alias llh='ls -lhA'\n" >> ${HOMEDIR}/.bashrc \
  && chown ${USERNAME}:${GID} ${HOMEDIR}/.bashrc \
  && printf "add-auto-load-safe-path ${WORKDIR}/.gdbinit\n" >> ${HOMEDIR}/.gdbinit \
  && chown ${USERNAME}:${GID} ${HOMEDIR}/.gdbinit

USER ${USERNAME}

RUN \
  pip3 install \
    aenum \
    ordered_set \
    plyplus \
    pyfdt \
    pyyaml

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