FROM ansible-terraform-aws:latest

USER root

RUN apk add wireguard-tools && \
  mkdir -p /wireguard/client /ssh_keys && \
  chown -R dev:dev /wireguard /ssh_keys

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
  chown dev:dev /entrypoint.sh

USER dev

WORKDIR /project

ENTRYPOINT ["/entrypoint.sh"]
