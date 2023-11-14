FROM ghcr.io/eviljoker/codespace_kubernets_devcontainer 

# 关联到 仓库 Packages
LABEL org.opencontainers.image.source=https://github.com/EvilJoker/codespace_kubernets
ARG DEBIAN_FRONTEND=noninteractive

COPY config/sources.list /etc/apt/sources.list
COPY config/pip.conf /root/.pip/pip.conf