FROM alpine:latest

USER root

RUN mkdir -p /wireguard
WORKDIR /wireguard

RUN apk add wireguard-tools

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
