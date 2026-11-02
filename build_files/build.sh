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
    docker-buildx \
    cocker-cli \
    docker-compose \
    docker-compose-switch \
    moby-engine
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
    docker-compose-plugin \
    docker-ce-rootless-extras

# --- SCRIPT DA INIZIALIZZARE IN RUNTIME ---
# Imposta i permessi per gli script personalizzati in runtime
for bash_file in /ctx/system_files/usr/bin/*; do
    if [ -f "$bash_file" ]; then
        bash_name=$(basename "$bash_file")
        echo "Impostazione permessi di: $bash_name"
        chmod +x /usr/bin/$bash_name
    fi
done

# --- USER CONTAINER ---
# in /etc/containers/systemd/users

# --- SYSTEM CONTAINER ---
# in /etc/containers/systemd

# --- USER SERVICE ---
USER_WANTS_DIR="/etc/systemd/user/default.target.wants"
mkdir -p "$USER_WANTS_DIR"
for service_file in /ctx/system_files/usr/lib/systemd/user/*.service; do
    service_name=$(basename "$service_file")
    echo "Abilitazione utente di: $service_name"
    ln -sf "/usr/lib/systemd/user/$service_name" "$USER_WANTS_DIR/$service_name"
done

# --- SYSTEM SERVICE ---
SYSTEM_WANTS_DIR="/etc/systemd/system/multi-user.target.wants"
mkdir -p "$SYSTEM_WANTS_DIR"
for service_file in /ctx/system_files/usr/lib/systemd/system/*.service; do
    service_name=$(basename "$service_file")
    echo "Abilitazione globale di: $service_name"
    ln -sf "/usr/lib/systemd/system/$service_name" "$SYSTEM_WANTS_DIR/$service_name"
done
#ln -s /usr/lib/systemd/system/enable-user-linger.service /etc/systemd/system/multi-user.target.wants/enable-user-linger.service
#ln -s /usr/lib/systemd/system/netbird-init.service /etc/systemd/system/multi-user.target.wants/netbird-init.service
ln -s /usr/lib/systemd/system/cockpit.service /etc/systemd/system/default.target.wants/cockpit.service

# --- CLEANING IMAGE ---
dnf clean all
rm -rf /tmp/* /var/tmp/*
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
