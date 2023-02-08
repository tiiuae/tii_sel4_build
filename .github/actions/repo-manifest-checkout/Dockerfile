# Copyright 2022, Technology Innovation Institute
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install \
    repo \
    git

COPY ./checkout.sh /
ENTRYPOINT ["/checkout.sh"]
