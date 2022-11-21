FROM debian:bullseye

ARG USERNAME=build
ARG PASSWORD=build
ARG HOMEDIR=/home/build
ARG USERSHELL=/bin/bash
ARG UID=1000
ARG GID=1000
ARG ENV_SETUP_SCRIPT=.container_env_setup.sh

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
        zstd \
	# screen is required by linux menuconfig
	screen

# Yocto build dependencies will uninstall these cross-compilers,
# so install them after everything else.
RUN apt-get -y install \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN groupadd -g ${GID} -o ${USERNAME} \
  && useradd -m -d ${HOMEDIR} -s ${USERSHELL} -G sudo -o -u ${UID} -g ${GID} ${USERNAME} \
  && echo "${USERNAME}:${PASSWORD}" | chpasswd

# Automate adding SSH keys to SSH agent
RUN mkdir -m 0700 ${HOMEDIR}/.ssh \
  && chown -R "${USERNAME}:${GID}" ${HOMEDIR}/.ssh
COPY ${ENV_SETUP_SCRIPT} ${HOMEDIR}/${ENV_SETUP_SCRIPT}
RUN chown "${USERNAME}:${GID}" ${HOMEDIR}/${ENV_SETUP_SCRIPT} && \
    chmod ug+x ${HOMEDIR}/${ENV_SETUP_SCRIPT}
RUN printf '\n\n\
alias ll="ls -la --color=auto"\n\
alias llh="ls -lha --color=auto"\n\
eval "$(ssh-agent -s)"\n\
source '${HOMEDIR}'/'${ENV_SETUP_SCRIPT}''\
>> ${HOMEDIR}/.bashrc
RUN chown "${USERNAME}:${GID}" ${HOMEDIR}/.bashrc
RUN printf 'add-auto-load-safe-path /workspace/.gdbinit' >> ${HOMEDIR}/.gdbinit
RUN chown "${USERNAME}:${GID}" ${HOMEDIR}/.gdbinit

USER ${USERNAME}

RUN pip3 install \
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
    git clone https://github.com/seL4/capdl.git ${HOMEDIR}/capdl && \
    cd ${HOMEDIR}/capdl/capDL-tool && \
    stack build --only-dependencies && \
    cd ${HOMEDIR} && \
    rm -rf ${HOMEDIR}/capdl

ENV WORKSPACE=/workspace
WORKDIR /workspace
