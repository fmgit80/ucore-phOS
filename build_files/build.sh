#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# --- DNF SPEEDUP ---
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

# --- TAILSCALE/NETBIRD ---
dnf remove -y tailscale
dnf install -y --setopt=tsflags=noscripts netbird

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

# --- CLEANING IMAGE ---
dnf clean all
rm -rf /tmp/* /var/tmp/*
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
