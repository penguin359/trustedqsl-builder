#!/usr/bin/env bash

base="$(dirname "$(readlink -f "$0")")"

args=$(getopt --name "$0" --options 'hn:uTUtapND' --longoptions 'help,name:,upload,tag,no-sign,tarball,appimage,package,no-clean,shell-debug' --shell sh -- "$@")
if [ $? -ne 0 ]; then
	echo >&2
	echo "Invalid options, use -h for help." >&2
	exit 1
fi
eval set -- "$args"

container="tqsl"
upload=
tag_opt=
no_sign=
tarball=
appimage=
package=
sh_debug=
all=y
clean=y
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help)
			echo "Usage: $0 [-h] [-n name] tag..." >&2
			echo "  -h | --help        Help" >&2
			echo "  -n | --name NAME   Container name" >&2
			echo "  -u | --upload      Upload signed package" >&2
			echo "  -T | --tag         Upload signed tag" >&2
			echo "  -U | --no-sign     Don't sign or upload" >&2
			echo "  -t | --tarball     Only build tarball" >&2
			echo "  -a | --appimage    Only build AppImage" >&2
			echo "  -p | --package     Only build Debian package" >&2
			echo "  -N | --no-clean    Don't clean container" >&2
			echo "  -D | --shell-debug Enable shell script debugging" >&2
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
		-T|--tag)
			tag_opt=-T
			;;
		-U|--no-sign)
			no_sign=-U
			;;
		-t|--tarball)
			tarball=y
			all=
			;;
		-a|--appimage)
			appimage=y
			all=
			;;
		-p|--package)
			package=y
			all=
			;;
		-N|--no-clean)
			clean=
			;;
		-D|--shell-debug)
			sh_debug="bash -x"
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

if [ -n "$all" ]; then
	tarball=y
	appimage=y
	package=y
fi

cd "$base"

declare -a tags=($@)

if [ "${#tags[@]}" -eq 0 ]; then
	tags=("22.04")
fi

cookie_file=
cleanup() {
	if [ -n "$cookie_file" -a -f "$cookie_file" ]; then
		echo "Cleaning up cookies ${cookie_file}..."
		rm "$cookie_file"
	fi
}

error() {
	echo -e "\e[31mBuild has failed.\e[m"
}

trap cleanup EXIT
trap error ERR

build() {
	local tag="$1"
	local release="ubuntu:${tag}"
	local outputdir="${base}/output-docker/ubuntu${tag}"
	local clean="$2"
	if [ -n "$clean" ]; then
		clean=--rm
	else
		clean=
	fi
	local user="ubuntu"
	if [[ "$release" =~ "debian" ]]; then
		user="debian"
	fi

	#sed -i -e 's/^FROM .*/FROM '"$release"'/' Dockerfile

	rm -fr "$outputdir"/
	mkdir -p "$outputdir"/

	#if ! docker image inspect "tqsl-${tag}" &>/dev/null; then
		docker build --build-arg tag="${tag}" --tag "tqsl-${tag}" .
	#fi
	docker container rm "${container}-${tag}" 2>/dev/null || true

	local host_socket="$(gpgconf --list-dir agent-extra-socket)"
	local container_socket="$(docker run --rm "tqsl-${tag}" gpgconf --list-dir | grep '^agent-socket:' | cut -d: -f2)"
	local x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
	echo "===> Detected sockets..."
	echo "host_socket=$host_socket"
	echo "container_socket=$container_socket"
	echo "x11_socket=$x11_socket"
	echo
	echo "===> Starting build script..."
	cookies_file="$(mktemp "${TMPDIR:-/tmp}/xauth-XXXXXXXX")"
	xauth extract - "$DISPLAY" > "$cookies_file"
	if [ -n "$tarball" ]; then
		docker container run -it $clean \
			-v "${x11_socket}:/tmp/.X11-unix/X0" \
			-v "${outputdir}:/output" \
			-v "${cookies_file}":/tmp/cookies \
			--name "${container}-${tag}" "tqsl-${tag}" $sh_debug "./build-tqsl-tarball.sh"
	fi
	if [ -n "$appimage" ]; then
		docker container run -it $clean \
			-v "${x11_socket}:/tmp/.X11-unix/X0" \
			-v "${outputdir}:/output" \
			-v "${cookies_file}":/tmp/cookies \
			--device /dev/fuse \
			--cap-add SYS_ADMIN \
			--security-opt apparmor:unconfined \
			--name "${container}-${tag}" "tqsl-${tag}" $sh_debug "./build-tqsl-appimage.sh"
	fi
	if [ -n "$package" ]; then
		# TODO Don't forward host_socket on $no_sign
		docker container run -it $clean \
			-v "${SSH_AUTH_SOCK}:/tmp/ssh-agent.sock" \
			-v "${x11_socket}:/tmp/.X11-unix/X0" \
			-v "${host_socket}:${container_socket}" \
			-v "${outputdir}:/output" \
			-v "${cookies_file}":/tmp/cookies \
			--name "${container}-${tag}" "tqsl-${tag}" $sh_debug "./build-tqsl-package.sh" $upload $tag_opt $no_sign
			#-v "${HOME}/.gnupg:/home/ubuntu/.gnupg" \
			#-v /tmp/.X11-unix:/tmp/.X11-unix \
			#-e DISPLAY="$DISPLAY" \
	fi

	echo "===> Done."
}

main() {
	for i in "${tags[@]}"; do
		build "$i" "$clean"
	done
	exit 0
}

main
