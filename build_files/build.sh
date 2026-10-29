#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# --- DNF SPEEDUP ---
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

# --- REMOVE MAN ---
echo "tsflags=nodocs" >> /etc/dnf/dnf.conf

# --- TAILSCALE/NETBIRD ---
dnf remove -y tailscale
dnf install -y --setopt=tsflags=noscripts netbird

# --- DOCKER ---
dnf remove -y \
    moby-engine \
    docker \
    docker-cli \
    docker-buildx \
    docker-compose
rm -rf /var/lib/docker
rm -rf /etc/docker
dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine
dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# --- SCRIPT DA INIZIALIZZARE IN RUNTIME ---
# Imposta i permessi per gli script personalizzati in runtime
for bash_file in /ctx/system_files/usr/bin/*; do
    if [ -f "$bash_file" ]; then
        bash_name=$(basename "$bash_file")
        echo "Impostazione permessi di: $bash_name"
        chmod +x /usr/bin/$bash_name
    fi
done

# --- USER SERVICE ---

# --- SYSTEM SERVICE ---
ln -s /usr/lib/systemd/system/netbird-init.service /etc/systemd/system/multi-user.target.wants/netbird-init.service
ln -s /usr/lib/systemd/system/docker.socket /etc/systemd/system/sockets.target.wants/docker.socket
ln -s /usr/lib/systemd/system/docker.service /etc/systemd/system/multi-user.target.wants/docker.service
ln -s /usr/lib/systemd/system/cockpit.service /etc/systemd/system/default.target.wants/cockpit.service

# --- CLEANING IMAGE ---
dnf clean all
rm -rf /tmp/* /var/tmp/*
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
