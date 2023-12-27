#!/bin/bash

set -e

. /etc/os-release

if [ "$VERSION_ID" = "14.04" ]; then
	VERSION_CODENAME="trusty"
fi

user="$(id -un)"
group="$(id -gn)"

if [ -z "$DISPLAY" ]; then
	export DISPLAY=":0"
fi
if [ -f /tmp/cookies ]; then
	xauth merge /tmp/cookies
fi

branch="backport-${VERSION_CODENAME}"

export SSH_AUTH_SOCK="/tmp/ssh-agent.sock"
export GPG_AGENT_INFO="$(gpgconf --list-dir | grep '^agent-socket:' | cut -d: -f2):0:1"
if tty >/dev/null 2>&1; then
	export GPG_TTY=$(tty)
fi

# Needed for Docker to fix permissions
x11_socket="/tmp/.X11-unix/X$(echo "$DISPLAY" | cut -d: -f2 | cut -d. -f1)"
sudo mkdir -p /output/deb/
sudo chown -R "${user}:${group}" "$SSH_AUTH_SOCK" "${HOME}/.gnupg" "$x11_socket" /output
sudo chmod -R u=rwX,go= "$SSH_AUTH_SOCK" "${HOME}/.gnupg" "$x11_socket"
sudo chmod -R u=rwX,go=rX /output


if [ "${VERSION_CODENAME}" = "groovy" -o \
     "${VERSION_CODENAME}" = "hirsute" -o \
     "${VERSION_CODENAME}" = "impish" -o \
     "${VERSION_CODENAME}" = "kinetic" ]; then
	sudo sed -i 's:archive.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
	sudo sed -i 's:security.ubuntu.com:old-releases.ubuntu.com:' /etc/apt/sources.list
else
	proxy=10.146.39.1
	#ping -n1 "$proxy"
	echo "Acquire::http::Proxy \"http://${proxy}:3142\";" | sudo tee /etc/apt/apt.conf.d/00aptproxy
fi
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -qy
cd


paramiko=python3-paramiko
if [ "$branch" = "backport-trusty" ]; then
	paramiko="python-paramiko python-bzrlib"
fi
sudo DEBIAN_FRONTEND=noninteractive apt install -qy devscripts equivs git-buildpackage gnupg2 $paramiko
if [ "$branch" = "backport-xenial" ]; then
	sudo DEBIAN_FRONTEND=noninteractive apt remove -qy gnupg
fi
export DEBEMAIL="lorenl@north-winds.org"
export DEBFULLNAME="Loren M. Lang"

cat >.devscripts <<EOF
DEBUILD_DPKG_BUILDPACKAGE_OPTS="-i -I -us -uc"
#DEBUILD_LINTIAN_OPTS="-i -I --show-overrides"
DEBSIGN_KEYID="7896E0999FC79F6CE0EDE103222DF356A57A98FA"
DSCVERIFY_KEYRINGS="$HOME/.gnupg/trustedkeys.gpg"
EOF
cat >.dput.cf <<EOF
[trustedqsl]
fqdn = ppa.launchpad.net
incoming = ~penguin359/ubuntu/trustedqsl/
method = sftp
login = penguin359
EOF

mkdir -p ~/.ssh/
cat >> ~/.ssh/config <<EOF
Host github.com
User git
EOF
cat >> ~/.ssh/known_hosts <<EOF
|1|L65WTC0AxkfE4nrvu2RV0ZmhURg=|wRCkGhAHG+NTMvWJZhrOk1Y/o1s= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0aKz5UTUndYgIGG7dQBV+HaeuEZJ2xPHo2DS2iSKvUL4xNMSAY4UguNW+pX56nAQmZKIZZ8MaEvSj6zMEDiq6HFfn5JcTlM80UwlnyKe8B8p7Nk06PPQLrnmQt5fh0HmEcZx+JU9TZsfCHPnX7MNz4ELfZE6cFsclClrKim3BHUIGq//t93DllB+h4O9LHjEUsQ1Sr63irDLSutkLJD6RXchjROXkNirlcNVHH/jwLWR5RcYilNX7S5bIkK8NlWPjsn/8Ua5O7I9/YoE97PpO6i73DTGLh5H9JN/SITwCKBkgSDWUt61uPK3Y11Gty7o2lWsBjhBUm2Y38CBsoGmBw==
|1|xPW80Prm6bDJ95oIpf2oWCo2ZbM=|f/tCGjfc5/6MrNIhruPMyX026nc= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0aKz5UTUndYgIGG7dQBV+HaeuEZJ2xPHo2DS2iSKvUL4xNMSAY4UguNW+pX56nAQmZKIZZ8MaEvSj6zMEDiq6HFfn5JcTlM80UwlnyKe8B8p7Nk06PPQLrnmQt5fh0HmEcZx+JU9TZsfCHPnX7MNz4ELfZE6cFsclClrKim3BHUIGq//t93DllB+h4O9LHjEUsQ1Sr63irDLSutkLJD6RXchjROXkNirlcNVHH/jwLWR5RcYilNX7S5bIkK8NlWPjsn/8Ua5O7I9/YoE97PpO6i73DTGLh5H9JN/SITwCKBkgSDWUt61uPK3Y11Gty7o2lWsBjhBUm2Y38CBsoGmBw==
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
EOF

