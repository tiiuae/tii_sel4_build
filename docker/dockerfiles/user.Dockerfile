#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_IMG=tiiuae/tools

FROM ${BASE_IMG}

LABEL ORGANISATION="Technology Innovation Institute"
LABEL MAINTAINER="Joonas Onatsu (joonasx@ssrc.tii.ae)"

ARG DEBIAN_FRONTEND=noninteractive

ARG SCRIPTS_DIR=scripts
ARG SETUP_DIR=/tmp/setup
ARG SCRIPT=user_img.sh
ARG UTILS=utils/utils.sh
ARG USERNAME
ARG USERID
ARG GROUPID
ARG GROUPNAME
ARG USHELL=/bin/bash
ARG WORKDIR=/workspace

COPY "${SCRIPTS_DIR}/${UTILS}" "${SETUP_DIR}/${UTILS}"
COPY "${SCRIPTS_DIR}/${SCRIPT}" "${SETUP_DIR}/${SCRIPT}"

ARG UTILS_SCRIPT="${SETUP_DIR}/${UTILS}"
ARG SETUP_SCRIPT="${SETUP_DIR}/${SCRIPT}"

RUN /bin/bash "${SETUP_SCRIPT}" \
    && rm -rf "${SETUP_DIR}"

VOLUME /home/${USERNAME}-home