#!/bin/sh

if ! git diff --exit-code --quiet -- debian/changelog; then
	echo "Debian changelog currently has uncommitted changes." >&2
	exit 1
fi

distro="$(git branch --show-current | sed 's:backport-::')"

if [ "backport-${distro}" != "$(git branch --show-current)" ]; then
	echo "It does not appear that you are on a backport branch" >&2
	exit 1
fi

case "${distro}" in
	trusty)		osver="14.04" ;;
	xenial)		osver="16.04" ;;
	bionic)		osver="18.04" ;;
	focal)		osver="20.04" ;;
	groovy)		osver="20.10" ;;
	hirsute)	osver="21.04" ;;
	impish)		osver="21.10" ;;
	jammy)		osver="22.04" ;;
	kinetic)	osver="22.10" ;;
	lunar)		osver="23.04" ;;
	mantic)		osver="23.10" ;;
	noble)		osver="24.04" ;;
	oracular)	osver="24.10" ;;
	plucky)		osver="25.04" ;;
	questing)	osver="25.10" ;;
	*)
		echo "Unrecognized Ubuntu distribution: ${distro}" >&2
		exit 1
		;;
esac

gbp dch --debian-branch "backport-${distro}" --release --commit --spawn-editor=never --distribution "${distro}" --local "ppa1~ubuntu${osver}"
