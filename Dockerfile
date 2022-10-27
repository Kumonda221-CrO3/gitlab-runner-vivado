FROM gitlab/gitlab-runner:latest

LABEL maintainer RISMD <kumonda@kucro3.org>

# Thanks for z4yx <z4yx@users.noreply.github.com>! Great love <3
# * https://github.com/z4yx/vivado-docker *

# Build command example:
#   docker build --build-arg VIVADO_VERSION=2019.2 \
#                --build-arg VIVADO_INSTALL_TAR=Xilinx_Vivado_2019.2_1106_2127.tar.gz \
#                --build-arg VIVADO_INSTALL_CFG=intall_config.txt \
#                --tag rismd/gitlab-runner-vivado:2019.2 .
# Or (easy to copy, dizzy to read):
#   docker build --build-arg VIVADO_VERSION=2019.2 --build-arg VIVADO_INSTALL_TAR=Xilinx_Vivado_2019.2_1106_2127.tar.gz --build-arg VIVADO_INSTALL_CFG=intall_config.txt --tag rismd/gitlab-runner-vivado:2019.2 .

# Run command exmaple:
#   docker run --security-opt seccomp=unconfined \
#              --name gitlab-runner-vivado-2019.2 \
#              -itd \
#              rismd/gitlab-runner-vivado:2019.2
# Or:
#   docker run --security-opt seccomp=unconfined --name gitlab-runner-vivado-2019.2 -itd 
# NOTE: '--secuity-opt seccomp=unconfined' is necessary for Docker under WSL2,
#       or Vivado after 2018 might fail on the run.
#       Make it always enabled won't make any difference. :)

ARG VIVADO_VERSION
ARG VIVADO_INSTALL_TAR
ARG VIVADO_INSTALL_CFG


# Install dependences
RUN apt update
RUN apt upgrade -y
RUN apt install -y \
    build-essential \
    libncurses5 \
    libxtst6 \
    libglib2.0-0 \
    libsm6 \
    libxi6 \
    libxrender1 \
    libxrandr2 \
    libfreetype6 \
    libfontconfig \
    lsb-release \
    git


# Install libudev-stub 
# NOTE: Vivado after 2018 might fail on udev_udev_enumerate_scan_devices(3) in docker !!!
RUN wget https://github.com/therealkenc/libudev-stub/releases/download/v0.9.0/libudev-stub-0.9.0-WSL.deb
RUN dpkg -i libudev-stub-0.9.0-WSL.deb


# NOTE: You may want to create a individual user in normal docker.
#       Though, it's not recommended under gitlab-runner image.

# # Make a Vivado user
# RUN adduser --disabled-password --gecos '' vivado &&\
#   usermod -aG sudo vivado &&\
#   echo "vivado ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


# GitLab-Runner registeration
# NOTE: Not included in dockerfile, you might want to run 'gitlab-runner register'
#       after your own GitLab deployed and docker instance started.


RUN mkdir /install_vivado
COPY ${VIVADO_INSTALL_CFG} /install_vivado/install_config.txt
# ADD will extract the installer tar
ADD ${VIVADO_INSTALL_TAR} /install_vivado/

# Install Vivado
RUN ls /install_vivado && /install_vivado/*/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config /install_vivado/install_config.txt
RUN rm -rf /${VIVADO_INSTALL_TAR} /install_vivado

# Vivado ENV configuration
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" > /etc/bash.bashrc
