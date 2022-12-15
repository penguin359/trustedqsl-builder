#!/bin/sh

set -e

container="tqsl3"
release="ubuntu:14.04"
#release="ubuntu:16.04"
#release="ubuntu:18.04"
#release="ubuntu:20.04"
#release="ubuntu:20.10"
#release="ubuntu:21.04"
#release="ubuntu:21.10"
#release="ubuntu:22.04"
#release="ubuntu:22.10"
#release="ubuntu:23.04"
#release="ubuntu:devel"

user="ubuntu"

lxc stop --force "$container" 2>/dev/null || true
lxc delete "$container" 2>/dev/null || true
echo "===> Creating new container..."
lxc launch "$release" "$container"
#lxc start "$container"
echo "===> Waiting for start-up..."
if [ "$release" = "ubuntu:16.04" ]; then
	lxc exec "$container" -- dhclient eth0
	lxc exec "$container" -- sh -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
	lxc exec "$container" -- sed -i 's:\( localhost\):\1 '"$container"':' /etc/hosts
fi
for i in $(seq 10); do
	if lxc exec "$container" -- ping -c 1 www.google.com; then
		break
	fi
	sleep 1
done
if [ "$release" = "ubuntu:16.04" ]; then
	lxc exec "$container" -- useradd "$user" -m -G sudo -s /bin/bash
	lxc exec "$container" -- sh -c 'echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99-ubuntu-user'
	lxc exec "$container" -- apt install -y gnupg2
	lxc exec "$container" -- rm -f /etc/apt/sources.list.d/ubuntu-esm-infra.list
elif [ "$release" = "ubuntu:14.04" ]; then
	lxc exec "$container" -- apt install -y gnupg2
	lxc exec "$container" -- rm -f /etc/apt/sources.list.d/ubuntu-esm-infra-trusty.list
else
	lxc exec "$container" -- systemctl isolate default
fi
home="$(lxc exec "$container" -- sudo -u "$user" -i echo '$HOME')"
uid="$(lxc exec "$container" -- sudo -u "$user" -i id -u)"
gid="$(lxc exec "$container" -- sudo -u "$user" -i id -g)"
host_socket="$(gpgconf --list-dir agent-extra-socket)"
#container_socket="$(lxc exec "$container" -- sudo -u "$user" -i gpgconf --list-dir agent-socket)"
container_socket="$(lxc exec "$container" -- sudo -u "$user" -i gpgconf --list-dir | grep '^agent-socket:' | cut -d: -f2)"
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
my_ip="$(ip -o route get 240.0.0.0 | sed -n 's:.* src \([^ ]\+\) .*:\1:p')"
lxc exec "$container" -- sudo -u "$user" -i mkdir -m 700 -p "$(dirname "$container_socket")"
lxc config device remove "$container" gpg-agent 2>/dev/null || true
lxc config device remove "$container" ssh-agent 2>/dev/null || true
lxc config device remove "$container" x11 2>/dev/null || true
lxc config device add "$container" ssh-agent proxy connect=unix:"$SSH_AUTH_SOCK" listen=unix:"/tmp/ssh-agent.sock" bind=container uid="$uid" gid="$gid" mode=0600
lxc config device add "$container" x11 disk source="$x11_socket" path=/tmp/.X11-unix/X0
xauth extract - "$DISPLAY" | lxc exec "$container" -- sudo -u "$user" -i xauth merge -
if [ "$release" = "ubuntu:14.04" -o \
     "$release" = "ubuntu:16.04" ]; then
	gpg2 --export-secret-key "7896E0999FC79F6CE0EDE103222DF356A57A98FA" | lxc exec "$container" -- sudo -u "$user" -i gpg2 --batch --import
else
	lxc config device add "$container" gpg-agent proxy connect=unix:"$host_socket" listen=unix:"$container_socket" bind=container uid="$uid" gid="$gid" mode=0600
fi
echo "===> Detected sockets..."
echo "host_socket=$host_socket"
echo "container_socket=$container_socket"
echo "x11_socket=$x11_socket"
echo
lxc file push build-tqsl.sh "$container""$home"/
echo "===> Starting build script..."
lxc exec "$container" -- sudo -u "$user" -i "./build-tqsl.sh"
#lxc stop "$container"
#lxc delete "$container"
echo "===> Done."
