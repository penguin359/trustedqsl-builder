Build scripts for TrustedQSL
============================

These are scripts for cleaning building Trusted QSL from the ARRL in a
clean environment for Ubuntu. The primary script uses LXD containers
and is run with this command:

    ./tqsl-lxc.sh [22.04]

There is also preliminary support for Docker builds with:

    ./tqsl-docker.sh
