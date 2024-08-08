# Builder
FROM golang:1.19-alpine as builder

WORKDIR /app

COPY . ./

RUN go mod download
RUN go build


# Release
FROM alpine:latest

ENV TSFILE=tailscale_1.70.0_amd64.tgz
ENV DNSPROXYFILE=dnsproxy-linux-amd64-v0.72.1.tar.gz
ENV DNSPROXYVERSION=v0.72.1

WORKDIR /app

RUN apk update && apk add ca-certificates iptables ip6tables bash bind-tools jq && rm -rf /var/cache/apk/*
RUN wget https://pkgs.tailscale.com/stable/${TSFILE} && tar xzf ${TSFILE} --strip-components=1
RUN wget https://github.com/AdguardTeam/dnsproxy/releases/download/${DNSPROXYVERSION}/${DNSPROXYFILE} && tar xzf ${DNSPROXYFILE} --strip-components=1

COPY --from=builder /app/tailscale-router /app/tailscale-router

# Copy and run tailscale init script, default nginx config
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

CMD ["/usr/local/bin/docker-entrypoint.sh"]
