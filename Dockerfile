FROM ubuntu:22.10
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -qy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy gnupg2 sudo \
    devscripts equivs git-buildpackage gnupg2 python3-paramiko
RUN useradd ubuntu -m -G sudo -s /bin/bash && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99-ubuntu-user
USER ubuntu
WORKDIR /home/ubuntu
COPY build-tqsl.sh .
CMD ["./build-tqsl.sh"]
