#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

ARG BASE_IMG=debian:bullseye

FROM ${BASE_IMG}

LABEL ORGANISATION="Technology Innovation Institute"
LABEL MAINTAINER="Joonas Onatsu (joonasx@ssrc.tii.ae)"

ARG TZ=Europe/Helsinki
ARG LANG=en_US.UTF-8
ARG LANGUAGE=en_US:en:C
ARG DEBIAN_FRONTEND=noninteractive

ARG TOOLS_GROUP=tools
ARG TOOLS_GID=10000
ARG SCRIPTS_DIR=scripts
ARG SETUP_DIR=/tmp/setup
ARG SCRIPT=base_img.sh
ARG UTILS=utils/utils.sh

COPY "${SCRIPTS_DIR}/${UTILS}" "${SETUP_DIR}/${UTILS}"
COPY "${SCRIPTS_DIR}/${SCRIPT}" "${SETUP_DIR}/${SCRIPT}"

ARG UTILS_SCRIPT="${SETUP_DIR}/${UTILS}"
ARG SETUP_SCRIPT="${SETUP_DIR}/${SCRIPT}"

RUN echo ipv4 >> ~/.curlrc \
    && /bin/bash "${SETUP_SCRIPT}" \
    && rm -rf "${SETUP_DIR}" \
    && apt-get clean autoclean \
    && apt-get -y autoremove --purge
