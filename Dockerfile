FROM --platform=${TARGETPLATFORM} golang:alpine as builder
ARG CGO_ENABLED=0
ARG TAG
ARG REPOSITORY

WORKDIR /root
RUN apk add --update git \
	&& git clone https://github.com/${REPOSITORY} mosdns \
	&& cd ./mosdns \
	&& git fetch --all --tags \
	&& git checkout tags/${TAG} \
	&& go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o mosdns

FROM --platform=${TARGETPLATFORM} alpine:latest

COPY --from=builder /root/mosdns/mosdns /usr/bin/

RUN apk add --no-cache supervisor ca-certificates \
	&& mkdir /etc/mosdns
ADD crontab.txt /crontab.txt
ADD script.sh /script.sh
ADD script1.sh /script1.sh
COPY entry.sh /entry.sh
ADD hosts /hosts
COPY hosts /hosts
ADD entry.sh /entry.sh
ADD entrypoint.sh /entrypoint.sh
ADD config.yaml /config.yaml
ADD https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat /geoip.dat
ADD https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat /geosite.dat
ADD hosts /etc/mosdns/hosts
COPY hosts /etc/mosdns/hosts
COPY supervisord.conf /etc/supervisord.conf
ADD script.sh /etc/mosdns/install_geodata.sh
COPY script.sh /etc/mosdns/install_geodata.sh
VOLUME /etc/mosdns
EXPOSE 53/udp 53/tcp
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
