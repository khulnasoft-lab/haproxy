FROM golang:1.22-alpine3.18 AS minica-builder
COPY minica.go /go
COPY genCert.sh /go
WORKDIR /go
RUN apk add --no-cache bash
RUN /bin/bash /go/genCert.sh


FROM haproxy:2.9-alpine3.18
MAINTAINER Khulnasoft Inc
LABEL kengine.role=system

USER root

ARG is_dev_build

COPY --from=minica-builder /go/minica.pem /usr/local/etc/haproxy/kengine.crt
COPY --from=minica-builder /go/minica-key.pem /usr/local/etc/haproxy/kengine.key
COPY router-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN apk update --no-cache \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && apk add --no-cache bash lua5.3 lua5.3-socket curl \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /var/log/haproxy \
    && touch /var/log/haproxy/haproxy.log

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
