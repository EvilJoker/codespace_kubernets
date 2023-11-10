FROM mcr.microsoft.com/devcontainers/go:1-1.21-bullseye
LABEL org.opencontainers.image.source=https://github.com/EvilJoker/codespace_kubernets
ARG DEBIAN_FRONTEND=noninteractive

COPY config/sources.list /etc/apt/sources.list
COPY config/pip.conf /root/.pip/pip.conf