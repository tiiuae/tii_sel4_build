# Copyright 2022, Technology Innovation Institute
FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install \
    repo \
    git

COPY ./checkout.sh /
ENTRYPOINT ["/checkout.sh"]
