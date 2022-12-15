#!/bin/sh

set -e

container="tqsl-fun"

docker build --tag tqsl .

host_socket="$(gpgconf --list-dir agent-extra-socket)"
container_socket="$(docker run --rm tqsl gpgconf --list-dir | grep '^agent-socket:' | cut -d: -f2)"
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
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
	--name "$container" tqsl
	#-v "${HOME}/.gnupg:/home/ubuntu/.gnupg" \
	#-v /tmp/.X11-unix:/tmp/.X11-unix \
	#-e DISPLAY="$DISPLAY" \
docker container run -it --rm \
	-v "${x11_socket}:/tmp/.X11-unix/X0" \
	--name "$container" tqsl ./build-tqsl-tarball.sh
docker container run -it --rm \
	-v "${x11_socket}:/tmp/.X11-unix/X0" \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	--name "$container" tqsl ./build-tqsl-appimage.sh

echo "===> Done."
