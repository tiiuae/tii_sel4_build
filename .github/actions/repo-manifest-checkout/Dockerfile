# Copyright 2022, Technology Innovation Institute
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install \
    repo \
    git \
    xmlstarlet

COPY ./checkout.sh /
COPY ./branch_override.sh /
COPY ./repo_override.sh /
ENTRYPOINT ["/checkout.sh"]
