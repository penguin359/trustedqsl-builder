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
	tags=("22.04")
fi

build() {
	local tag="$1"
	local release="ubuntu:${tag}"
	local outputdir="${base}/output-docker/ubuntu${tag}"

	#sed -i -e 's/^FROM .*/FROM '"$release"'/' Dockerfile

	rm -fr "$outputdir"/
	mkdir -p "$outputdir"/

	docker build --build-arg tag="${tag}" --tag "tqsl-${tag}" .

	local host_socket="$(gpgconf --list-dir agent-extra-socket)"
	local container_socket="$(docker run --rm "tqsl-${tag}" gpgconf --list-dir | grep '^agent-socket:' | cut -d: -f2)"
	local x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
	echo "===> Detected sockets..."
	echo "host_socket=$host_socket"
	echo "container_socket=$container_socket"
	echo "x11_socket=$x11_socket"
	echo
	echo "===> Starting build script..."
	docker container run -it --rm \
		-v "${SSH_AUTH_SOCK}:/tmp/ssh-agent.sock" \
		-v "${x11_socket}:/tmp/.X11-unix/X0" \
		-v "${host_socket}:${container_socket}" \
		-v "${outputdir}:/output" \
		--name "$container" "tqsl-${tag}" ./build-tqsl-package.sh $upload
		#-v "${HOME}/.gnupg:/home/ubuntu/.gnupg" \
		#-v /tmp/.X11-unix:/tmp/.X11-unix \
		#-e DISPLAY="$DISPLAY" \
	docker container run -it --rm \
		-v "${x11_socket}:/tmp/.X11-unix/X0" \
		-v "${outputdir}:/output" \
		--name "$container" "tqsl-${tag}" ./build-tqsl-tarball.sh
	docker container run -it --rm \
		-v "${x11_socket}:/tmp/.X11-unix/X0" \
		-v "${outputdir}:/output" \
		--device /dev/fuse \
		--cap-add SYS_ADMIN \
		--security-opt apparmor:unconfined \
		--name "$container" "tqsl-${tag}" ./build-tqsl-appimage.sh

	echo "===> Done."
}

for i in "${tags[@]}"; do
	build "$i"
done
