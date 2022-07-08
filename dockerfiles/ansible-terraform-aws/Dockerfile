FROM alpine:latest
#RUN apk update && \
#  apk add \
#    curl \
#    unzip

#RUN mkdir /aws-cli
#WORKDIR /aws-cli

#RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
#  unzip awscliv2.zip && \
#  ./aws/install

FROM ansible:latest

COPY --from=terraform:latest /bin/terraform /bin/terraform
#COPY --from=0 /usr/local/aws-cli /usr/local/aws-cli
#COPY --from=0 /usr/local/bin /bin

USER dev
RUN pip3 install awscli
ENV PATH="/home/dev/.local/bin:${PATH}"
