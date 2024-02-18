FROM ubuntu:latest
WORKDIR /app

ARG USER_NAME="aeroriver"
ARG OPT="/opt"
ARG PKGS="sudo curl git g++ wget build-essential bash-completion ccache g++-arm-linux-gnueabihf python3-pip python3-distutils"
ARG ARM_ROOT="gcc-arm-none-eabi-10-2020-q4-major"


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    $PKGS && \
    rm -rf /var/lib/apt/lists/*

RUN cd $OPT && \
    sudo wget --no-check-certificate --progress=dot:giga https://firmware.ardupilot.org/Tools/STM32-tools/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo chmod -R 777 gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo tar xjf gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo rm gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo ln -s -f $(which ccache) /usr/lib/ccache/arm-none-eabi-g++ && \
    sudo ln -s -f $(which ccache) /usr/lib/ccache/arm-none-eabi-gcc
    
ENV PATH="${OPT}/gcc-arm-none-eabi-10-2020-q4-major/bin:${PATH}"

RUN useradd -m -s /bin/bash -u 1002 $USER_NAME && \
    usermod -aG sudo $USER_NAME && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USER_NAME 

RUN pip install --user empy==3.3.4 pexpect future

CMD ["bash"]
