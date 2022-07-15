FROM ansible:latest

USER root

# Create a group/user and project directory
RUN apk add groff less

RUN mkdir -p /runtime && \
  chown -R dev:dev /runtime

COPY --from=terraform:latest /bin/terraform /bin/terraform

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh && \
  chown dev:dev /entrypoint.sh

USER dev
ENV PATH="/home/dev/.local/bin:${PATH}"

RUN pip3 install awscli

WORKDIR /project

ENTRYPOINT ["/entrypoint.sh"]