# dch -v 2.6.5-3~penguin359~kinetic1
rm -f ~/.gnupg/trustedkeys.gpg
gpg2 --keyserver keyserver.ubuntu.com --recv-key "7896E0999FC79F6CE0EDE103222DF356A57A98FA"
#echo -e "5\ny\nsave\n" | gpg2 --command-fd 0 --edit-key "7896E0999FC79F6CE0EDE103222DF356A57A98FA" trust
gpg2 --import-ownertrust <<EOF
7896E0999FC79F6CE0EDE103222DF356A57A98FA:6:
EOF
gpg2 --check-trustdb
gpg2 --output ~/.gnupg/trustedkeys.gpg --export "7896E0999FC79F6CE0EDE103222DF356A57A98FA"

git config --global user.name "Loren M. Lang"
git config --global user.email "lorenl@north-winds.org"

rm -fr ~/deb
mkdir ~/deb
cd ~/deb
rm -fr trustedqsl
git clone -b "$branch" https://github.com/penguin359/trustedqsl
mk-build-deps trustedqsl/debian/control
if [ "$branch" = "backport-trusty" ]; then
	sudo DEBIAN_FRONTEND=noninteractive dpkg -i ./trustedqsl-build-deps_*.deb || true
	sudo apt install -y -f
else
	sudo DEBIAN_FRONTEND=noninteractive apt install -qy ./trustedqsl-build-deps_*.deb
fi
pristine=
if [ -z "$pristine" ]; then
	version="$(curl -qsSLf https://arrl.org/tqsl-download | sed -ne 's@.*/tqsl-\([0-9]\+\(\.[0-9]\+\)\+\)\.tar\.gz.*@\1@p')"
	wget "http://archive.ubuntu.com/ubuntu/pool/universe/t/trustedqsl/trustedqsl_${version}.orig.tar.gz"
fi
cd trustedqsl
if [ -n "$pristine" ]; then
	git branch pristine-tar origin/pristine-tar
fi
#lintian_opts="--fail-on error,warning"
lintian_opts="--fail-on error"
if [ "$branch" = "backport-trusty" -o \
     "$branch" = "backport-xenial" -o \
     "$branch" = "backport-bionic" -o \
     "$branch" = "backport-focal" ]; then
	lintian_opts=""
elif [ "$branch" = "backport-groovy" -o \
       "$branch" = "backport-hirsute" -o \
       "$branch" = "backport-impish" ]; then
	# Warnings are being produced due to Troff segfault
	lintian_opts="--fail-on error"
fi
#dpkg-buildpackage -kfakeroot
#gbp buildpackage --git-debian-branch="$branch" --git-tarball-dir=.. --lintian-opts $lintian_opts
echo "===> Building binary package..."
tarball_opt=('--git-tarball-dir=..')
if [ -n "$pristine" ]; then
	tarball_opt=('--git-pristine-tar')
fi
git_msg_opt=('--git-debian-tag-msg=%(pkg)s Ubuntu PPA release %(version)s')
if [ "$branch" = "backport-trusty" ]; then
	git_msg_opt=()
fi
gbp buildpackage --git-debian-branch="$branch" "${tarball_opt[@]}" --git-builder="debuild --no-lintian -i -I" --git-tag --git-sign-tags --git-keyid="7896E0999FC79F6CE0EDE103222DF356A57A98FA" --git-debian-tag='released/%(version)s' "${git_msg_opt[@]}"
#lintian -i -I --fail-on error,warning,info,pedantic ../trustedqsl_*_amd64.changes
echo "===> Running lintian on binary package..."
lintian -I --pedantic $lintian_opts ../trustedqsl_*_amd64.changes
echo "===> Building source package..."
debuild --no-lintian -S
echo "===> Running lintian on source package..."
lintian -I --pedantic $lintian_opts ../trustedqsl_*_source.changes
#debsign
echo "===> Signing source package..."
debsign -S
cd ..
sudo dpkg -i trustedqsl_*_amd64.deb
# Exits with status 255 on good invocation
tqsl --version 2>&1 | grep --color 'TQSL Version 2\..*'
dscverify trustedqsl_*_source.changes
dput -ol trustedqsl trustedqsl_*_source.changes
if [ "$1" = "-u" ]; then
	dput --debug -l trustedqsl trustedqsl_*_source.changes
fi
cp --preserve=timestamps trustedqsl_* /output/deb/
if [ "$1" = "-u" ]; then
	git --git-dir=trustedqsl/.git push --tags github.com:penguin359/trustedqsl
fi
echo "Success!"
