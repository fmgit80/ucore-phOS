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
#USER_CONTAINER_WANTSDIR="/etc/systemd/user/default.target.wants"
#mkdir -p "$USER_CONTAINER_WANTSDIR"
#for container_file in /ctx/system_files/etc/containers/systemd/users/*.container; do
#    container_name=$(basename "$container_file")
#    echo "Abilitazione globale di: $container_name"
#    ln -sf "/run/systemd/user/$container_name" "$USER_CONTAINER_WANTSDIR/$container_name"
#done
#ln -s /run/systemd/user/quadeck.service /etc/systemd/user/default.target.wants/quadeck.service

# --- SYSTEM CONTAINER ---


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
#ln -s /usr/lib/systemd/system/cockpit.service /etc/systemd/system/default.target.wants/cockpit.service

# --- QUADECK ---
curl -fsSLo /usr/local/bin/quadeck https://github.com/firsttris/quadeck/releases/latest/download/quadeck-linux-x64-baseline
chmod +x /usr/local/bin/quadeck
groupadd --system quadeck
useradd --system --gid quadeck --home-dir /var/lib/quadeck --no-create-home --shell /usr/sbin/nologin quadeck
usermod -aG systemd-journal quadeck
quadeck print-unit helper > /etc/systemd/system/quadeck-helper.service
quadeck print-unit web > /etc/systemd/system/quadeck.service

# --- CLEANING IMAGE ---
dnf clean all
rm -rf /tmp/* /var/tmp/*
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
