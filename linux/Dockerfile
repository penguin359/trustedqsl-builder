ARG tag=22.04
FROM ubuntu:${tag}
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -qy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy gnupg2 sudo \
    devscripts equivs git-buildpackage gnupg2 python3-paramiko
RUN id ubuntu >/dev/null 2>&1 || useradd ubuntu -m -s /bin/bash
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99-ubuntu-user
USER ubuntu
WORKDIR /build
COPY scripts/ .
CMD ["./build-tqsl-package.sh"]
