FROM alpine:latest

COPY --from=golang:1.18.3-alpine3.16 /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

# Install ansible and dependencies
RUN apk update && \
  apk add \
    git && \
  git clone https://github.com/hashicorp/terraform.git

WORKDIR terraform
RUN go install && \
  mkdir "/terraform-binary" && \
  mv "$(go env GOPATH)/bin/terraform" /terraform-binary/terraform

FROM alpine:latest

COPY --from=0 /terraform-binary/terraform /bin/terraform

# Create a group/user and project directory
RUN addgroup -S dev && \
  adduser -S dev -G dev && \
  mkdir /project && \
  chown -R dev:dev /project

RUN terraform --version

USER dev

# Install ansible-galaxy requirements
# and python pip modules
ENTRYPOINT ["tail", "-f", "/dev/null"]
