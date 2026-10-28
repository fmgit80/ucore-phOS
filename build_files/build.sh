#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# --- DNF SPEEDUP ---
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

# --- TAILSCALE/NETBIRD ---
dnf remove -y tailscale
dnf install -y --setopt=tsflags=noscripts netbird

# --- COCKPIT PLUGINS ---
dnf install -y \
    cockpit-389-ds \
    cockpit-bridge \
    cockpit-doc \
    cockpit-files \
    cockpit-ha-cluster \
    cockpit-image-builder \
    cockpit-kdump \
    cockpit-machines \
    cockpit-networkmanager \
    cockpit-ostree \
    cockpit-packagekit \
    cockpit-podman \
    cockpit-selinux \
    cockpit-sosreport \
    cockpit-storaged \
    cockpit-system \
    cockpit-ws \
    cockpit-ws-selinux \
    cockpit-composer \
    cockpit-session-recording \
    dockermanager


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
ln -s /usr/lib/systemd/system/docker.service /etc/systemd/system/multi-user.target.wants/docker.service
ln -s /usr/lib/systemd/system/cockpit.service /etc/systemd/system/default.target.wants/cockpit.service

# --- CLEANING IMAGE ---
dnf clean all
rm -rf /tmp/* /var/tmp/*
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
