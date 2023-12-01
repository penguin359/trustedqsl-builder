#!/usr/bin/env bash

base="$(dirname "$(readlink -f "$0")")"

args=$(getopt --name "$0" --options 'hn:u' --longoptions 'help,name:,upload' --shell sh -- "$@")
if [ $? -ne 0 ]; then
	echo >&2
	echo "Invalid options, use -h for help." >&2
	exit 1
fi
eval set -- "$args"

container="tqsl"
upload=
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help)
			echo "Usage: $0 [-h] [-n name] tag..." >&2
			echo "  -h | --help        Help" >&2
			echo "  -n | --name NAME   Container name" >&2
			echo "  -u | --upload      Upload signed package" >&2
			echo "  tag...             Ubuntu version(s) to build for" >&2
			exit 0
			;;
		-n|--name)
			container="$2"
			shift
			;;
		-u|--upload)
			upload=-u
			;;
		--)
			shift
			break
			;;
		*)
			echo "Error in getopt configuration (missing or extra options?)" >&2
			exit 1
			;;
	esac
	shift
done

set -e

cd "$base"

declare -a tags=($@)

if [ "${#tags[@]}" -eq 0 ]; then
	#tags=("14.04")
	#tags=("16.04")
	#tags=("18.04")
	#tags=("20.04")
	#tags=("20.10")
	#tags=("21.04")
	#tags=("21.10")
	tags=("22.04")
	#tags=("22.10")
	#tags=("23.04")
	#tags=("devel")
fi

build() {
	local tag="$1"
	local release="ubuntu:${tag}"
	local outputdir="${base}/output-lxc/ubuntu${tag}"
	local user="ubuntu"

	lxc stop --force "$container" 2>/dev/null || true
	lxc delete "$container" 2>/dev/null || true
	echo "===> Creating new container for ${release}..."
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
	local home="$(lxc exec "$container" -- sudo -u "$user" -i echo '$HOME')"
	local uid="$(lxc exec "$container" -- sudo -u "$user" -i id -u)"
	local gid="$(lxc exec "$container" -- sudo -u "$user" -i id -g)"
	local host_socket="$(gpgconf --list-dir agent-extra-socket)"
	local container_socket="$(lxc exec "$container" -- sudo -u "$user" -i gpgconf --list-dir | grep '^agent-socket:' | cut -d: -f2)"
	local x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
	echo "===> Detected sockets..."
	echo "host_socket=$host_socket"
	echo "container_socket=$container_socket"
	echo "x11_socket=$x11_socket"
	echo
	local my_ip="$(ip -o route get 240.0.0.0 | sed -n 's:.* src \([^ ]\+\) .*:\1:p')"
	lxc exec "$container" -- sudo -u "$user" -i mkdir -m 700 -p "$(dirname "$container_socket")" "$home"/.gnupg /tmp/.X11-unix
	lxc config device remove "$container" gpg-agent 2>/dev/null || true
	lxc config device remove "$container" ssh-agent 2>/dev/null || true
	lxc config device remove "$container" x11 2>/dev/null || true
	lxc config device add "$container" ssh-agent proxy connect=unix:"$SSH_AUTH_SOCK" listen=unix:"/tmp/ssh-agent.sock" bind=container uid="$uid" gid="$gid" mode=0600
	#lxc config device add "$container" x11 disk source="$x11_socket" path=/tmp/.X11-unix/X0
	lxc config device add "$container" x11 proxy connect=unix:"$x11_socket" listen=unix:/tmp/.X11-unix/X0 bind=container uid="$uid" gid="$gid" mode=0600
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
	lxc file push -r scripts/* "$container""$home"/
	echo "===> Starting build script..."
	lxc exec "$container" -- sudo -u "$user" -i "./build-tqsl-package.sh" $upload
	lxc exec "$container" -- sudo -u "$user" -i "./build-tqsl-tarball.sh"
	lxc exec "$container" -- sudo -u "$user" -i "./build-tqsl-appimage.sh"
	rm -fr "$outputdir"/
	lxc file pull -r "$container/output/" "$outputdir"/
	mv "$outputdir"/output/* "$outputdir"/
	rmdir "$outputdir"/output/
	lxc stop "$container"
	lxc delete "$container"
	echo "===> Done."
}

for i in "${tags[@]}"; do
	build "$i"
done
