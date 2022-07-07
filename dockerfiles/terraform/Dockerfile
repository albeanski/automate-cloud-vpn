FROM alpine:latest

COPY --from=golang:1.18.3-alpine3.16 /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

# Install ansible and dependencies
RUN apk update && \
  apk add \
    git && \
  git clone https://github.com/hashicorp/terraform.git

WORKDIR terraform
RUN go install

FROM alpine:latest

COPY --from=0 /terraform/terraform /bin/

# Create a group/user and project directory
RUN addgroup -S dev && \
  adduser -S dev -G dev && \
  chown -R dev:dev /project

USER dev

# Install ansible-galaxy requirements
# and python pip modules
ENTRYPOINT ["tail", "-f", "/dev/null"]
