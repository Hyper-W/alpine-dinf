ARG FinchVersionMajor=1
ARG FinchVersionMinor=13
ARG FinchVersionPatch=0
ARG FinchVersion="v${FinchVersionMajor}.${FinchVersionMinor}.${FinchVersionPatch}"

FROM alpine:latest AS builder

ARG FinchVersion

RUN apk update && apk add --no-cache go git \
    && git clone https://github.com/runfinch/finch.git -b ${FinchVersion} \
    && cd finch/ \
    && CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o /usr/bin/finch ./cmd/finch

FROM alpine:latest AS app

RUN apk update && apk add --no-cache containerd nerdctl \
    && mkdir -p /usr/libexec/finch \
    && ln -s $(which nerdctl) /usr/libexec/finch/nerdctl \
    && ln -sf /usr/bin/finch /usr/bin/docker \
    && mkdir -p /etc/finch && printf '%s\n' "{}" > /etc/finch/finch.yaml

ENV CONTAINERD_SNAPSHOTTER=native

COPY --from=builder /usr/bin/finch /usr/bin/finch

ENTRYPOINT [ "containerd" ]