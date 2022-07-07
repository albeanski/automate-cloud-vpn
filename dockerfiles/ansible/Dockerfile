FROM alpine:latest

# Install ansible and dependencies
RUN apk update && \
  apk add \
    python3 \
    py3-pip \
  && python3 -m pip install ansible

RUN mkdir -p /project
WORKDIR /project

# Create a group/user and project directory
RUN addgroup -S dev && \
  adduser -S dev -G dev && \
  chown -R dev:dev /project


COPY ./bootstrap.sh /
RUN chmod +x /bootstrap.sh && \
  chown dev:dev /bootstrap.sh

USER dev

# Install ansible-galaxy requirements
# and python pip modules
ENTRYPOINT ["/bootstrap.sh"]