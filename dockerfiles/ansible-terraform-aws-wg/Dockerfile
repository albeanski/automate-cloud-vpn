FROM ansible-terraform-aws:latest

USER root

RUN apk add wireguard-tools && \
  mkdir -p /wireguard && \
  chown -R dev:dev /wireguard

RUN wg genkey | \
    tee /etc/wireguard/privatekey | \
    wg pubkey | \
    tee /etc/wireguard/publickey && \
    cp /etc/wireguard/publickey /wireguard/publickey


COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
  chown dev:dev /entrypoint.sh

USER dev

WORKDIR /project

ENTRYPOINT ["/entrypoint.sh"]
